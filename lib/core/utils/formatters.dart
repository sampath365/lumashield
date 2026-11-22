import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String clock(int minuteOfDay) {
    final normalized = minuteOfDay % 1440;
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String clock24(int minuteOfDay) {
    final normalized = minuteOfDay % 1440;
    return '${(normalized ~/ 60).toString().padLeft(2, '0')}:'
        '${(normalized % 60).toString().padLeft(2, '0')}';
  }

  static String duration(Duration value) {
    if (value.inMinutes < 1) return '${value.inSeconds}s';
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String minutesAsDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  static String timeOfDay(DateTime time) => DateFormat.jm().format(time);

  static String dayLabel(DateTime day) => DateFormat('EEE').format(day);

  static String shortDate(DateTime day) => DateFormat('d MMM').format(day);

  static String relativeToNow(DateTime time) {
    final diff = time.difference(DateTime.now());
    if (diff.isNegative) return 'now';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return minutes == 0 ? 'in ${hours}h' : 'in ${hours}h ${minutes}m';
  }

  static String weekdayNames(Set<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'No days selected';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    if (sorted.length == 5 && sorted.every((d) => d <= 5)) return 'Weekdays';
    if (sorted.length == 2 && sorted.contains(6) && sorted.contains(7)) return 'Weekends';
    return sorted.map((d) => names[d - 1]).join(', ');
  }
}
