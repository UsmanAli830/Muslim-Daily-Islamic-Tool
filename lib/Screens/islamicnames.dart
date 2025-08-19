import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class IslamicNamesScreen extends StatefulWidget {
  @override
  _IslamicNamesScreenState createState() => _IslamicNamesScreenState();
}

class _IslamicNamesScreenState extends State<IslamicNamesScreen> {
  List<String> _maleNames = [];
  List<String> _femaleNames = [];
  List<String> _displayedNames = [];
  String _selectedGender = "Boy";
  String _search = "";

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final maleCsv = await rootBundle.loadString('assets/males_en.csv');
    final femaleCsv = await rootBundle.loadString('assets/females_en.csv');
    setState(() {
      _maleNames = _parseCsv(maleCsv);
      _femaleNames = _parseCsv(femaleCsv);
      _displayedNames = _maleNames;
    });
  }

  List<String> _parseCsv(String csv) {
    final rows = const CsvToListConverter().convert(csv, eol: '\n');
    if (rows.isNotEmpty &&
        rows.first.length == 1 &&
        rows.first.first is String &&
        rows.first.first.toString().toLowerCase().contains("name")) {
      return rows.skip(1).map((row) => row[0].toString()).toList();
    }
    return rows.map((row) => row[0].toString()).toList();
  }

  void _onGenderChanged(String gender) {
    setState(() {
      _selectedGender = gender;
      _displayedNames = (gender == "Boy") ? _maleNames : _femaleNames;
      _search = "";
    });
  }

  List<String> _filterNames(String query) {
    if (query.isEmpty) return _displayedNames;
    return _displayedNames
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNames = _filterNames(_search);

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Islamic Names",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Find Islamic ${_selectedGender == "Boy" ? "Boys" : "Girls"} Names",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.teal[900],
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 18),
            // Search Field
            Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search ${_selectedGender} Names...",
                  prefixIcon: Icon(Icons.search, color: Colors.teal[800]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                ),
                onChanged: (value) {
                  setState(() => _search = value);
                },
              ),
            ),
            SizedBox(height: 14),
            // Gender Selector
            Container(
              alignment: Alignment.center,
              child: Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.male, color: _selectedGender == "Boy" ? Colors.white : Colors.teal[800]),
                          SizedBox(width: 4),
                          Text("Boy", style: TextStyle(color: _selectedGender == "Boy" ? Colors.white : Colors.teal[800])),
                        ],
                      ),
                    ),
                    selected: _selectedGender == "Boy",
                    selectedColor: Colors.teal[700],
                    backgroundColor: Colors.white,
                    onSelected: (selected) => _onGenderChanged("Boy"),
                  ),
                  ChoiceChip(
                    label: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.female, color: _selectedGender == "Girl" ? Colors.white : Colors.teal[800]),
                          SizedBox(width: 4),
                          Text("Girl", style: TextStyle(color: _selectedGender == "Girl" ? Colors.white : Colors.teal[800])),
                        ],
                      ),
                    ),
                    selected: _selectedGender == "Girl",
                    selectedColor: Colors.teal[700],
                    backgroundColor: Colors.white,
                    onSelected: (selected) => _onGenderChanged("Girl"),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: filteredNames.isEmpty
                  ? Center(
                child: Text(
                  "No names found",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              )
                  : Scrollbar(
                child: ListView.separated(
                  itemCount: filteredNames.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final name = filteredNames[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Text(
                            name.isNotEmpty ? name[0] : "",
                            style: TextStyle(
                              color: Colors.teal[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: Colors.teal[900],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}