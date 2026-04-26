import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';

/// Professional UI components with Material Design 3 and advanced animations
class ProfessionalUIComponents {
  // Color palette
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  // Text styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Color(0xFF1C1B1F),
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: Color(0xFF1C1B1F),
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: Color(0xFF1C1B1F),
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: Color(0xFF49454F),
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: Color(0xFF49454F),
  );

  /// Professional card with elevation and animations
  static Widget professionalCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
    double? elevation,
    VoidCallback? onTap,
    bool enableHover = true,
    bool enableRipple = true,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Material(
        elevation: elevation ?? 4,
        borderRadius: BorderRadius.circular(16),
        color: color ?? surfaceColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          enableFeedback: enableRipple,
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Professional button with multiple variants
  static Widget professionalButton({
    required String text,
    required VoidCallback onPressed,
    ButtonVariant variant = ButtonVariant.primary,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool fullWidth = false,
    bool isLoading = false,
    bool disabled = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: _ButtonWidget(
        text: text,
        onPressed: onPressed,
        variant: variant,
        size: size,
        icon: icon,
        isLoading: isLoading,
        disabled: disabled,
      ),
    );
  }

  /// Professional text field with validation
  static Widget professionalTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? errorText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    VoidCallback? onSuffixIconTap,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: enabled ? const Color(0xFF1C1B1F) : const Color(0xFF49454F).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            enabled: enabled,
            maxLines: maxLines,
            onChanged: onChanged,
            style: bodyLarge.copyWith(
              color: enabled ? const Color(0xFF1C1B1F) : const Color(0xFF49454F).withOpacity(0.6),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF6750A4)) : null,
              suffixIcon: suffixIcon != null
                  ? IconButton(
                      icon: Icon(suffixIcon, color: const Color(0xFF6750A4)),
                      onPressed: onSuffixIconTap,
                    )
                  : null,
              errorText: errorText,
              filled: true,
              fillColor: enabled ? const Color(0xFFF7F2FA) : const Color(0xFFE7E0EC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null ? errorColor : const Color(0xFFE7E0EC),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6750A4),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: errorColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Professional status indicator
  static Widget statusIndicator({
    required StatusType status,
    String? label,
    double size = 12,
  }) {
    final colors = {
      StatusType.success: successColor,
      StatusType.warning: warningColor,
      StatusType.error: errorColor,
      StatusType.info: primaryColor,
      StatusType.neutral: const Color(0xFF9E9E9E),
    };

    final icons = {
      StatusType.success: Icons.check_circle,
      StatusType.warning: Icons.warning,
      StatusType.error: Icons.error,
      StatusType.info: Icons.info,
      StatusType.neutral: Icons.radio_button_unchecked,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors[status],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icons[status],
            color: Colors.white,
            size: size * 0.7,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: bodyMedium.copyWith(
              color: colors[status],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Professional progress indicator
  static Widget progressIndicator({
    required double progress,
    String? label,
    Color? color,
    double height = 8,
    bool showPercentage = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || showPercentage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                if (showPercentage)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          if (label != null || showPercentage) const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFE7E0EC),
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? primaryColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Professional list tile with animations
  static Widget animatedListTile({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool enableAnimation = true,
  }) {
    return enableAnimation
        ? OpenContainer(
            closedElevation: 0,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            openShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            openColor: Colors.white,
            closedColor: Colors.transparent,
            builder: (context, action) => ListTile(
              leading: leading,
              title: Text(
                title,
                style: bodyLarge.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: bodyMedium.copyWith(color: const Color(0xFF49454F)),
                    )
                  : null,
              trailing: trailing,
            ),
            closedBuilder: (context, action) => ListTile(
              leading: leading,
              title: Text(
                title,
                style: bodyLarge.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: bodyMedium.copyWith(color: const Color(0xFF49454F)),
                    )
                  : null,
              trailing: trailing,
              onTap: onTap,
            ),
          )
        : ListTile(
            leading: leading,
            title: Text(
              title,
              style: bodyLarge.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: bodyMedium.copyWith(color: const Color(0xFF49454F)),
                  )
                : null,
            trailing: trailing,
            onTap: onTap,
          );
  }

  /// Professional dialog with animations
  static Future<T?> showProfessionalDialog<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeScaleTransition(
          animation: animation,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 16),
                  content,
                  if (actions != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Professional snackbar with animations
  static void showProfessionalSnackBar({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? action,
    String? actionLabel,
  }) {
    final colors = {
      SnackBarType.success: successColor,
      SnackBarType.warning: warningColor,
      SnackBarType.error: errorColor,
      SnackBarType.info: primaryColor,
    };

    final icons = {
      SnackBarType.success: Icons.check_circle,
      SnackBarType.warning: Icons.warning,
      SnackBarType.error: Icons.error,
      SnackBarType.info: Icons.info,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icons[type],
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: colors[type],
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: action,
              )
            : null,
      ),
    );
  }
}

/// Button widget implementation
class _ButtonWidget extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool disabled;

  const _ButtonWidget({
    required this.text,
    required this.onPressed,
    required this.variant,
    required this.size,
    this.icon,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  State<_ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<_ButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.disabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getButtonColors();
    final textStyle = _getTextStyle();
    final padding = _getPadding();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.disabled || widget.isLoading ? null : widget.onPressed,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: colors['background'],
                borderRadius: BorderRadius.circular(12),
                border: colors['border'] != null
                    ? Border.all(color: colors['border']!, width: 1)
                    : null,
                boxShadow: [
                  if (widget.variant == ButtonVariant.primary)
                    BoxShadow(
                      color: ProfessionalUIComponents.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: widget.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors['text']!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading...',
                          style: textStyle,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: _getIconSize(),
                            color: colors['text'],
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: textStyle,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Map<String, Color> _getButtonColors() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return {
          'background': ProfessionalUIComponents.primaryColor,
          'text': Colors.white,
        };
      case ButtonVariant.secondary:
        return {
          'background': ProfessionalUIComponents.surfaceColor,
          'text': ProfessionalUIComponents.primaryColor,
          'border': ProfessionalUIComponents.primaryColor,
        };
      case ButtonVariant.outline:
        return {
          'background': Colors.transparent,
          'text': ProfessionalUIComponents.primaryColor,
          'border': ProfessionalUIComponents.primaryColor,
        };
      case ButtonVariant.text:
        return {
          'background': Colors.transparent,
          'text': ProfessionalUIComponents.primaryColor,
        };
    }
  }

  TextStyle _getTextStyle() {
    final fontSize = _getFontSize();
    final fontWeight = _getFontWeight();
    final color = _getButtonColors()['text']!;

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: widget.disabled ? color.withOpacity(0.5) : color,
    );
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  FontWeight _getFontWeight() {
    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return FontWeight.w600;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return FontWeight.w500;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

/// Enums for UI components
enum ButtonVariant { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }
enum StatusType { success, warning, error, info, neutral }
enum SnackBarType { success, warning, error, info }

/// Fade scale transition for dialogs
class FadeScaleTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const FadeScaleTransition({
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutBack,
        ),
        child: child,
      ),
    );
  }
}
