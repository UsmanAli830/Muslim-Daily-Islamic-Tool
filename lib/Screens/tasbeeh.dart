import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbeehScreen extends StatefulWidget {
  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _tasbeehCount = 0;
  int _tasbeehTarget = 33;
  int _tasbeehLoop = 1;
  bool _isLoaded = false;

  @override
  void dispose() {
    _saveTasbeehState(); // save latest values before leaving
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTasbeehState();
  }

  Future<void> _loadTasbeehState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _tasbeehCount = prefs.getInt('tasbeehCount') ?? 0;
        _tasbeehTarget = prefs.getInt('tasbeehTarget') ?? 33;
        _tasbeehLoop = prefs.getInt('tasbeehLoop') ?? 1;
        _isLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading SharedPreferences: $e");
      setState(() => _isLoaded = true); // avoid infinite loading
    }
  }


  Future<void> _saveTasbeehState({int? count, int? target, int? loop}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbeehCount', count ?? _tasbeehCount);
    await prefs.setInt('tasbeehTarget', target ?? _tasbeehTarget);
    await prefs.setInt('tasbeehLoop', loop ?? _tasbeehLoop);
  }

  void _incrementTasbeeh() async {
    int newCount = _tasbeehCount + 1;
    int newLoop = _tasbeehLoop;
    if (newCount >= _tasbeehTarget) {
      newCount = 0;
      newLoop++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tasbeeh loop $newLoop started!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    setState(() {
      _tasbeehCount = newCount;
      _tasbeehLoop = newLoop;
    });
    await _saveTasbeehState(count: newCount, loop: newLoop);
  }

  void _showSetTargetDialog() {
    TextEditingController controller =
    TextEditingController(text: _tasbeehTarget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Tasbeeh Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Enter Tasbeeh Target'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              int? newTarget = int.tryParse(controller.text);
              if (newTarget != null && newTarget > 0) {
                setState(() {
                  _tasbeehTarget = newTarget;
                  _tasbeehCount = 0;
                  _tasbeehLoop = 1;
                });
                await _saveTasbeehState(count: 0, target: newTarget, loop: 1);
                Navigator.of(context).pop();
              }
            },
            child: Text('Set'),
          ),
        ],
      ),
    );
  }

  void _refreshTasbeeh() async {
    setState(() {
      _tasbeehCount = 0;
      _tasbeehLoop = 1;
    });
    await _saveTasbeehState(count: 0, loop: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasbeeh'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Reset Tasbeeh",
            onPressed: _refreshTasbeeh,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: "Set Target",
            onPressed: _showSetTargetDialog,
          ),
        ],
      ),
      body: !_isLoaded
          ? Center(child: CircularProgressIndicator())
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tasbeeh Target: $_tasbeehTarget',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Current Count: $_tasbeehCount',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tasbeeh Loop: $_tasbeehLoop',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _incrementTasbeeh,
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(48),
                backgroundColor: Colors.green,
              ),
              child: Text(
                '+1',
                style: TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Tap the button to add Tasbeeh!',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),

    ),
    );
  }
}