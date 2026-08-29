/// Formats a warning period for Japanese copy, e.g. `1時間`, `30分`, `1時間15分`.
String formatWarningPeriod(Duration period) {
  final hours = period.inHours;
  final minutes = period.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) {
    return '$hours時間$minutes分';
  }
  if (hours > 0) {
    return '$hours時間';
  }
  return '$minutes分';
}

String remainingLabel(Duration remaining) {
  if (remaining.inHours >= 1) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (minutes == 0) {
      return 'あと$hours時間';
    }
    return 'あと$hours時間$minutes分';
  }
  final minutes = remaining.inMinutes;
  if (minutes <= 0) {
    return 'あと1分未満';
  }
  return 'あと$minutes分';
}
