import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkTheme = false;

  Map<String, List<ApplicationWithIcon>> categorizedApps = {
    "Essential Apps": [],
    "Less Frequent Apps": [],
    "Shopping & Food Apps": [],
    "Distracting Apps": [],
    "Other Apps": []
  };

  final Map<String, List<String>> keywordCategories = {
    "Essential Apps": ["whatsapp", "gmail", "chrome", "brave", "google", "phone", "dialer", "settings", "camera", "messages"],
    "Less Frequent Apps": ["pay", "gpay", "paytm", "phonepe", "bank", "wallet", "clock", "calendar", "gallery", "files", "calculator"],
    "Shopping & Food Apps": ["amazon", "myntra", "ajio", "flipkart", "swiggy", "zomato", "blinkit", "zepto", "ola", "uber"],
    "Distracting Apps": ["instagram", "facebook", "netflix", "snapchat", "thread", "prime video", "hotstar", "telegram", "discord", "sonyliv", "spotify", "gaana", "hungama"],
  };

  List<ApplicationWithIcon> allApps = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
      includeAppIcons: true,
    );

    setState(() {
      allApps.clear();
      categorizedApps.forEach((key, value) => value.clear());

      for (var app in apps) {
        if (app is ApplicationWithIcon) {
          String appName = app.appName.toLowerCase();
          String packageName = app.packageName.toLowerCase();

          bool categorized = false;
          for (var category in keywordCategories.keys) {
            if (_containsKeyword(appName, keywordCategories[category]!) ||
                _containsKeyword(packageName, keywordCategories[category]!)) {
              categorizedApps[category]?.add(app);
              categorized = true;
              break;
            }
          }
          if (!categorized) {
            categorizedApps["Other Apps"]?.add(app);
          }
        }
      }
    });
  }

  bool _containsKeyword(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minimalist Launcher',
      theme: isDarkTheme
          ? ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
      )
          : ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        textTheme: ThemeData.light().textTheme.apply(bodyColor: Colors.black),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Minimalist Launcher"),
          actions: [
            IconButton(
              icon: Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  isDarkTheme = !isDarkTheme;
                });
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search apps...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (query) => setState(() {}),
              ),
            ),
          ),
        ),
        body: PageView(
          children: categorizedApps.entries.map((entry) {
            return _buildCategoryPage(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryPage(String category, List<ApplicationWithIcon> apps) {
    List<ApplicationWithIcon> filteredApps = apps
        .where((app) => app.appName.toLowerCase().contains(searchController.text.toLowerCase()))
        .toList();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            category,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
            ),
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _handleAppLaunch(category, filteredApps[index], context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDarkTheme ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.apps,
                        size: 30,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      filteredApps[index].appName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleAppLaunch(String category, Application app, BuildContext context) async {
    if (category == "Distracting Apps") {
      _showChallengeDialog(app, context);
    } else {
      DeviceApps.openApp(app.packageName);
    }
  }

  void _showChallengeDialog(Application app, BuildContext context) {
    int num1 = Random().nextInt(10) + 1;
    int num2 = Random().nextInt(10) + 1;
    int correctAnswer = num1 + num2;
    TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Solve this to proceed"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$num1 + $num2 = ?"),
              TextField(controller: answerController, keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            TextButton(
              onPressed: () async {
                if (int.tryParse(answerController.text) == correctAnswer) {
                  Navigator.pop(context);
                  if (await Vibration.hasVibrator() ?? false) {
                    Vibration.vibrate(duration: 5000);
                  }
                  DeviceApps.openApp(app.packageName);
                }
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
