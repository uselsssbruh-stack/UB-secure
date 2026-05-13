import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A dashboard category card with icon, count, gradient accent, and hover effect.
class CategoryCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color accentColor;
  final VoidCallback onTap;

  CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.of(context).cardHover : AppColors.of(context).cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.4)
                  : AppColors.of(context).border,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with glow
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: 24,
                ),
              ),
              Spacer(),
              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              SizedBox(height: 4),
              // Count
              Text(
                '${widget.count} ${widget.count == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.accentColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
