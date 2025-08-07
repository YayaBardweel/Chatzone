// ============================================================================
// File: lib/core/utils/validators.dart (UPDATED FOR EMAIL)
// ============================================================================

import '../constants/firebase_constants.dart';

class Validators {
  // ============================================================================
  // EMAIL VALIDATION
  // ============================================================================

  /// Validates email format
  /// Returns error message if invalid, null if valid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    String trimmed = value.trim().toLowerCase();

    // Check for basic email format
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    // Check for double dots
    if (trimmed.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }

    // Check for valid domain
    List<String> parts = trimmed.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return 'Please enter a valid email address';
    }

    // Check domain part
    String domain = parts[1];
    if (domain.startsWith('.') || domain.endsWith('.') || domain.startsWith('-') || domain.endsWith('-')) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  /// Formats email for consistent storage (lowercase, trimmed)
  static String formatEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Check if email looks like a temporary/disposable email
  static bool isDisposableEmail(String email) {
    final disposableDomains = [
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'yopmail.com',
    ];

    String domain = email.split('@').last.toLowerCase();
    return disposableDomains.contains(domain);
  }

  // ============================================================================
  // PASSWORD VALIDATION
  // ============================================================================

  /// Validates password strength
  /// Returns error message if invalid, null if valid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < FirebaseConstants.passwordMinLength) {
      return 'Password must be at least ${FirebaseConstants.passwordMinLength} characters';
    }

    if (value.length > FirebaseConstants.passwordMaxLength) {
      return 'Password cannot exceed ${FirebaseConstants.passwordMaxLength} characters';
    }

    // Check for at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Check for common weak passwords
    List<String> weakPasswords = [
      '123456',
      'password',
      'password123',
      '123456789',
      'qwerty',
      'abc123',
    ];

    if (weakPasswords.contains(value.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }

    return null; // Valid
  }

  /// Validates confirm password field
  /// Returns error message if invalid, null if valid
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null; // Valid
  }

  /// Get password strength level (0-4)
  static int getPasswordStrength(String password) {
    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) strength++; // lowercase
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++; // uppercase
    if (RegExp(r'[0-9]').hasMatch(password)) strength++; // numbers
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++; // special chars

    // Return max 4
    return strength > 4 ? 4 : strength;
  }

  /// Get password strength description
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Get password strength color
  static int getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 0xFFF44336; // Red
      case 2:
        return 0xFFFF9800; // Orange
      case 3:
        return 0xFF2196F3; // Blue
      case 4:
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // ============================================================================
  // USER PROFILE VALIDATION
  // ============================================================================

  /// Validates user display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Name cannot be empty';
    }

    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmed.length > 50) {
      return 'Name cannot exceed 50 characters';
    }

    // Check for valid characters (letters, spaces, some punctuation)
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, dots, hyphens, and apostrophes';
    }

    // Check for inappropriate content (basic check)
    List<String> inappropriateWords = ['admin', 'root', 'system', 'null', 'undefined'];
    if (inappropriateWords.any((word) => trimmed.toLowerCase().contains(word))) {
      return 'Please choose a different name';
    }

    return null; // Valid
  }

  /// Validates user status/about text
  static String? validateStatus(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Status is optional
    }

    String trimmed = value.trim();

    if (trimmed.length > 139) {
      return 'Status cannot exceed 139 characters';
    }

    return null; // Valid
  }

  // ============================================================================
  // MESSAGE VALIDATION
  // ============================================================================

  /// Validates chat message content
  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Message cannot be empty';
    }

    String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Message cannot be empty';
    }

    if (trimmed.length > FirebaseConstants.maxMessageLength) {
      return 'Message is too long (max ${FirebaseConstants.maxMessageLength} characters)';
    }

    return null; // Valid
  }

  /// Checks if message is only whitespace
  static bool isEmptyMessage(String message) {
    return message.trim().isEmpty;
  }

  // ============================================================================
  // GROUP VALIDATION
  // ============================================================================

  /// Validates group name
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Group name is required';
    }

    String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Group name cannot be empty';
    }

    if (trimmed.length < 3) {
      return 'Group name must be at least 3 characters';
    }

    if (trimmed.length > 25) {
      return 'Group name cannot exceed 25 characters';
    }

    // No special characters except spaces, dots, hyphens
    if (!RegExp(r"^[a-zA-Z0-9\s.-]+$").hasMatch(trimmed)) {
      return 'Group name can only contain letters, numbers, spaces, dots, and hyphens';
    }

    return null; // Valid
  }

  /// Validates group description
  static String? validateGroupDescription(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Description is optional
    }

    String trimmed = value.trim();

    if (trimmed.length > 512) {
      return 'Description cannot exceed 512 characters';
    }

    return null; // Valid
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Checks if a string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }


  /// Checks if text contains only emojis
  static bool isOnlyEmojis(String text) {
    // Remove all spaces first
    final cleanText = text.replaceAll(' ', '');
    if (cleanText.isEmpty) return false;

    // Check if all characters are emojis
    final emojiRegex = RegExp(
      r'^(\u{1f600}-\u{1f64f}|\u{1f300}-\u{1f5ff}|\u{1f680}-\u{1f6ff}|\u{1f1e0}-\u{1f1ff}|\u{2600}-\u{26ff}|\u{2700}-\u{27bf}|\u{1f900}-\u{1f9ff}|\u{1f018}-\u{1f270})+$',
      unicode: true,
    );
    return emojiRegex.hasMatch(cleanText);
  }

  /// Validates if string has minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  /// Validates if string doesn't exceed maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; // Let other validators handle required fields
    }

    if (value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    return null;
  }

  /// Check if input contains only allowed characters
  static bool containsOnlyAllowedChars(String input, String allowedPattern) {
    return RegExp(allowedPattern).hasMatch(input);
  }

  /// Extract domain from email
  static String? extractDomain(String email) {
    try {
      return email.split('@').last.toLowerCase();
    } catch (e) {
      return null;
    }
  }

  /// Check if email domain is from a major provider
  static bool isMajorEmailProvider(String email) {
    final majorProviders = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'icloud.com',
      'protonmail.com',
      'aol.com',
    ];

    String? domain = extractDomain(email);
    return domain != null && majorProviders.contains(domain);
  }
}

// ============================================================================
// VALIDATOR EXTENSIONS (Optional - for cleaner code)
// ============================================================================

extension StringValidation on String? {
  /// Extension method for email validation
  String? get validateEmail => Validators.validateEmail(this);

  /// Extension method for password validation
  String? get validatePassword => Validators.validatePassword(this);

  /// Extension method for name validation
  String? get validateName => Validators.validateDisplayName(this);

  /// Extension method for message validation
  String? get validateMessage => Validators.validateMessage(this);

  /// Extension method for status validation
  String? get validateStatus => Validators.validateStatus(this);
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
// Example 1: Email Login Form
TextFormField(
  decoration: const InputDecoration(labelText: 'Email'),
  validator: Validators.validateEmail,
  keyboardType: TextInputType.emailAddress,
  onChanged: (value) {
    // Format email as user types
    String formatted = Validators.formatEmail(value);
  },
)

// Example 2: Password Field with Strength Indicator
TextFormField(
  decoration: const InputDecoration(labelText: 'Password'),
  validator: Validators.validatePassword,
  obscureText: true,
  onChanged: (value) {
    int strength = Validators.getPasswordStrength(value);
    String strengthText = Validators.getPasswordStrengthText(strength);
    Color strengthColor = Color(Validators.getPasswordStrengthColor(strength));
    // Update UI with strength indicator
  },
)

// Example 3: Confirm Password Field
TextFormField(
  decoration: const InputDecoration(labelText: 'Confirm Password'),
  validator: (value) => Validators.validateConfirmPassword(_passwordController.text, value),
  obscureText: true,
)

// Example 4: Using Extension Methods
class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _validateInput() {
    final emailError = _emailController.text.validateEmail;
    final passwordError = _passwordController.text.validatePassword;

    if (emailError != null) {
      _showError(emailError);
      return;
    }

    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    // Proceed with sign in
    _signIn();
  }
}

// Example 5: Multiple Validation
String? validateSignUpForm(String email, String password, String confirmPassword, String name) {
  // Validate email
  final emailError = Validators.validateEmail(email);
  if (emailError != null) return emailError;

  // Validate password
  final passwordError = Validators.validatePassword(password);
  if (passwordError != null) return passwordError;

  // Validate confirm password
  final confirmError = Validators.validateConfirmPassword(password, confirmPassword);
  if (confirmError != null) return confirmError;

  // Validate name
  final nameError = Validators.validateDisplayName(name);
  if (nameError != null) return nameError;

  return null; // All valid
}
*/