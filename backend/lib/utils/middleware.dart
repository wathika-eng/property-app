import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
          (path.contains('/reviews') && request.method == 'GET' && !path.contains('/user')) ||
          // Allow fetching OpenAPI/Swagger JSON without auth
          path == 'api/docs/openapi.json' ||
          path.startsWith('api/docs')) {
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

// Simple in-memory token-bucket rate limiter per IP address.
// Default limit: 60 requests per minute. You can change the value when
// registering the middleware: `rateLimitMiddleware(requestsPerMinute: 100)`.
Middleware rateLimitMiddleware({int requestsPerMinute = 60}) {
  final capacity = requestsPerMinute;
  final refillPerSecond = requestsPerMinute / 60.0;

  final Map<String, _Bucket> buckets = {};

  // Periodically clean up buckets that haven't been used for a while
  Timer.periodic(const Duration(minutes: 5), (_) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    buckets.removeWhere((_, b) => b.lastRequest.isBefore(cutoff));
  });

  return (Handler innerHandler) {
    return (Request request) async {
      // Determine client IP. Prefer X-Forwarded-For if present (behind proxy).
      String ip = 'unknown';
      final xff = request.headers['x-forwarded-for'];
      if (xff != null && xff.isNotEmpty) {
        ip = xff.split(',').first.trim();
      } else {
        final connInfo = request.context['shelf.io.connection_info'];
        if (connInfo is HttpConnectionInfo) {
          ip = connInfo.remoteAddress.address;
        }
      }

      final bucket = buckets.putIfAbsent(ip, () => _Bucket(capacity, refillPerSecond));
      bucket.lastRequest = DateTime.now();
      if (!bucket.consume(1)) {
        return Response(
          429,
          body: json.encode({'error': 'Too many requests'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

class _Bucket {
  _Bucket(this.capacity, this.refillPerSecond)
      : tokens = capacity.toDouble(),
        lastRefill = DateTime.now(),
        lastRequest = DateTime.now();

  final int capacity;
  final double refillPerSecond;
  double tokens;
  DateTime lastRefill;
  DateTime lastRequest;

  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(lastRefill).inMilliseconds / 1000.0;
    if (elapsed <= 0) return;
    tokens = (tokens + elapsed * refillPerSecond).clamp(0, capacity).toDouble();
    lastRefill = now;
  }

  bool consume(int amount) {
    _refill();
    if (tokens >= amount) {
      tokens -= amount;
      return true;
    }
    return false;
  }
}