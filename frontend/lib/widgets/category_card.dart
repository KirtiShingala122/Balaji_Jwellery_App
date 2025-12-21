import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category.dart';
import '../config/api_config.dart';

class CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.25 : 0.15),
                  blurRadius: _isHovered ? 25 : 15,
                  offset: Offset(0, _isHovered ? 12 : 8),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image or Placeholder
                  _buildBackground(),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                              icon: Icons.edit_outlined,
                              onPressed: widget.onEdit,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8.w),
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              onPressed: widget.onDelete,
                              color: Colors.red,
                            ),
                          ],
                        ),

                        // Category Name at Bottom
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.category.name.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.category.description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.sp,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.category.imagePath != null &&
        widget.category.imagePath!.isNotEmpty) {
      return Image.network(
        '${Api.baseHost}${widget.category.imagePath}',
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    // Create beautiful gradient backgrounds for categories without images
    final gradients = [
      [const Color(0xFFD4A574), const Color(0xFF8B6F47)], // Gold
      [const Color(0xFFC9ADA7), const Color(0xFF9A8C98)], // Rose Gold
      [const Color(0xFFE8C5B5), const Color(0xFFB8A398)], // Champagne
      [const Color(0xFFBDB2A8), const Color(0xFF8B7E74)], // Silver
    ];

    final gradient =
        gradients[widget.category.name.hashCode.abs() % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.diamond_outlined,
          size: 80.w,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(8.w),
          child: Icon(icon, size: 20.w, color: color),
        ),
      ),
    );
  }
}
