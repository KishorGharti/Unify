import 'package:flutter/material.dart';

class AppDimensions {
  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double space2Xl = 32.0;
  static const double space3Xl = 48.0;

  // Border Radii
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;
  static const double radius2Xl = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius rounded2Xl = BorderRadius.all(Radius.circular(radius2Xl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Heights & Sizes
  static const double buttonHeight = 48.0;
  static const double buttonHeightSm = 36.0;
  static const double inputHeight = 50.0;
  static const double bottomNavHeight = 68.0;
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 44.0;
  static const double avatarSizeLg = 56.0;
  static const double avatarSizeXl = 80.0;
}
