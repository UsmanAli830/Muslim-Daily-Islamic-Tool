import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class DuaCollectionScreen extends StatefulWidget {
  @override
  _DuaCollectionScreenState createState() => _DuaCollectionScreenState();
}

class _DuaCollectionScreenState extends State<DuaCollectionScreen> {
  List<Map<String, dynamic>> _duas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    final jsonString = await rootBundle.loadString('assets/duas.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      _duas = List<Map<String, dynamic>>.from(jsonList);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Daily Duas'),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
        elevation: 2,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
        padding: EdgeInsets.all(18),
        itemCount: _duas.length,
        separatorBuilder: (_, __) => SizedBox(height: 14),
        itemBuilder: (context, index) {
          final dua = _duas[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    dua['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.teal[800],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    dua['arabic'] ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black87,
                      fontFamily: 'Scheherazade', // Use a nice Arabic font if available
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    dua['english'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal[900],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}