import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _chunkSize = 900000; // ~900 KB per chunk

  /// Listens to changes on the vault master document.
  /// Emits the `updatedAt` string whenever the remote document changes.
  /// Uses a 5-second polling interval to avoid known Windows FlutterFire
  /// threading bugs with native `snapshots()` EventChannels.
  Stream<String?> listenForChanges(String uid) {
    final controller = StreamController<String?>();
    Timer? timer;
    
    void poll() async {
      try {
        final doc = await _firestore.collection('vaults').doc(uid).get();
        if (doc.exists && !controller.isClosed) {
          final data = doc.data()!;
          final updatedAt = data['updatedAt'] as String?;
          controller.add(updatedAt);
        }
      } catch (e) {
        print('[SyncService] Poll error: $e');
      }
    }
    
    // Initial poll
    poll();
    
    // Poll every 5 seconds
    timer = Timer.periodic(const Duration(seconds: 5), (_) => poll());
    
    controller.onCancel = () {
      timer?.cancel();
      controller.close();
    };
    
    return controller.stream;
  }

  /// Pushes the encrypted vault blob + salt + verifier to Firestore under the user's UID.
  Future<void> pushVault({
    required String uid,
    required String encryptedBlob,
    required String saltBase64,
    required String verifier,
  }) async {
    print('[SyncService] pushVault called for uid=$uid, blob length=${encryptedBlob.length}');
    final masterDocRef = _firestore.collection('vaults').doc(uid);
    final chunksCollection = masterDocRef.collection('chunks');
    
    // Check old chunks count to delete orphaned chunks
    final docSnapshot = await masterDocRef.get();
    int oldChunksCount = 0;
    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      if (data.containsKey('chunksCount')) {
        oldChunksCount = data['chunksCount'] as int;
      }
    }
    print('[SyncService] Old chunks count: $oldChunksCount');

    // Split blob into chunks
    final int length = encryptedBlob.length;
    final int chunksCount = (length / _chunkSize).ceil();
    print('[SyncService] New chunks count: $chunksCount');
    
    WriteBatch batch = _firestore.batch();
    
    // Write new chunks
    for (int i = 0; i < chunksCount; i++) {
      final int start = i * _chunkSize;
      final int end = (start + _chunkSize < length) ? start + _chunkSize : length;
      final String chunk = encryptedBlob.substring(start, end);
      
      batch.set(chunksCollection.doc(i.toString()), {
        'data': chunk,
      });
    }
    
    // Delete leftover chunks if the new vault is smaller
    for (int i = chunksCount; i < oldChunksCount; i++) {
      batch.delete(chunksCollection.doc(i.toString()));
    }
    
    // Update master document — includes salt & verifier for cross-device sync
    batch.set(masterDocRef, {
      'chunksCount': chunksCount,
      'updatedAt': DateTime.now().toIso8601String(),
      'salt': saltBase64,
      'verifier': verifier,
      'vaultData': null, // Remove old legacy unchunked data if it existed
    }, SetOptions(merge: true));
    
    print('[SyncService] Committing batch...');
    await batch.commit();
    print('[SyncService] Batch committed successfully!');
  }

  /// Fetches the encrypted vault blob from Firestore.
  /// Returns null if no remote vault exists.
  /// Returns a map with 'vaultData', 'updatedAt', 'salt', and 'verifier'.
  Future<Map<String, dynamic>?> fetchVault(String uid) async {
    print('[SyncService] fetchVault called for uid=$uid');
    final masterDocRef = _firestore.collection('vaults').doc(uid);
    final doc = await masterDocRef.get();
    
    if (!doc.exists) {
      print('[SyncService] No remote vault found');
      return null;
    }
    
    final data = doc.data()!;
    final String? salt = data['salt'] as String?;
    final String? verifier = data['verifier'] as String?;
    
    // Backwards compatibility for single-document uploads
    if (data.containsKey('vaultData') && data['vaultData'] != null) {
      return {
        ...data,
        'salt': salt,
        'verifier': verifier,
      };
    }
    
    // Assemble chunks
    if (data.containsKey('chunksCount')) {
      final int chunksCount = data['chunksCount'] as int;
      print('[SyncService] Fetching $chunksCount chunks...');
      final StringBuffer stringBuffer = StringBuffer();
      
      final chunksCollection = masterDocRef.collection('chunks');
      // Fetch all chunks in parallel for maximum speed
      List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = [];
      for (int i = 0; i < chunksCount; i++) {
        futures.add(chunksCollection.doc(i.toString()).get());
      }
      
      final snapshots = await Future.wait(futures);
      
      for (var snapshot in snapshots) {
        if (snapshot.exists) {
          stringBuffer.write(snapshot.data()!['data'] as String);
        }
      }
      
      print('[SyncService] Fetched vault data (${stringBuffer.length} chars)');
      return {
        'vaultData': stringBuffer.toString(),
        'updatedAt': data['updatedAt'],
        'salt': salt,
        'verifier': verifier,
      };
    }
    
    return null;
  }

  /// Deletes the vault from Firestore.
  Future<void> deleteVault(String uid) async {
    final masterDocRef = _firestore.collection('vaults').doc(uid);
    final chunksCollection = masterDocRef.collection('chunks');
    
    final docSnapshot = await masterDocRef.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      if (data.containsKey('chunksCount')) {
        final int chunksCount = data['chunksCount'] as int;
        WriteBatch batch = _firestore.batch();
        for (int i = 0; i < chunksCount; i++) {
          batch.delete(chunksCollection.doc(i.toString()));
        }
        await batch.commit();
      }
    }
    
    await masterDocRef.delete();
  }
}
