import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:work_mate/main.dart';
import 'package:table_calendar/table_calendar.dart';

class ManageCalendar extends StatefulWidget {
  @override
  _ManageCalendarState createState() => _ManageCalendarState();
}

class _ManageCalendarState extends State<ManageCalendar> {
  FirebaseAuth auth = FirebaseAuth.instance;
  CalendarController _controller;
  Map<DateTime, List<dynamic>> _events;
  TextEditingController _eventController;
  List<dynamic> _selectedEvents;
  List<dynamic> _dbEvents;
  bool flg;

  _showAddDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Add Event',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            content: TextField(
              cursorColor: Colors.black,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter Work',
              ),
              controller: _eventController,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Save',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () async {
                  if (_eventController.text.isEmpty) return;
                  String subname;
                  await FirebaseDatabase.instance
                      .reference()
                      .child('class/${cd.curclass}/subject/${cd.cursub}/')
                      .once()
                      .then((DataSnapshot snap) {
                    Map<dynamic, dynamic> values = snap.value;
                    subname = values['subname'];
                    print(subname);
                    subname += ' - ';
                  });

                  String dbdate =
                      _controller.selectedDay.toString().replaceAll('.', ',');
                  await FirebaseDatabase.instance
                      .reference()
                      .child('class/${cd.curclass}/date')
                      .once()
                      .then((DataSnapshot snap) async {
                    if (snap.value == null) {
                      List<dynamic> newevent = [];
                      newevent.add(subname + _eventController.text);
                      await FirebaseDatabase.instance
                          .reference()
                          .child('class/${cd.curclass}/date')
                          .set({dbdate: newevent});
                    } else {
                      Map<dynamic, dynamic> values = snap.value;
                      var oldevent;
                      if (values[dbdate] == null) {
                        oldevent = new List<dynamic>();
                      } else {
                        oldevent = new List<dynamic>.from(values[dbdate]);
                      }
                      oldevent.add(subname + _eventController.text);
                      values[dbdate] = oldevent;
                      await FirebaseDatabase.instance
                          .reference()
                          .child('class/${cd.curclass}')
                          .update({'date': values});
                    }
                  });
                  setState(() {
                    if (_eventController.text.isEmpty) return;
                    if (_events[_controller.selectedDay] != null) {
                      var temp = new List<dynamic>.from(
                          _events[_controller.selectedDay]);
                      temp.add(subname + _eventController.text);
                      _events[_controller.selectedDay] = temp;
                    } else {
                      _events[_controller.selectedDay] = [
                        subname + _eventController.text
                      ];
                    }
                    _eventController.clear();
                    _selectedEvents = _events[_controller.selectedDay];
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _controller = CalendarController();
    _events = {};
    _eventController = TextEditingController();
    _selectedEvents = [];
    _dbEvents = [];
    flg = false;
  }

  Future<Map<DateTime, List<dynamic>>> initGetEvents() async {
    final dbref = FirebaseDatabase.instance.reference();
    Map<DateTime, List<dynamic>> newvalues = {};
    Map<DateTime, List<dynamic>> evt;
    await dbref
        .child('class/${cd.curclass}/date')
        .once()
        .then((DataSnapshot snap) {
      if (snap.value == null) {
        _events = {};
        return _events;
      }
      Map<dynamic, dynamic> values = snap.value;
      for (var x in values.entries) {
        DateTime convDate =
            DateTime.parse(x.key.toString().replaceAll(',', '.'));
        newvalues[convDate];
        List<dynamic> temp = [];
        List<dynamic> temp2 = [];
        temp.add(x.value);
        int i = 0;
        while (i < temp.length) {
          newvalues[convDate] = temp[i];
          i++;
        }
        //DataSnapshot s = val;
        // Map<dynamic, dynamic> v = s.value;
        // v.forEach((key, value) {
        //   newvalues[convDate].add(value);
        // });
        //print(temp2);
      }
    });
    //print(newvalues);
    _events = newvalues;
    return _events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: () async {
                await auth.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/landingpage', (Route<dynamic> route) => false);
              },
              child: Text(
                "Sign Out",
                //style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        title: Text("Manange Calendar"),
      ),
      body: FutureBuilder(
          future: initGetEvents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: Text('Loading Calendar...'),
              );
            }
            if (snapshot.hasData) {
              if (flg == false) {
                String y = DateTime.now().toString();
                String k = '';
                for (int i = 0; i < y.length; i++) {
                  if (y[i] != ' ') {
                    k += y[i];
                  } else {
                    y = k + ' ';
                    break;
                  }
                }
                y += '12:00:00.000Z';
                DateTime x = DateTime.parse(y);
                _selectedEvents = _events[x] ?? [];
                flg = true;
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TableCalendar(
                      events: _events,
                      calendarStyle: CalendarStyle(
                        todayColor: Colors.grey.shade800,
                        selectedColor: Color(0xFFB00020),
                      ),
                      initialCalendarFormat: CalendarFormat.month,
                      headerStyle: HeaderStyle(formatButtonShowsNext: false),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      onDaySelected: (date, events, _) {
                        setState(() {
                          _selectedEvents = events;
                        });
                      },
                      calendarController: _controller,
                      builders: CalendarBuilders(),
                    ),
                    Text(
                      'Events for the day : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    (_selectedEvents.isEmpty)
                        ? Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Text('No assigned works for this day !! 😄'))
                        : ListView(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            children: [
                              ..._selectedEvents.map((event) {
                                String full = event.toString();
                                String sub = 'Subject - ';
                                String cont = '';
                                bool f = false;
                                for (int i = 0; i < full.length; i++) {
                                  if (full[i] == ' ' &&
                                      full[i + 1] == '-' &&
                                      full[i + 2] == ' ') {
                                    i += 3;
                                    f = true;
                                  }
                                  if (f == false) {
                                    sub += full[i];
                                  } else {
                                    cont += full[i];
                                  }
                                }
                                return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 5.0,
                                        right: 5.0,
                                        top: 3.0,
                                        bottom: 3.0),
                                    child: Card(
                                      color: Colors.grey.shade900,
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.calendar_today_rounded,
                                          color: Colors.white,
                                        ),
                                        title: Text(
                                          sub,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          cont,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                      ),
                                    ));
                              }),
                            ],
                          ),
                  ],
                ),
              );
            }
            return Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddDialog,
      ),
    );
  }
}
