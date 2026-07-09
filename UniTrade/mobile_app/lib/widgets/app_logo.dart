import 'package:flutter/material.dart';
import '../theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? textColor;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 24.0,
    this.textColor,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_mark.png',
          width: size * 1.5,
          height: size * 1.5,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Code-based Logo "U" as fallback
            return Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'U',
                  style: TextStyle(
                    fontSize: size * 2.2,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE67E22),
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                // Fake cut-out effect for the right stem of 'U'
                Positioned(
                  top: size * 0.2,
                  right: size * 0.1,
                  child: Container(
                    width: size * 0.6,
                    height: size * 0.6,
                    decoration: BoxDecoration(color: context.bgColor, // Match background color for cut-out effect
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (showText) ...[
          SizedBox(width: size * 0.4),
          Text(
            'UniTrade',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: textColor ?? const Color(0xFF2C3E50),
            ),
          ),
        ],
      ],
    );
  }
}
