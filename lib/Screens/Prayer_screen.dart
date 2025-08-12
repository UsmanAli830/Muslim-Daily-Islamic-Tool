import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import 'NamazTrackerScreen.dart';

class PrayerTimesScreen extends StatefulWidget {
  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  bool _loading = true;
  Map<String, String> _prayerTimes = {};
  Map<String, DateTime> _prayerTimesDateTime = {};
  List<Map<String, dynamic>> _cities = [];
  TextEditingController _cityController = TextEditingController();
  String _selectedZone = "";
  Map<String, dynamic>? _selectedCity;
  bool _notificationSwitch = false;

  final String _apiKey = "A93ZJTWRZK52"; // <<< Your TimeZoneDB API key

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _initAwesomeNotifications();
    _requestNotificationPermission();
    _loadNotificationPreference();
    _loadSelectedCity();
    _loadCities().then((_) => _refreshPrayerTimes());
  }

  void _initAwesomeNotifications() {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Namaz Reminder',
          channelDescription: 'Reminders for prayer times',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );
  }

  Future<void> _refreshPrayerTimes() async {
    if (_selectedCity != null) {
      await _calculatePrayerTimes(_selectedCity!['lat'], _selectedCity!['lng']);
    } else {
      await _getPrayerTimesFromLocation();
    }
  }

  Future<void> _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Notification permission requested. Please enable!")),
      );
    }
  }

  Future<void> _loadCities() async {
    final csvData = await rootBundle.loadString('assets/worldcities.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

    _cities = rows.skip(1).map((row) {
      return {
        'city': row[0].toString(),
        'lat': double.tryParse(row[2].toString()) ?? 0.0,
        'lng': double.tryParse(row[3].toString()) ?? 0.0,
        'country': row[4].toString(),
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> _getTimeZoneDB(double lat, double lng) async {
    try {
      final tzResponse = await http.get(Uri.parse(
          "http://api.timezonedb.com/v2.1/get-time-zone?key=$_apiKey&format=json&by=position&lat=$lat&lng=$lng"
      ));

      if (tzResponse.statusCode == 200) {
        final data = jsonDecode(tzResponse.body);
        if (data["status"] == "OK") {
          return {
            "zoneName": data["zoneName"],
            "localTime": data["formatted"],
          };
        }
      }
    } catch (e) {
      debugPrint("Timezone fetch error: $e");
    }
    return null;
  }

  Future<void> _getPrayerTimesFromLocation() async {
    setState(() => _loading = true);

    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permission denied")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _calculatePrayerTimes(position.latitude, position.longitude);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _schedulePrayerNotifications(Map<String, DateTime> times) async {
    int id = 2000; // start from 2000 to avoid collision with test notification
    for (var prayer in times.keys) {
      final time = times[prayer];
      if (time!.isAfter(DateTime.now())) {
        try {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: id++,
              channelKey: 'basic_channel',
              title: '$prayer Time',
              body: "Hayya ala-l-falah. It's time for $prayer.",
              notificationLayout: NotificationLayout.Default,
            ),
            schedule: NotificationCalendar(
              year: time.year,
              month: time.month,
              day: time.day,
              hour: time.hour,
              minute: time.minute,
              second: time.second,
              preciseAlarm: true,
              timeZone: AwesomeNotifications.localTimeZoneIdentifier,
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to schedule $prayer notification: $e"),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _cancelPrayerNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> _calculatePrayerTimes(double lat, double lng) async {
    setState(() {
      _loading = true;
      _selectedZone = "";
    });

    Map<String, dynamic>? tzResult = await _getTimeZoneDB(lat, lng);

    String zoneName = "UTC";
    tz.Location cityLocation = tz.getLocation('UTC');
    tz.TZDateTime nowInZone = tz.TZDateTime.now(cityLocation);

    if (tzResult != null && tzResult["zoneName"] != null) {
      zoneName = tzResult["zoneName"];
      try {
        cityLocation = tz.getLocation(zoneName);
        nowInZone = tz.TZDateTime.now(cityLocation);
      } catch (e) {
        cityLocation = tz.getLocation('UTC');
        nowInZone = tz.TZDateTime.now(cityLocation);
      }
    }

    final myCoordinates = Coordinates(lat, lng);

    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    final prayerTimes = PrayerTimes(
      myCoordinates,
      DateComponents(nowInZone.year, nowInZone.month, nowInZone.day),
      params,
    );

    final formatter = DateFormat.jm();

    final fajrCity = tz.TZDateTime.from(prayerTimes.fajr.toUtc(), cityLocation);
    final sunriseCity = tz.TZDateTime.from(prayerTimes.sunrise.toUtc(), cityLocation);
    final dhuhrCity = tz.TZDateTime.from(prayerTimes.dhuhr.toUtc(), cityLocation);
    final asrCity = tz.TZDateTime.from(prayerTimes.asr.toUtc(), cityLocation);
    final maghribCity = tz.TZDateTime.from(prayerTimes.maghrib.toUtc(), cityLocation);
    final ishaCity = tz.TZDateTime.from(prayerTimes.isha.toUtc(), cityLocation);

    setState(() {
      _prayerTimes = {
        "Fajr": formatter.format(fajrCity),
        "Sunrise": formatter.format(sunriseCity),
        "Dhuhr": formatter.format(dhuhrCity),
        "Asr": formatter.format(asrCity),
        "Maghrib": formatter.format(maghribCity),
        "Isha": formatter.format(ishaCity),
      };
      _prayerTimesDateTime = {
        "Fajr": fajrCity,
        "Dhuhr": dhuhrCity,
        "Asr": asrCity,
        "Maghrib": maghribCity,
        "Isha": ishaCity,
      };
      _loading = false;
      _selectedZone = zoneName;
    });

    // If switch is ON, schedule notifications
    if (_notificationSwitch) {
      await _schedulePrayerNotifications(_prayerTimesDateTime);
    } else {
      await _cancelPrayerNotifications();
    }
  }

  Future<void> _saveSelectedCity(Map<String, dynamic>? city) async {
    final prefs = await SharedPreferences.getInstance();
    if (city == null) {
      await prefs.remove('selectedCity');
    } else {
      await prefs.setString('selectedCity', jsonEncode(city));
    }
  }

  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final cityString = prefs.getString('selectedCity');
    if (cityString != null) {
      setState(() {
        _selectedCity = jsonDecode(cityString);
        _refreshPrayerTimes();
      });
    }
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationSwitch', value);
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('notificationSwitch');
    setState(() {
      _notificationSwitch = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prayer Times"),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            tooltip: "Use Current Location",
            onPressed: () async {
              setState(() {
                _selectedCity = null;
              });
              await _saveSelectedCity(null);
              await _getPrayerTimesFromLocation();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TypeAheadField<Map<String, dynamic>>(
              suggestionsCallback: (pattern) async {
                return _cities.where((city) => city['city']
                    .toLowerCase()
                    .contains(pattern.toLowerCase())).toList();
              },
              builder: (context, controller, focusNode) {
                _cityController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search City',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text('${suggestion['city']}'),
                  subtitle: Text('${suggestion['country']}'),
                );
              },
              onSelected: (suggestion) async {
                _cityController.text = suggestion['city'];
                setState(() {
                  _selectedCity = suggestion;
                });
                await _saveSelectedCity(suggestion);
                await _calculatePrayerTimes(suggestion['lat'], suggestion['lng']);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Namaz Reminders"),
              Switch(
                value: _notificationSwitch,
                onChanged: (value) async {
                  setState(() {
                    _notificationSwitch = value;
                  });
                  await _saveNotificationPreference(value);
                  await _refreshPrayerTimes();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          value
                              ? "Namaz reminders enabled"
                              : "Namaz reminders disabled"
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : ListView(
              children: _prayerTimes.entries.map((entry) {
                return ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text(entry.key),
                  trailing: Text(entry.value),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            child: Text("Test Awesome Notification (after 30 sec)"),
            onPressed: () async {
              bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
              if (!isAllowed) {
                await AwesomeNotifications().requestPermissionToSendNotifications();
              }
              DateTime now = DateTime.now().add(Duration(seconds: 30));
              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: 1001,
                  channelKey: 'basic_channel',
                  title: 'Test Notification',
                  body: 'This notification appeared 30 seconds after you clicked!',
                  notificationLayout: NotificationLayout.Default,
                ),
                schedule: NotificationCalendar(
                  year: now.year,
                  month: now.month,
                  day: now.day,
                  hour: now.hour,
                  minute: now.minute,
                  second: now.second,
                  preciseAlarm: true,
                  timeZone: AwesomeNotifications.localTimeZoneIdentifier,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notification scheduled for 30 seconds later!'))
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text("Namaz Tracker"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NamazTrackerScreen(
                          todayPrayerTimes: _prayerTimesDateTime,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}