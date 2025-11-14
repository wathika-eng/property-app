import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/listings_provider.dart';
import 'providers/bookmarks_provider.dart';
import 'providers/bookings_provider.dart';
import 'providers/reviews_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/main_navigation_screen.dart';
import 'screens/listings_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

void main() {
  runApp(const StaySpaceApp());
}

class StaySpaceApp extends StatelessWidget {
  const StaySpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ListingsProvider()),
        ChangeNotifierProvider(create: (context) => BookmarksProvider()),
        ChangeNotifierProvider(create: (context) => BookingsProvider()),
        ChangeNotifierProvider(create: (context) => ReviewsProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
  // Show listings first for all users; login is optional and can be triggered later
  home: const ListingsScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainNavigationScreen(),
          '/listings': (context) => const ListingsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    // Check authentication status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      void navigateAfterLoad() {
        if (authProvider.isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }

      if (authProvider.isLoading) {
        // Wait until loading finishes
        _authListener = () {
          if (!authProvider.isLoading) {
            navigateAfterLoad();
            if (_authListener != null) authProvider.removeListener(_authListener!);
          }
        };
        authProvider.addListener(_authListener!);
      } else {
        navigateAfterLoad();
      }
    });
  }

  @override
  void dispose() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_authListener != null) {
      authProvider.removeListener(_authListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
