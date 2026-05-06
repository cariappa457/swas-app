import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- CustomButton Variants ---
enum CustomButtonVariant { primary, outlined, danger }

/// A premium, reusable button widget with:
///  - Scale press animation
///  - Haptic feedback (light for normal, heavy for danger)
///  - Loading state (disables taps and shows spinner)
///  - Optional leading icon
///  - Three variants: primary, outlined, danger
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDanger;
  final IconData? icon;
  final CustomButtonVariant buttonVariant;
  final double? width;
  final double height;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDanger = false,
    this.icon,
    this.buttonVariant = CustomButtonVariant.primary,
    this.width,
    this.height = 56,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.isLoading || widget.onPressed == null) return;
    _controller.forward();
  }

  Future<void> _onTapUp(TapUpDetails _) async {
    if (widget.isLoading || widget.onPressed == null) return;
    await _controller.reverse();
    // Haptic Feedback
    if (widget.isDanger) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  // --- Color Helpers ---

  Color _backgroundColor(BuildContext context) {
    if (widget.isLoading || widget.onPressed == null) {
      return Colors.grey.shade300;
    }
    if (widget.isDanger || widget.buttonVariant == CustomButtonVariant.danger) {
      return const Color(0xFFE53935);
    }
    if (widget.buttonVariant == CustomButtonVariant.outlined) {
      return Colors.transparent;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _foregroundColor(BuildContext context) {
    if (widget.isLoading || widget.onPressed == null) return Colors.grey;
    if (widget.buttonVariant == CustomButtonVariant.outlined) {
      return Theme.of(context).colorScheme.primary;
    }
    return Colors.white;
  }

  Border? _border(BuildContext context) {
    if (widget.buttonVariant == CustomButtonVariant.outlined) {
      return Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5);
    }
    return null;
  }

  List<BoxShadow> _shadows() {
    if (widget.buttonVariant == CustomButtonVariant.outlined ||
        widget.isLoading ||
        widget.onPressed == null) return [];
    final color = (widget.isDanger || widget.buttonVariant == CustomButtonVariant.danger)
        ? const Color(0xFFE53935)
        : const Color(0xFFE91E63);
    return [
      BoxShadow(
        color: color.withOpacity(0.25),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = _foregroundColor(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: _backgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: _border(context),
            boxShadow: _shadows(),
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fgColor,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fgColor, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
