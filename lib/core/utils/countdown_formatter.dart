/// Formats the time remaining until [endAt] as a short human string, e.g.
/// "2h 14m left" or "Ended".
String formatCountdown(DateTime endAt, {DateTime? now}) {
  final remaining = endAt.difference(now ?? DateTime.now());
  if (remaining.isNegative) return 'Ended';

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m left';
  return '${minutes}m left';
}
