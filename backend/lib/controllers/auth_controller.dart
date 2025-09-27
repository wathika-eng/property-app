import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthController {
  static const _uuid = Uuid();

  static Future<Response> register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;
      final name = data['name'] as String?;
      final isLandlord = data['is_landlord'] as bool? ?? false;

      if (email == null || password == null || name == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Email, password, and name are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (password.length < 6) {
        return Response.badRequest(
          body: json.encode({'error': 'Password must be at least 6 characters'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      // Check if user already exists
      final existing = db.select(
        'SELECT id FROM users WHERE email = ?',
        [email],
      );

      if (existing.isNotEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'User with this email already exists'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create new user
      final user = User(
        id: _uuid.v4(),
        email: email,
        passwordHash: AuthService.hashPassword(password),
        name: name,
        isLandlord: isLandlord,
        createdAt: DateTime.now(),
      );

      db.execute(
        '''INSERT INTO users (id, email, password_hash, name, profile_image, is_landlord, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          user.id,
          user.email,
          user.passwordHash,
          user.name,
          user.profileImage,
          user.isLandlord ? 1 : 0,
          user.createdAt.toIso8601String(),
        ],
      );

      final token = AuthService.generateToken(user.id, user.email, user.isLandlord);

      return Response.ok(
        json.encode({
          'token': token,
          'user': user.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Registration failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;

      if (email == null || password == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Email and password are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      final result = db.select(
        'SELECT * FROM users WHERE email = ?',
        [email],
      );

      if (result.isEmpty) {
        return Response.unauthorized(
          json.encode({'error': 'Invalid email or password'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userMap = result.first;
      final user = User.fromMap(userMap);

      if (!AuthService.verifyPassword(password, user.passwordHash)) {
        return Response.unauthorized(
          json.encode({'error': 'Invalid email or password'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = AuthService.generateToken(user.id, user.email, user.isLandlord);
      print(token);
      return Response.ok(
        json.encode({
          'token': token,
          'user': user.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Login failed'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> profile(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final db = DatabaseService.database;

      final result = db.select(
        'SELECT * FROM users WHERE id = ?',
        [userId],
      );

      if (result.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final user = User.fromMap(result.first);

      return Response.ok(
        json.encode({'user': user.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to get profile'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}