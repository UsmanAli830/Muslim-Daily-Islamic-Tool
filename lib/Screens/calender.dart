import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../Services/timezone.dart'; // Adjust path if needed

class IslamicEventType {
  final String name;
  final int hMonth;
  final int hDay;
  IslamicEventType({required this.name, required this.hMonth, required this.hDay});
}

final List<IslamicEventType> islamicEventTypes = [
  IslamicEventType(name: "Ashura", hMonth: 1, hDay: 10),
  IslamicEventType(name: "Ramadhan Start", hMonth: 9, hDay: 1),
  IslamicEventType(name: "Eid ul Fitr", hMonth: 10, hDay: 1),
  IslamicEventType(name: "Eid ul Azha", hMonth: 12, hDay: 10),
  IslamicEventType(name: "Islamic New Year", hMonth: 1, hDay: 1),
  IslamicEventType(name: "Hajj", hMonth: 12, hDay: 9),
];

class HijriCalendarPage extends StatefulWidget {
  @override
  _HijriCalendarPageState createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  HijriCalendar? _selectedHijri;
  IslamicEventType? _selectedEventType;

  @override
  void initState() {
    super.initState();
    final localTime = TimeZoneService.getLocalDateTime();
    _focusedDay = localTime;
    _selectedDay = localTime;
    _selectedHijri = getAdjustedHijriFromDate(localTime);
    _selectedEventType = getEventTypeForHijri(_selectedHijri!);
  }

  HijriCalendar getAdjustedHijriFromDate(DateTime date) {
    HijriCalendar hijri = HijriCalendar.fromDate(date);
    if (TimeZoneService.shouldAdjustHijriDate()) {
      if (hijri.hDay == 1) {
        hijri.hMonth -= 1;
        if (hijri.hMonth < 1) {
          hijri.hMonth = 12;
          hijri.hYear -= 1;
        }
        hijri.hDay = hijri.getDaysInMonth(hijri.hYear, hijri.hMonth);
      } else {
        hijri.hDay -= 1;
      }
    }
    return hijri;
  }

  IslamicEventType? getEventTypeForHijri(HijriCalendar hijri) {
    try {
      return islamicEventTypes.firstWhere(
            (eventType) =>
        eventType.hMonth == hijri.hMonth &&
            eventType.hDay == hijri.hDay,
      );
    } catch (e) {
      return null;
    }
  }

  String getFormattedGregorian(DateTime date) =>
      DateFormat('dd MMMM yyyy').format(date);

  String getFormattedHijri(HijriCalendar hijri) =>
      '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear}';

  String getDayName(DateTime date) => DateFormat('EEEE').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hijri Calendar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      // Use a SingleChildScrollView for proper layout
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              if (_selectedHijri != null && _selectedDay != null)
                Column(
                  children: [
                    Text(
                      'Islamic: ${getFormattedHijri(_selectedHijri!)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      getFormattedGregorian(_selectedDay!),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              SizedBox(height: 8),
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.saturday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) {
                    final hijri = getAdjustedHijriFromDate(date);
                    return '${hijri.getLongMonthName()} ${hijri.hYear}';
                  },
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final hijri = getAdjustedHijriFromDate(day);
                    final eventType = getEventTypeForHijri(hijri);
                    return Center(
                      child: Container(
                        width: 36, // Fixed size for all numbers
                        height: 36,
                        decoration: eventType != null
                            ? BoxDecoration(
                          color: Colors.green[300],
                          shape: BoxShape.circle,
                        )
                            : null,
                        alignment: Alignment.center,
                        child: Text(
                          hijri.hDay.toString(),
                          style: TextStyle(
                            color: eventType != null ? Colors.white : Colors.black,
                            fontWeight: eventType != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final hijri = getAdjustedHijriFromDate(day);
                    final eventType = getEventTypeForHijri(hijri);
                    return Center(
                      child: Container(
                        width: 36, // Same fixed size!
                        height: 36,
                        margin: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: eventType != null ? Colors.green : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          hijri.hDay.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final hijri = getAdjustedHijriFromDate(day);
                    final eventType = getEventTypeForHijri(hijri);
                    return Container(
                      margin: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        color: eventType != null ? Colors.green[300] : null,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hijri.hDay.toString(),
                        style: TextStyle(
                          color: eventType != null ? Colors.white : Colors.blue,
                          fontWeight: eventType != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  final selectedHijri = getAdjustedHijriFromDate(selectedDay);
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedHijri = selectedHijri;
                    _selectedEventType = getEventTypeForHijri(selectedHijri);
                  });
                },
              ),
              // ↓↓↓ No Expanded or Spacer here, so event card appears just below calendar!
              if (_selectedEventType != null && _selectedHijri != null && _selectedDay != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // less vertical gap!
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          "Event: ${_selectedEventType!.name}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          "Islamic Date: ${getFormattedHijri(_selectedHijri!)}",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "Gregorian Date: ${getFormattedGregorian(_selectedDay!)}",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "Day: ${getDayName(_selectedDay!)}",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}