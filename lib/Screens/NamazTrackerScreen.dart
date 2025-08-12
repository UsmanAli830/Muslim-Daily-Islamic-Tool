import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

final List<String> prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

class NamazTrackerScreen extends StatefulWidget {
  final Map<String, DateTime> todayPrayerTimes;
  NamazTrackerScreen({required this.todayPrayerTimes});

  @override
  State<NamazTrackerScreen> createState() => _NamazTrackerScreenState();
}

class _NamazTrackerScreenState extends State<NamazTrackerScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime calendarRefDate = DateTime.now(); // Used for week/month navigation
  bool showWeek = true;
  Map<String, Map<String, bool>> allStatuses = {}; // dateStr -> prayer -> bool

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    allStatuses = {};
    final data = prefs.getString('namaz_statuses');
    if (data != null) {
      final jsonMap = jsonDecode(data) as Map<String, dynamic>;
      jsonMap.forEach((dateStr, prayersMap) {
        allStatuses[dateStr] = Map<String, bool>.from(prayersMap);
      });
    }
    setState(() {});
  }

  Future<void> _saveStatusForDate(String dateStr, Map<String, bool> status) async {
    allStatuses[dateStr] = status;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('namaz_statuses', jsonEncode(allStatuses));
    setState(() {});
  }

  String _dateString(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  Map<String, bool> _getStatusForDate(DateTime date) {
    final dstr = _dateString(date);
    return allStatuses[dstr] ?? {for (var p in prayers) p: false};
  }

  /// Returns a list of DateTime objects for current week or month view
  List<DateTime> _getCalendarDates() {
    if (showWeek) {
      // Week view: start from Sunday (or your locale)
      int weekday = calendarRefDate.weekday; // 1=Mon, 7=Sun
      DateTime weekStart = calendarRefDate.subtract(Duration(days: weekday % 7));
      return List.generate(7, (i) => weekStart.add(Duration(days: i)));
    } else {
      // Month view
      final year = calendarRefDate.year;
      final month = calendarRefDate.month;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      return List.generate(daysInMonth, (i) => DateTime(year, month, i + 1));
    }
  }

  /// Move calendarRefDate by one week or one month
  void _goToPrev() {
    setState(() {
      if (showWeek) {
        calendarRefDate = calendarRefDate.subtract(Duration(days: 7));
      } else {
        calendarRefDate = DateTime(calendarRefDate.year, calendarRefDate.month - 1, calendarRefDate.day);
      }
    });
  }

  void _goToNext() {
    setState(() {
      if (showWeek) {
        calendarRefDate = calendarRefDate.add(Duration(days: 7));
      } else {
        calendarRefDate = DateTime(calendarRefDate.year, calendarRefDate.month + 1, calendarRefDate.day);
      }
    });
  }

  bool canTickPrayer(DateTime? prayerTime, DateTime selectedDate) {
    if (prayerTime == null) return false;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    // For previous days, always allow ticking
    if (selectedDay.isBefore(todayDate)) return true;
    // For future days, not allowed
    if (selectedDay.isAfter(todayDate)) return false;
    // For today, only if prayer time has passed
    return now.isAfter(prayerTime);
  }

  @override
  Widget build(BuildContext context) {
    // UI colors from your image
    final bgColor = Color(0xFF0D4746); // Deep teal (background)
    final selectedCircleColor = Color(0xFF00B2FF); // Blue for selected/ticked
    final outlinedCircleColor = Colors.white; // White for outline
    final textColor = Colors.white;

    final calendarDates = _getCalendarDates();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text("Namaz Tracker", style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          // Date and prayers for selectedDate
          _buildDateHeader(selectedDate, textColor),
          SizedBox(height: 4),
          _buildPrayerList(selectedDate, widget.todayPrayerTimes, textColor, selectedCircleColor),
          SizedBox(height: 18),
          // Progress Calendar
          _buildProgressCalendar(
            calendarDates: calendarDates,
            selectedDate: selectedDate,
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
            },
            showWeek: showWeek,
            onWeekMonthToggle: (isWeek) {
              setState(() {
                showWeek = isWeek;
              });
            },
            onPrev: _goToPrev,
            onNext: _goToNext,
            calendarRefDate: calendarRefDate,
            selectedCircleColor: selectedCircleColor,
            outlinedCircleColor: outlinedCircleColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, Color textColor) {
    final hijriDate = ""; // If you want to add Islamic date, use a hijri package
    return Column(
      children: [
        Text(
          "Today, ${DateFormat('d MMMM').format(date)}",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        ),
        if (hijriDate.isNotEmpty)
          Text(hijriDate, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
      ],
    );
  }

  Widget _buildPrayerList(DateTime date, Map<String, DateTime> times, Color textColor, Color iconColor) {
    final status = _getStatusForDate(date);
    bool isToday = _dateString(date) == _dateString(DateTime.now());
    return Column(
      children: prayers.map((prayer) {
        final time = times[prayer];
        final timeStr = time != null ? DateFormat.jm().format(time) : '--';
        return Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(
                _prayerIcon(prayer),
                color: iconColor,
              ),
            ),
            title: Text(
              prayer,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(timeStr, style: TextStyle(color: textColor)),
                SizedBox(width: 12),
                Checkbox(
                  value: status[prayer] ?? false,
                  onChanged: canTickPrayer(time, date)
                      ? (val) {
                    final newStatus = {...status, prayer: val ?? false};
                    _saveStatusForDate(_dateString(date), newStatus);
                  }
                      : null,
                  activeColor: iconColor,
                  checkColor: Colors.white,
                  side: BorderSide(color: iconColor, width: 2),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _prayerIcon(String prayer) {
    switch (prayer) {
      case "Fajr":
        return Icons.wb_twighlight;
      case "Dhuhr":
        return Icons.wb_sunny;
      case "Asr":
        return Icons.sunny;
      case "Maghrib":
        return Icons.nightlight;
      case "Isha":
        return Icons.nightlight_round;
      default:
        return Icons.circle;
    }
  }

  Widget _buildProgressCalendar({
    required List<DateTime> calendarDates,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
    required bool showWeek,
    required Function(bool) onWeekMonthToggle,
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required DateTime calendarRefDate,
    required Color selectedCircleColor,
    required Color outlinedCircleColor,
    required Color textColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.only(bottom: 12, top: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _progressTab("Week", showWeek, () => onWeekMonthToggle(true)),
              SizedBox(width: 8),
              _progressTab("Month", !showWeek, () => onWeekMonthToggle(false)),
            ],
          ),
          SizedBox(height: 10),
          // Calendar arrows and label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                onPressed: onPrev,
              ),
              Text(
                showWeek
                    ? "${DateFormat('d MMM yyyy').format(calendarDates.first)} - ${DateFormat('d MMM yyyy').format(calendarDates.last)}"
                    : "${DateFormat('MMMM yyyy').format(calendarRefDate)}",
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                onPressed: onNext,
              ),
            ],
          ),
          SizedBox(height: 8),
          // Days row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              calendarDates.length >= 7 ? 7 : calendarDates.length,
                  (i) => Text(
                DateFormat('E').format(calendarDates[i]),
                style: TextStyle(color: textColor.withOpacity(0.7), fontWeight: FontWeight.w500),
              ),
            ),
          ),
          SizedBox(height: 6),
          // Date circles row(s)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: calendarDates.map((date) {
              final status = _getStatusForDate(date);
              final prayersDone = status.values.where((v) => v).length;
              final isSelected = _dateString(date) == _dateString(selectedDate);
              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: prayersDone == prayers.length
                        ? selectedCircleColor
                        : Colors.transparent,
                    border: Border.all(
                      color: prayersDone == prayers.length
                          ? selectedCircleColor
                          : outlinedCircleColor,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${date.day}",
                      style: TextStyle(
                        color: prayersDone == prayers.length
                            ? Colors.white
                            : outlinedCircleColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: isSelected ? 17 : 15,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 10),
          // Month label (bottom left)
          Row(
            children: [
              Icon(Icons.calendar_month, color: textColor, size: 18),
              SizedBox(width: 6),
              Text(
                showWeek
                    ? DateFormat('MMMM yyyy').format(calendarRefDate)
                    : DateFormat('MMMM yyyy').format(calendarRefDate),
                style: TextStyle(color: textColor.withOpacity(0.8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Color(0xFF00B2FF) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}