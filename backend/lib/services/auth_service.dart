import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthService {
  static const String _jwtSecret = 'your-super-secret-jwt-key-change-in-production';
  static const Duration _tokenExpiry = Duration(days: 7);

  static String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return salt + digest.toString();
  }

  static bool verifyPassword(String password, String hashedPassword) {
    if (hashedPassword.length < 16) return false;
    
    final salt = hashedPassword.substring(0, 16);
    final hash = hashedPassword.substring(16);
    
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    
    return digest.toString() == hash;
  }

  static String generateToken(String userId, String email, bool isLandlord) {
    final jwt = JWT({
      'userId': userId,
      'email': email,
      'isLandlord': isLandlord,
      'exp': DateTime.now().add(_tokenExpiry).millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(SecretKey(_jwtSecret));
  }

  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;
      
      // Check if token is expired
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (exp < now) {
        return null; // Token expired
      }
      
      return payload;
    } catch (e) {
      return null; // Invalid token
    }
  }

  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (i) => random.nextInt(256));
    final encoded = base64Encode(saltBytes);
    return encoded.length >= 16 ? encoded.substring(0, 16) : encoded.padRight(16, '0');
  }
}