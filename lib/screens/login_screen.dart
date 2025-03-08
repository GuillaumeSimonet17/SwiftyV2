import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home/home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks(); // Initialize AppLinks instance
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() async {
    // Get the initial deep link if the app was opened with one
    Uri? initialUri = await _appLinks.getInitialLink();

    if (initialUri != null && initialUri.queryParameters.containsKey("code")) {
      String? authCode = initialUri.queryParameters["code"];
      if (authCode != null) {
        await _exchangeCodeForToken(
            authCode); // Exchange the code for access token
      }
    }

    // Listen for dynamic deep links if not on Flutter Web
    if (!kIsWeb) {
      _appLinks.uriLinkStream.listen((Uri? uri) async {
        if (uri != null && uri.queryParameters.containsKey("code")) {
          String? authCode = uri.queryParameters["code"];
          if (authCode != null) {
            await _exchangeCodeForToken(authCode);
          }
        }
      }, onError: (err) {
        print("Error while listening to deep links: $err");
      });
    }
  }

  Future<void> _exchangeCodeForToken(String authCode) async {
    final String clientId = dotenv.env['CLIENT_ID']!;
    final String clientSecret = dotenv.env['CLIENT_SECRET']!;
    final String redirectUri = dotenv.env['REDIRECT_URI']!;
    final String tokenUrl = "https://api.intra.42.fr/oauth/token";

    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': authCode,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String accessToken = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);

        print('-----------------------------ok-----------------------------');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(accessToken: accessToken),
          ),
        );
      } else {
        print("Error while exchanging code: ${response.body}");
      }
    } catch (e) {
      print("Error caught while exchanging the code: $e");
    }
  }

  Future<void> _launchAuthUrl() async {
    final String authUrl = "https://api.intra.42.fr/oauth/authorize?"
        "client_id=${dotenv.env['CLIENT_ID']}"
        "&redirect_uri=${Uri.encodeComponent(dotenv.env['REDIRECT_URI']!)}"
        "&response_type=code";

    try {
      final Uri parsedUrl = Uri.parse(authUrl);

      if (await canLaunchUrl(parsedUrl)) {
        await launchUrl(
          parsedUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch $parsedUrl');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _launchAuthUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      // White background
                      foregroundColor: Colors.black,
                      // Black text
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      // Adjust button size
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    child: Text("Se connecter avec 42"),
                  ),
                  SvgPicture.asset(
                    'assets/42_Logo.svg',
                    height: 200,
                    color: Colors.white,
                  ),
                ]))));
  }
}
