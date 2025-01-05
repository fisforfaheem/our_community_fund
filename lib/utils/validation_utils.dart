class ValidationUtils {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^\+?[\d\s-]+$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }

    if (value.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }

    return null;
  }

  static String? validatePaymentDate(DateTime? value) {
    if (value == null) {
      return 'Payment date is required';
    }

    final now = DateTime.now();
    final maxDate = DateTime(now.year, now.month + 1, 0);

    if (value.isAfter(maxDate)) {
      return 'Payment date cannot be after the end of the current month';
    }

    return null;
  }

  static String? validateNote(String? value) {
    if (value != null && value.length > 500) {
      return 'Note cannot be longer than 500 characters';
    }

    return null;
  }

  static String? validateNotificationMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Message is required';
    }

    if (value.length > 200) {
      return 'Message cannot be longer than 200 characters';
    }

    return null;
  }

  static String? validateUserSelection(List<String>? value) {
    if (value == null || value.isEmpty) {
      return 'Please select at least one user';
    }

    return null;
  }

  static String? validateDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Both start and end dates are required';
    }

    if (end.isBefore(start)) {
      return 'End date must be after start date';
    }

    return null;
  }

  static String? validateMonthYear(DateTime? value) {
    if (value == null) {
      return 'Month and year are required';
    }

    final now = DateTime.now();
    if (value.isAfter(DateTime(now.year, now.month + 1, 0))) {
      return 'Cannot select future months';
    }

    return null;
  }
}
