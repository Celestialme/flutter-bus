import 'package:android_bus2/components/BuildDrawer.dart';

import 'package:flutter/material.dart';
import 'package:android_bus2/main.dart' show db;

class Schedule extends StatefulWidget {
  @override
  _ScheduleState createState() => _ScheduleState();
}

var stopFocuse = new FocusNode();
var busFocuse = new FocusNode();

class _ScheduleState extends State<Schedule> {
  var stops = [];
  var searchstop;
  var searchbus;
  var currentstop;
  var scheme;
  List cols = [];
  var description = '';
  var days = {0: [], 1: []};
  var _controller = new TextEditingController();
  bool reject = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        drawer: new BuildDrawer(
          currentPage: 'Schedule',
          parent: this,
        ),
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(0, 31, 63, 1),
          centerTitle: true,
          title: Text(language == 'true' ? 'გრაფიკი' : 'Schedule'),
        ),
        body: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                busTextField(context),
                if (days[0].length > 0) dayButtons(),
                stopTextField(),
              ],
            ),
            bottomSection(),
          ],
        ));
  }

  Expanded bottomSection() {
    var thishour;
    var changeColor;
    return Expanded(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (stops.length == 0)
            Column(
              children: <Widget>[
                Container(
                    margin: EdgeInsets.only(top: 15.0, bottom: 35.0),
                    child: SingleChildScrollView(
                        child: Text(description),
                        scrollDirection: Axis.horizontal)),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: cols
                        .map<Widget>((value) => Expanded(
                              child: Column(
                                  children: value
                                      .map<Widget>((item) => item is Widget
                                          ? item
                                          : Container(
                                              width: 300,
                                              color: (() {
                                                if (thishour != false &&
                                                    item == value[0] &&
                                                    int.parse(item) >=
                                                        TimeOfDay.now().hour) {
                                                  thishour = int.parse(item);
                                                  changeColor = false;
                                                  return Colors.grey[300];
                                                } else if (thishour != null &&
                                                    thishour != false &&
                                                    (int.parse(item) +
                                                            thishour * 60) >=
                                                        (TimeOfDay.now()
                                                                .minute +
                                                            TimeOfDay.now()
                                                                    .hour *
                                                                60)) {
                                                  thishour = false;
                                                  changeColor = true;
                                                  return Color.fromRGBO(
                                                      0, 31, 63, 1);
                                                } else {
                                                  changeColor = false;
                                                  return Colors.grey[300];
                                                }
                                              })(),
                                              alignment: Alignment.center,
                                              child: Text(
                                                item,
                                                style: TextStyle(
                                                    color: changeColor == true
                                                        ? Colors.greenAccent
                                                        : Colors.black),
                                              ),
                                            ))
                                      .toList()),
                            ))
                        .toList())
              ],
            ),
          if (stops.length > 0)
            ListView.builder(
              itemCount: stops.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    currentstop = stops[index];

                    _controller.clear();

                    var tempscheme;
                    var hour;
                    var minutes;

                    db.rawQuery(
                        'SELECT arrival,description FROM schedule,description WHERE schedule.route == description.route AND schedule.forward=description.forward AND schedule.route=? AND stopid = ?  AND schedule.forward = ?',
                        [
                          searchbus,
                          stops[index]['sch_stopid'],
                          stops[index]['forward']
                        ]).then((data) => {
                          (() async {
                            if (data.length == 0) {
                              data = await db.rawQuery(
                                  'SELECT arrival FROM schedule WHERE route = ?  AND stopid = ?  AND schedule.forward = ?',
                                  [
                                    searchbus,
                                    stops[index]['sch_stopid'],
                                    stops[index]['forward']
                                  ]);
                            }
                            days[0] = await db.rawQuery(
                                'SELECT fromday,today FROM schedule WHERE route=? AND stopid = ?  AND forward = ?',
                                [
                                  searchbus,
                                  currentstop['sch_stopid'],
                                  currentstop['forward']
                                ]);
                            var temp = [];
                            for (var item in days[0]) {
                              item = [item['fromday'], item['today']];
                              if (item[0] != item[1]) {
                                language == 'true'
                                    ? temp.add(item
                                        .join(' - ')
                                        .replaceAll('MONDAY', 'ორშაბათი')
                                        .replaceAll('TUESDAY', 'სამშაბათი')
                                        .replaceAll('WEDNESDAY', 'ოთხშაბათი')
                                        .replaceAll('THURSDAY', 'ხუთშაბათი')
                                        .replaceAll('FRIDAY', 'პარასკევი')
                                        .replaceAll('SATURDAY', 'შაბათი')
                                        .replaceAll('SUNDAY', 'კვირა'))
                                    : temp.add(item.join(' - '));
                              } else {
                                language == 'true'
                                    ? temp.add(item[0]
                                        .replaceAll('MONDAY', 'ორშაბათი')
                                        .replaceAll('TUESDAY', 'სამშაბათი')
                                        .replaceAll('WEDNESDAY', 'ოთხშაბათი')
                                        .replaceAll('THURSDAY', 'ხუთშაბათი')
                                        .replaceAll('FRIDAY', 'პარასკევი')
                                        .replaceAll('SATURDAY', 'შაბათი')
                                        .replaceAll('SUNDAY', 'კვირა'))
                                    : temp.add(item[0]);
                              }
                            }
                            days[1] = temp;
                            description = data[0]['description'] != null
                                ? data[0]['description']
                                : '';
                            scheme = (data[0]['arrival'] as String).split(',');
                            tempscheme = {};
                            for (var time in scheme) {
                              hour = time.split(':')[0];
                              minutes = time.split(':')[1];
                              if (tempscheme[hour] != null) {
                                tempscheme[hour].add(minutes);
                              } else {
                                tempscheme[hour] = [minutes];
                              }
                            }
                            scheme = tempscheme;
                            cols = [];
                            scheme.forEach((k, v) => {
                                  v.insert(
                                      0,
                                      Divider(
                                        color: Colors.black,
                                        thickness: 2.0,
                                      )),
                                  v.insert(0, k),
                                  cols.add(v)
                                });

                            stops = [];
                            setState(() {});
                          })()
                        });
                  },
                  child: Container(
                    padding: EdgeInsets.only(bottom: 5.0, top: 5.0),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border(
                            bottom: BorderSide(
                                color: Theme.of(context).dividerColor))),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                            flex: 4,
                            child: Text(
                              language == 'true'
                                  ? stops[index]['name']
                                  : stops[index]['name_en'],
                              textAlign: TextAlign.center,
                            )),
                        Expanded(
                            flex: 1,
                            child: Text(
                                '#' + stops[index]['sch_stopid'].toString(),
                                textAlign: TextAlign.end))
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Expanded busTextField(context) {
    return Expanded(
      flex: 1,
      child: TextField(
        keyboardType: TextInputType.number,
        autofocus: true,
        focusNode: busFocuse,
        textInputAction: TextInputAction.send,
        onSubmitted: (notImportant) {
          FocusScope.of(context).requestFocus(stopFocuse);
        },
        style: TextStyle(color: reject == true ? Colors.red : Colors.black),
        onChanged: (value) {
          searchbus = value;
          days = {0: [], 1: []};
          db.rawQuery('SELECT route FROM schedule WHERE instr(route,?)',
              [searchbus]).then((data) {
            setState(() {
              if (data.length == 0) {
                reject = true;
              } else {
                reject = false;
              }
            });
          });
        },
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            hintText: 'Bus',
            hintStyle: TextStyle(color: Color.fromRGBO(0, 31, 63, 1))),
      ),
    );
  }

  Expanded dayButtons() {
    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: (() {
            List<Widget> buttons = [];
            days[0].asMap().forEach((index, value) => {
                  buttons.add(RaisedButton(
                    color: Colors.white,
                    child: Text(days[1][index]),
                    onPressed: () async {
                      var data = await db.rawQuery(
                          'SELECT arrival FROM schedule WHERE route=? AND stopid = ? AND fromday = ? AND today=? AND forward = ?',
                          [
                            searchbus,
                            currentstop['sch_stopid'],
                            days[0][index]['fromday'],
                            days[0][index]['today'],
                            currentstop['forward']
                          ]);

                      scheme = (data[0]['arrival'] as String).split(',');
                      var tempscheme = {};
                      for (var time in scheme) {
                        var hour = time.split(':')[0];
                        var minutes = time.split(':')[1];
                        if (tempscheme[hour] != null) {
                          tempscheme[hour].add(minutes);
                        } else {
                          tempscheme[hour] = [minutes];
                        }
                      }
                      scheme = tempscheme;
                      cols = [];
                      scheme.forEach((k, v) => {
                            v.insert(
                                0,
                                Divider(
                                  color: Colors.black,
                                  thickness: 2.0,
                                )),
                            v.insert(0, k),
                            cols.add(v)
                          });

                      setState(() {});
                    },
                  ))
                });
            return buttons;
          })(),
        ),
      ),
    );
  }

  Expanded stopTextField() {
    return Expanded(
      flex: 1,
      child: TextField(
        focusNode: stopFocuse,
        controller: _controller,
        onChanged: (value) {
          searchstop = value;
          if (searchstop == '') {
            stops = [];
            setState(() {});
            return;
          }
          db.rawQuery(
              'SELECT name,name_en, schedule.stopid as sch_stopid,forward FROM schedule,stops WHERE schedule.stopid=stops.stopid AND route =? AND instr(schedule.stopid, ? )>0 UNION SELECT name,name_en,schedule.stopid as sch_stopid,forward FROM schedule,stops WHERE schedule.stopid=stops.stopid AND route = ? AND (instr(name,?)>0 OR instr(lower(name_en),?)>0)',
              [
                this.searchbus,
                this.searchstop,
                this.searchbus,
                this.searchstop,
                this.searchstop.toLowerCase()
              ]).then((data) {
            stops = data;
            // print(stops);
            setState(() {});
          });
        },
        decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            hintText: 'Stop',
            hintStyle: TextStyle(color: Color.fromRGBO(0, 31, 63, 1))),
      ),
    );
  }
}
