class AppBreakpoints {
  AppBreakpoints._();

  /// Browser window width at/above which the web layout switches from the
  /// mobile letterbox + bottom nav to the wider desktop layout + nav rail.
  static const desktop = 840.0;

  /// Letterboxed content width below [desktop] — the original mobile-only
  /// width, unchanged.
  static const mobileContentMaxWidth = 480.0;

  /// Content width once the desktop layout kicks in. Still a bounded,
  /// centered column (not full-bleed) — the app is single-column and
  /// phone-shaped, not a desktop-grade dashboard.
  static const desktopContentMaxWidth = 960.0;

  /// Max width for a single AppButton when expanded, once desktop layout
  /// is active — keeps primary CTAs from stretching the full content
  /// column width.
  static const buttonMaxWidth = 360.0;

  /// Max width for RevealModal's card at desktop widths.
  static const dialogMaxWidth = 420.0;

  /// Max width for the QR scan viewfinder at desktop widths — it's a
  /// square (aspectRatio 1), so left uncapped it grows as tall as the
  /// content column is wide and pushes everything below it off-screen.
  static const scanViewfinderMaxWidth = 420.0;
}
