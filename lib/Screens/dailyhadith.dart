import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HadithPage extends StatefulWidget {
  const HadithPage({Key? key}) : super(key: key);

  @override
  State<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends State<HadithPage> {
  Map<String, dynamic>? hadithData;
  bool loading = true;
  bool offline = false;

  @override
  void initState() {
    super.initState();
    fetchHadith();
  }

  Future<void> fetchHadith() async {
    setState(() {
      loading = true;
      offline = false;
    });

    const totalHadith = 5000;
    final startDate = DateTime(2025, 8, 18); // today = hadith 1
    final today = DateTime.now();
    final diffDays = today.difference(startDate).inDays;
    final hadithNumber = (diffDays % totalHadith) + 1;

    final url =
        "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-abudawud/$hadithNumber.json";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        hadithData = jsonDecode(response.body);
        // Store in shared preferences
        await storeHadithLocally(response.body);
        setState(() {
          loading = false;
          offline = false;
        });
        return;
      }
      // If API fails, try local
      await loadHadithFromLocal();
    } catch (e) {
      await loadHadithFromLocal();
    }
  }

  Future<void> storeHadithLocally(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_hadith', jsonString);
  }

  Future<void> loadHadithFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final localHadith = prefs.getString('last_hadith');
    if (localHadith != null) {
      setState(() {
        hadithData = jsonDecode(localHadith);
        loading = false;
        offline = true;
      });
    } else {
      setState(() {
        hadithData = null;
        loading = false;
        offline = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFc8e6c9), Color(0xFF43a047)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  "Daily Hadith",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: "Back",
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: "Refresh",
                    onPressed: () => fetchHadith(),
                  ),
                ],
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : hadithData == null
                    ? const Center(
                  child: Text(
                    "No Hadith available.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
                    : buildHadithCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHadithCard() {
    final hadith = hadithData!['hadiths'][0];
    final reference = hadith['reference'];
    final metadata = hadithData!['metadata'];
    final section = (metadata['section'] as Map).values.first;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (offline)
                Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.red[700], size: 20),
                    const SizedBox(width: 5),
                    Text(
                      "Offline: showing last hadith",
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              if (offline) const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.menu_book, color: Colors.green, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metadata['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hadith['text'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "📖 Reference: Book ${reference['book']}, Hadith ${reference['hadith']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.green),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(metadata['name'], style: const TextStyle(color: Colors.green)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Section: $section"),
                            const SizedBox(height: 10),
                            Text("Arabic Number: ${hadith['arabicnumber']}"),
                            const SizedBox(height: 10),
                            Text("Grades:"),
                            ...(hadith['grades'] as List)
                                .map<Widget>(
                                  (g) => Text("- ${g['name']}: ${g['grade']}"),
                            )
                                .toList(),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}