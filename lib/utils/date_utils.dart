import 'package:intl/intl.dart';

class AppDateUtils {
  // Date formatters
  static final DateFormat dayMonthYear = DateFormat('MMM d, y');
  static final DateFormat fullDate = DateFormat('EEEE, MMMM d, y');
  static final DateFormat monthYear = DateFormat('MMMM y');
  static final DateFormat timeOnly = DateFormat('h:mm a');
  
  // Get date without time for comparison
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  // Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return dateOnly(date1) == dateOnly(date2);
  }
  
  // Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }
  
  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
  
  // Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return dateOnly(date.subtract(Duration(days: daysFromMonday)));
  }
  
  // Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final startOfWeekDate = startOfWeek(date);
    return startOfWeekDate.add(const Duration(days: 6));
  }
  
  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  // Get days in month
  static int daysInMonth(DateTime date) {
    return endOfMonth(date).day;
  }
  
  // Get relative date string (Today, Yesterday, etc.)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      final now = DateTime.now();
      final difference = dateOnly(now).difference(dateOnly(date)).inDays;
      
      if (difference < 7) {
        return DateFormat('EEEE').format(date); // Day of week
      } else if (difference < 365) {
        return DateFormat('MMM d').format(date); // Month day
      } else {
        return DateFormat('MMM d, y').format(date); // Month day, year
      }
    }
  }
  
  // Get weekday names
  static List<String> getWeekdayNames({bool short = false}) {
    if (short) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else {
      return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    }
  }
  
  // Get weekday name by index (1-7)
  static String getWeekdayName(int weekday, {bool short = false}) {
    final names = getWeekdayNames(short: short);
    return names[weekday - 1];
  }
  
  // Get days between two dates
  static List<DateTime> getDaysBetween(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = dateOnly(start);
    final endDate = dateOnly(end);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }
  
  // Get week dates (Monday to Sunday)
  static List<DateTime> getWeekDates(DateTime date) {
    final startOfWeekDate = startOfWeek(date);
    return List.generate(7, (index) => startOfWeekDate.add(Duration(days: index)));
  }
  
  // Calculate age from date
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  // Format duration in human readable format
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'Just now';
    }
  }
  
  // Get time ago string
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    return formatDuration(difference) + ' ago';
  }
}
