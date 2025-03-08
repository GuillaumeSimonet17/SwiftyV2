import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token'); // Retourne le token ou null
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0C3E54), // Utilise la variable définie
          secondary: Color(0XFF366553),
        ),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        // scaffoldBackgroundColor: Color(0xFF003366),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.blue.shade50),
          titleLarge: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade50),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.blue.shade50,
                width: 2,
              ),
            ),
          ),
        ),
      ),

      home: FutureBuilder<String?>(
        future: _getAccessToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasData && snapshot.data == true) {
            return HomeScreen(accessToken: snapshot.data!); // Redirige vers la Home si token valide
          } else {
            return LoginScreen(); // Sinon vers Login
          }
        },
      ),
    );
  }
}
