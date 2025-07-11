import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umous/firebase_options.dart';
import 'package:umous/pages/login_page.dart';
import 'package:umous/pages/signup_page.dart';
import 'pages/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showLogin = true;
  bool isAuthenticated = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        isAuthenticated = user != null;
        isLoading = false;
      });
    });
  }

  void _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      isAuthenticated = user != null;
      isLoading = false;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : isAuthenticated
              ? const HomePage()
              : showLogin
                  ? LoginPage(
                      onSignupTap: () => setState(() => showLogin = false),
                      onLoginSuccess: _onLoginSuccess,
                    )
                  : SignupPage(
                      onLoginTap: () => setState(() => showLogin = true),
                      onSignupSuccess: _onLoginSuccess,
                    ),
    );
  }
}
