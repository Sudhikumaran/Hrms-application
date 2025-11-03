import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Alternative authentication using Firebase REST API
/// This bypasses the SDK configuration issues
class FirebaseRestAuth {
  // Use the API key from firebase_options.dart (Android config)
  static const String apiKey = 'AIzaSyD95UyPhJf4FpLbZL0kyisx5BnKj5zBPb8'; // From google-services.json
  static const String authUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';

  /// Sign in with email and password using REST API
  static Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(authUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final idToken = data['idToken'] as String?;
        final localId = data['localId'] as String?;
        final email = data['email'] as String?;

        if (idToken != null && localId != null) {
          // Store auth data locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('firebase_id_token', idToken);
          await prefs.setString('firebase_user_id', localId);
          await prefs.setString('firebase_user_email', email ?? '');

          return {
            'success': true,
            'userId': localId,
            'email': email,
            'idToken': idToken,
            'message': 'Login successful',
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response from Firebase',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorObj = errorData['error'] as Map<String, dynamic>?;
          final errorMessage = (errorObj?['message'] as String?) ?? 'Authentication failed';
          
          String userMessage = 'Login failed';
          final errorMsgStr = errorMessage.toString();
          if (errorMsgStr.contains('INVALID_PASSWORD')) {
            userMessage = 'Incorrect password';
          } else if (errorMsgStr.contains('EMAIL_NOT_FOUND')) {
            userMessage = 'No account found with this email';
          } else if (errorMsgStr.contains('USER_DISABLED')) {
            userMessage = 'Account has been disabled';
          } else if (errorMsgStr.contains('TOO_MANY_ATTEMPTS')) {
            userMessage = 'Too many failed attempts. Please try again later';
          }

          return {
            'success': false,
            'message': userMessage,
            'error': errorMsgStr,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Login failed. Status code: ${response.statusCode}',
            'error': response.body.toString(),
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get current user ID from stored token
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_user_id');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('firebase_id_token');
    final userId = prefs.getString('firebase_user_id');
    return token != null && userId != null;
  }

  /// Create user account with email and password using REST API
  static Future<Map<String, dynamic>> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      const String signUpUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(signUpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final idToken = data['idToken'] as String?;
        final localId = data['localId'] as String?;
        final emailResponse = data['email'] as String?;

        if (idToken != null && localId != null) {
          // Store auth data locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('firebase_id_token', idToken);
          await prefs.setString('firebase_user_id', localId);
          await prefs.setString('firebase_user_email', emailResponse ?? '');

          return {
            'success': true,
            'uid': localId,
            'userId': localId,
            'email': emailResponse,
            'idToken': idToken,
            'message': 'Account created successfully',
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response from Firebase',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorObj = errorData['error'] as Map<String, dynamic>?;
          final errorMessage = (errorObj?['message'] as String?) ?? 'Account creation failed';
          
          // Handle error code which can be int or string
          String errorCode = 'unknown';
          if (errorObj != null && errorObj.containsKey('code')) {
            final codeValue = errorObj['code'];
            if (codeValue is String) {
              errorCode = codeValue;
            } else if (codeValue is int) {
              errorCode = codeValue.toString();
            }
          }
          
          String userMessage = 'Account creation failed';
          if (errorMessage.toString().contains('EMAIL_EXISTS')) {
            userMessage = 'Email is already registered. Please login instead.';
          } else if (errorMessage.toString().contains('INVALID_EMAIL')) {
            userMessage = 'Invalid email address';
          } else if (errorMessage.toString().contains('WEAK_PASSWORD')) {
            userMessage = 'Password is too weak. Use at least 6 characters';
          } else if (errorMessage.toString().contains('OPERATION_NOT_ALLOWED')) {
            userMessage = 'Email/password authentication is not enabled in Firebase Console';
          }

          return {
            'success': false,
            'message': userMessage,
            'error': errorMessage.toString(),
            'errorCode': errorCode,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Account creation failed. Status code: ${response.statusCode}',
            'error': response.body.toString(),
            'errorCode': 'unknown',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('firebase_id_token');
    await prefs.remove('firebase_user_id');
    await prefs.remove('firebase_user_email');
  }
}


