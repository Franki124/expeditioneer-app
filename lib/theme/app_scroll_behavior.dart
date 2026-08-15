import 'package:flutter/material.dart';

/// Suppresses the persistent scrollbar `MaterialScrollBehavior` draws by
/// default on web/desktop — this app doesn't want one on any scrollable
/// view (the Journal grid, the Leaderboard list once it's long, etc.).
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}
