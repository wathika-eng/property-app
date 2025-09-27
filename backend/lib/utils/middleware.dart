import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/auth_service.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Skip auth for login/register routes and public listings/reviews
      final path = request.url.path;
      if (path == 'api/auth/login' || 
          path == 'api/auth/register' ||
          path == 'api/listings' ||
          (path.startsWith('api/listings/') && request.method == 'GET') ||
          (path.contains('/reviews') && request.method == 'GET' && !path.contains('/user'))) {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          json.encode({'error': 'Authorization token required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7); // Remove 'Bearer ' prefix
      final payload = AuthService.verifyToken(token);

      if (payload == null) {
        return Response.unauthorized(
          json.encode({'error': 'Invalid or expired token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Add user info to request context
      final updatedRequest = request.change(context: {
        ...request.context,
        'userId': payload['userId'],
        'email': payload['email'],
        'isLandlord': payload['isLandlord'] ?? false,
      });

      return innerHandler(updatedRequest);
    };
  };
}