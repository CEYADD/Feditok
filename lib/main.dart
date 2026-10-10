import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/feed_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializzazione Supabase con credenziali da env
  await Supabase.initialize(
    url: 'https://echqiwnipjxuscpwphto.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjaHFpd25pcGp4dXNjcHdwaHRvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc5MTYxMzQ0MSwiZXhwIjoyMTA3MTg5NDQxfQ.r-htntjMIPfQG3isEJCtPFauOVdmx9Zz4bhpC81mcy8',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
      ],
      child: const FeditokApp(),
    ),
  );
}

class FeditokApp extends StatelessWidget {
  const FeditokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feditok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF6C5CE7),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C5CE7),
          secondary: Color(0xFF00CEC9),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const WelcomeScreen();
    }
  }
}
