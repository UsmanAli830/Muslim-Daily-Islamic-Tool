import 'package:flutter/material.dart';
import 'package:muslim_daily/Screens/Prayer_screen.dart';
import 'package:muslim_daily/Screens/mosques.dart';
import 'package:muslim_daily/Screens/qibla.dart';
import 'package:muslim_daily/Screens/tasbeeh.dart';
import 'package:muslim_daily/Services/location_permission.dart';
import 'calender.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchedCity = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔍 Search Bar

                // 🕌 Welcome Text
                Text(
                  'Welcome to Muslim Daily',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // 📅 Calendar Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HijriCalendarPage()),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Text(
                        'Calendar',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => QiblahCompassScreen()),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Text(
                        'Find qibla',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TasbeehScreen()),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Text(
                        'Tasbeeh',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PrayerTimesScreen()),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Text(
                        'Prayer Times',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NearbyMosquesMap()),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Text(
                        'Nearby Mosques',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),



              ],
            ),
          ),
        ),
      ),
    );
  }
}
