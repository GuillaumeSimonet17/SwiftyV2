import 'dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_infos_wisget.dart';
import 'radar_chart_widget.dart';
import 'projects_list_widget.dart';
import 'profile_widgets.dart';
import '../utils.dart';

class HomeScreen extends StatefulWidget {
  final String accessToken;

  const HomeScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPage = 1;
  String username = '';
  late Future<Map<String, dynamic>> userDataFutureMe;
  late Future<Map<String, dynamic>>? userDataFutureSearch;
  TextEditingController _searchController = TextEditingController();
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    userDataFutureMe = fetchUserData();
    userDataFutureSearch = null;
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      final userResponse = await http.get(
        Uri.parse('https://api.intra.42.fr/v2/me'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (userResponse.statusCode == 200) {
        final data = json.decode(userResponse.body);
        setState(() {
          username = data['login'] ?? 'Inconnu';
        });
        return data;
      } else {
        throw Exception("Failed to load user data: ${userResponse.statusCode}");
      }
    } catch (e) {
      await logout(context);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllUsersData(int page) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.intra.42.fr/v2/cursus_users?filter[campus_id]=9&sort=-level&page[size]=9&page[number]=$page'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .where((user) =>
                user is Map<String, dynamic> &&
                user['user'] is Map<String, dynamic>)
            .map((user) => user as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception("Failed to load user data: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _searchExe(String value) async {
    final response = await http.get(
      Uri.parse('https://api.intra.42.fr/v2/users/$value'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('============$data');

      setState(() {
        errorMsg = '';
        userDataFutureSearch = Future.value(data);
      });
    } else {
      setState(() {
        errorMsg = 'User not found';
      });
    }
  }

  void deleteSearch() {
    setState(() {
      errorMsg = '';
      userDataFutureSearch = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.white,
          // Change la couleur ici
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Get 42',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  )),
              Padding(padding: EdgeInsets.all(8.0)),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(hintText: 'Rechercher...'),
                  onSubmitted: (value) {
                    _searchExe(value);
                  },
                  style: TextStyle(color: Colors.black),
                ),
              ),
              DropdownWidget(
                username: username,
                onLogout: () => logout(context),
              )
            ],
          ),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.secondary,
            tabs: [
              Tab(icon: Icon(Icons.person), text: "Profil"),
              Tab(icon: Icon(Icons.check), text: "Ranking"),
            ],
          ),
        ),
        body: Stack(children: [
          TabBarView(
            children: [
              Center(
                child: errorMsg.isNotEmpty
                    ? Column(
                        children: [
                          Text(errorMsg,
                              style: TextStyle(
                                color: Colors.black,
                              )
                          ),
                          ElevatedButton(
                              onPressed: deleteSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10),
                                ),
                              ),
                              child: Text('Close')),
                        ],
                      )
                    : FutureBuilder<Map<String, dynamic>>(
                  future: userDataFutureSearch ?? userDataFutureMe,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Unknown user');
                    } else if (snapshot.hasData) {
                      final user = snapshot.data!;
                      List<dynamic> cursus = user['cursus_users'];

                      dynamic cursus21 = cursus.firstWhere(
                              (element) => element['cursus_id'] == 21,
                          orElse: () => null
                      );

                      if (cursus21 == null) {
                        return Text('Cursus 21 non trouvé');
                      }

                      List<dynamic> skillsData = cursus21['skills'] ?? [];
                      List<String> skillNames = skillsData
                          .map((s) => '${s['name']}: ${(s['level'] as num).toStringAsFixed(2)}')
                          .toList();
                      List<double> skillLevels = skillsData
                          .map((s) => (s['level'] as num).toDouble())
                          .toList();

                      return SingleChildScrollView(
                        child: Container(
                          width: 700,
                          margin: EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/background.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(50),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (userDataFutureSearch != null)
                                Column(children: [
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: deleteSearch,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 30,
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text('Close'),
                                      ),
                                      SizedBox(width: 30),
                                    ],
                                  ),
                                ]),
                              SizedBox(height: 30),
                              UserInfos(
                                user: user,
                                username: user['login'],
                                staff: user['staff?'],
                                cursus: cursus21,
                                image: user['image']['link'],
                              ),
                              SizedBox(height: 70),
                              if (skillLevels.isNotEmpty)
                                RadarChartExtend(
                                  skillNames: skillNames,
                                  skillLevels: skillLevels,
                                ),
                              SizedBox(height: 70),
                              if (skillLevels.isNotEmpty)
                                ProjectsList(projects: user['projects_users']),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Text("Aucune donnée disponible");
                    }
                  },
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchAllUsersData(currentPage),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Erreur: ${snapshot.error}'));
                        } else if (snapshot.hasData) {
                          List<Map<String, dynamic>> data = snapshot.data!;

                          return ProfilesList(
                              currentPage: currentPage, data: data);
                        } else {
                          return Center(
                              child: Text('Aucune donnée disponible'));
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 700,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: currentPage > 1
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10), // Coins arrondis
                              ),
                            ),
                            child: Text("Précédent"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                currentPage++;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              // Fond blanc
                              foregroundColor: Color(0xFF003366),
                              // Texte noir
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              // Ajuste la taille du bouton
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10), // Coins arrondis
                              ),
                            ),
                            child: Text("Suivant"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
