import 'package:intl/intl.dart';

class DateTimeUtils {
  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _timeFormatter = DateFormat('hh:mm a');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, hh:mm a');
  static final _monthYearFormatter = DateFormat('MMMM yyyy');
  static final _shortMonthYearFormatter = DateFormat('MMM yyyy');
  static final _dayFormatter = DateFormat('EEEE');
  static final _shortDayFormatter = DateFormat('EEE');
  static final _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  static String formatShortMonthYear(DateTime date) {
    return _shortMonthYearFormatter.format(date);
  }

  static String formatDay(DateTime date) {
    return _dayFormatter.format(date);
  }

  static String formatShortDay(DateTime date) {
    return _shortDayFormatter.format(date);
  }

  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String getPaymentDueText(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      final days = difference.inDays.abs();
      return 'Overdue by $days day${days == 1 ? '' : 's'}';
    } else {
      final days = difference.inDays;
      if (days == 0) {
        return 'Due today';
      } else {
        return 'Due in $days day${days == 1 ? '' : 's'}';
      }
    }
  }

  static String getMonthYearRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        return formatMonthYear(start);
      } else {
        return '${_shortMonthYearFormatter.format(start)} - ${_shortMonthYearFormatter.format(end)}';
      }
    } else {
      return '${_shortMonthYearFormatter.format(start)} - ${_shortMonthYearFormatter.format(end)}';
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static List<DateTime> getMonthDates(DateTime month) {
    final startDate = getStartOfMonth(month);
    final endDate = getEndOfMonth(month);
    final dates = <DateTime>[];

    for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    return dates;
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  static bool isPastDue(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(getStartOfDay(now));
  }

  static bool isDueSoon(DateTime dueDate, {int days = 3}) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference >= 0 && difference <= days;
  }
}
