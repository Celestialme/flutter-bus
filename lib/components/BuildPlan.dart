import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'BuildDrawer.dart';
import 'package:android_bus2/pages/map.dart';

var page = 1;
var planData;
var active;
var stops = [];
var tostops = [];
// TextEditingController  _toController = new TextEditingController();
// TextEditingController  _fromController = new TextEditingController();
List<Item> items;

class BuildPlan extends StatefulWidget {
  final latlon;
  final Function notifyParent;
  final toController;
  final fromController;
  const BuildPlan(
      {Key key,
      this.latlon,
      this.notifyParent,
      this.toController,
      this.fromController})
      : super(key: key);

  @override
  _BuildPlanState createState() => _BuildPlanState(
      latlon: this.latlon,
      toController: this.toController,
      fromController: this.fromController);
}

FocusNode toControllerFocus = new FocusNode();

class _BuildPlanState extends State<BuildPlan> {
  var typedropdownValue = 'ავტობუსით და მეტროთი';
  var feetdropdownValue = '1000 მეტრი';
  var latlon;
  var fromController;
  var toController;
  _BuildPlanState({this.latlon, this.fromController, this.toController});

  @override
  void initState() {
    super.initState();
    FocusScope.of(mapContext).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return page == 1 ? drawerFirstPage() : drawerSecondtPage();
  }

  Drawer drawerFirstPage() {
    if (latlon['From'].length > 0) {
      fromController.text = latlon['From'];
    }
    if (latlon['To'].length > 0) {
      toController.text = latlon['To'];
    }
    return Drawer(
        child: SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DrawerHeader(
                  decoration:
                      BoxDecoration(color: Color.fromRGBO(0, 31, 63, 1)),
                  child: Icon(
                    Icons.directions_bus,
                    size: 50.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Icon(Icons.location_on),
                          Expanded(
                              child: TextField(
                            controller: fromController,
                            decoration: InputDecoration(
                                hintText:
                                    language == 'true' ? 'აქედან' : 'From'),
                            onChanged: (value) async {
                              stops = await db.rawQuery(
                                  'SELECT stopid,name,name_en,lat,lon FROM stops WHERE instr(stopid,?)>0 OR instr(name,?)>0  OR instr(name_en,?)>0 ',
                                  [value, value, value]);
                              if (value == '') {
                                stops = [];
                              }
                              // _controller.jumpTo(_controller.position.minScrollExtent);
                              setState(() {});
                            },
                          )),
                          GestureDetector(
                              onTap: () {
                                widget.notifyParent('delFromMarker');
                                fromController.text = '';
                                stops = [];
                              },
                              child: Icon(Icons.clear)),
                        ],
                      ),
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4),
                          child: MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: ListView.builder(
                              physics: ClampingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: stops.length,
                              itemBuilder: (BuildContext context, index) {
                                return new Column(
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        fromController.text =
                                            '${stops[index]['lat']},${stops[index]['lon']}';
                                        FocusScope.of(context)
                                            .requestFocus(toControllerFocus);
                                        print(toControllerFocus);
                                        widget.notifyParent({
                                          'position': LatLng(
                                              stops[index]['lat'],
                                              stops[index]['lon']),
                                          'direction': 'From'
                                        });
                                        stops = [];
                                        setState(() {});
                                      },
                                      child: Row(children: [
                                        Expanded(
                                            flex: 1,
                                            child: Text(' ' +
                                                stops[index]['stopid']
                                                    .toString())),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            language == 'true'
                                                ? stops[index]['name']
                                                : stops[index]['name_en'],
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      ]),
                                    ),
                                    Divider(
                                      color: Colors.black,
                                    )
                                  ],
                                );
                              },
                            ),
                          ))
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Icon(Icons.keyboard_tab),
                          Expanded(
                              child: TextField(
                            controller: toController,
                            focusNode: toControllerFocus,
                            decoration: InputDecoration(
                                hintText: language == 'true' ? 'აქეთ' : 'To'),
                            onChanged: (value) async {
                              tostops = await db.rawQuery(
                                  'SELECT stopid,name,name_en,lat,lon FROM stops WHERE instr(stopid,?)>0 OR instr(name,?)>0  OR instr(name_en,?)>0 ',
                                  [value, value, value]);
                              if (value == '') {
                                tostops = [];
                              }
                              // _controller.jumpTo(_controller.position.minScrollExtent);
                              setState(() {});
                            },
                          )),
                          GestureDetector(
                              onTap: () {
                                widget.notifyParent('delToMarker');
                                toController.text = '';
                              },
                              child: Icon(Icons.clear)),
                        ],
                      ),
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4),
                          child: MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: ListView.builder(
                              physics: ClampingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: tostops.length,
                              itemBuilder: (BuildContext context, index) {
                                return new Column(
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () {
                                        // print(tostops[index]['stopid']);
                                        toController.text =
                                            '${tostops[index]['lat']},${tostops[index]['lon']}';
                                        FocusScope.of(context).unfocus();
                                        widget.notifyParent({
                                          'position': LatLng(
                                              tostops[index]['lat'],
                                              tostops[index]['lon']),
                                          'direction': 'To'
                                        });
                                        tostops = [];
                                        setState(() {});
                                      },
                                      child: Row(children: [
                                        Expanded(
                                            flex: 1,
                                            child: Text(' ' +
                                                tostops[index]['stopid']
                                                    .toString())),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            language == 'true'
                                                ? tostops[index]['name']
                                                : tostops[index]['name_en'],
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      ]),
                                    ),
                                    Divider(
                                      color: Colors.black,
                                    )
                                  ],
                                );
                              },
                            ),
                          ))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(Icons.directions_transit),
                      Expanded(
                        child: DropdownButton(
                            value: typedropdownValue,
                            iconSize: 24,
                            items: <String>[
                              'ავტობუსით და მეტროთი',
                              'მხოლოდ ავტობუსით',
                              'მხოლოდ მეტროთი'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(language == 'true'
                                      ? value
                                      : value
                                          .replaceAll('ავტობუსით და მეტროთი',
                                              'Bus and SubWay')
                                          .replaceAll(
                                              'მხოლოდ ავტობუსით', 'Only Bus')
                                          .replaceAll('მხოლოდ მეტროთი',
                                              'Only SubWay')));
                            }).toList(),
                            onChanged: (String newValue) {
                              setState(() {
                                typedropdownValue = newValue;
                              });
                            }),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(Icons.transfer_within_a_station),
                      Expanded(
                        child: DropdownButton(
                            value: feetdropdownValue,
                            iconSize: 24,
                            items: <String>[
                              "100 მეტრი",
                              "200 მეტრი",
                              "300 მეტრი",
                              "400 მეტრი",
                              "500 მეტრი",
                              "750 მეტრი",
                              "1000 მეტრი",
                              "1500 მეტრი",
                              "2000 მეტრი",
                              "2500 მეტრი",
                              "5000 მეტრი",
                              "7500 მეტრი",
                              "10000 მეტრი"
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(language == 'true'
                                    ? value
                                    : value.replaceAll('მეტრი', 'Meter')),
                              );
                            }).toList(),
                            onChanged: (String newValue) {
                              setState(() {
                                feetdropdownValue = newValue;
                              });
                            }),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded(child:Container())
          // ,
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Color.fromRGBO(0, 31, 63, 1)),
                  onPressed: () async {
                    RegExp re = RegExp(r'(\d+)-(\d+)-(\d+)');
                    var match =
                        re.allMatches(DateTime.now().toString()).elementAt(0);

                    var fromplace = latlon['From'];
                    var toplace = latlon['To'];
                    var time =
                        TimeOfDay.now().format(context).replaceAll(' ', '');
                    var date =
                        '${match.group(2)}-${match.group(3)}-${match.group(1)}';
                    var mode = typedropdownValue == 'მხოლოდ ავტობუსით'
                        ? 'BUS,WALK'
                        : typedropdownValue == 'მხოლოდ მეტროთი'
                            ? 'TRAM,RAIL,SUBWAY,FUNICULAR,GONDOLA,WALK'
                            : 'TRANSIT,WALK';
                    var maxwalkingdistance =
                        new RegExp(r'\d+').stringMatch(feetdropdownValue);
                    planData = await fetchPost(
                        'http://transferen.ttc.com.ge:8080/otp/routers/ttc/plan?fromPlace=$fromplace&toPlace=$toplace&time=$time&date=$date&mode=$mode&maxWalkDistance=$maxwalkingdistance&arriveBy=false&wheelchair=false&locale=ka');
                    items = planData['itineraries'].map<Item>((item) {
                      return Item(
                        headerValue: [item['legs'], item['duration']],
                        expandedValue: item['legs'],
                        isExpanded: false,
                      );
                    }).toList();
                    setState(() {
                      page = 2;
                    });
                  },
                  child: Text(
                    language == 'true' ? 'დაგეგმვა' : 'Plan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    ));
  }

  Drawer drawerSecondtPage() {
    return Drawer(
        child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DrawerHeader(
                        decoration:
                            BoxDecoration(color: Color.fromRGBO(0, 31, 63, 1)),
                        child: Icon(
                          Icons.directions_bus,
                          size: 50.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: ExpansionPanelList(
                        expansionCallback: (int index, bool isExpanded) {
                          for (var item in items) {
                            item.isExpanded = false;
                          } // close all when opening one; already planned
                          setState(() {
                            active = null;
                            widget.notifyParent(items[index].expandedValue);
                            items[index].isExpanded = !isExpanded;
                          });
                        },
                        children: items.map<ExpansionPanel>((Item item) {
                          return ExpansionPanel(
                            headerBuilder:
                                (BuildContext context, bool isExpanded) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.all(0),
                                title: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: <Widget>[
                                      Text((item.headerValue[1] / 60)
                                          .round()
                                          .toString()),
                                      Icon(Icons.timer),
                                      Text('   '),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: item.headerValue[0]
                                            .map<Widget>((itm) {
                                          return itm['mode'] == 'WALK'
                                              ? Icon(Icons.directions_walk)
                                              : itm['mode'] == 'BUS'
                                                  ? Row(
                                                      children: <Widget>[
                                                        Text(
                                                            '№' + itm['route']),
                                                        Icon(Icons
                                                            .directions_bus)
                                                      ],
                                                    )
                                                  : Icon(
                                                      Icons.directions_subway);
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            body: Container(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                itemCount: item.expandedValue.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return GestureDetector(
                                    onTap: () {
                                      widget.notifyParent(index);
                                      active = index;
                                    },
                                    child: SingleChildScrollView(
                                      padding:
                                          EdgeInsets.only(top: 5, bottom: 5),
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        color: active == index
                                            ? Colors.green
                                            : Colors.white,
                                        child: Row(
                                          children: <Widget>[
                                            item.expandedValue[index]['mode'] ==
                                                    'WALK'
                                                ? Icon(Icons.directions_walk)
                                                : item.expandedValue[index]
                                                            ['mode'] ==
                                                        'BUS'
                                                    ? Icon(Icons.directions_bus)
                                                    : Icon(Icons
                                                        .directions_subway),
                                            item.expandedValue[index]['mode'] ==
                                                    'BUS'
                                                ? Text('№' +
                                                    item.expandedValue[index]
                                                        ['route'] +
                                                    ' ')
                                                : Container(),
                                            item.expandedValue[index]['mode'] ==
                                                    'WALK'
                                                ? Text(
                                                    'გაიარე ${item.expandedValue[index]['distance'].round()}მ')
                                                : Container(),
                                            Text(
                                                '${item.expandedValue[index]['from']['name'] != 'Origin' ? item.expandedValue[index]['from']['name'] : ''} - ${item.expandedValue[index]['to']['name'] != 'Destination' ? item.expandedValue[index]['to']['name'] : 'დანიშნულების ადგილი'} ')
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            isExpanded: item.isExpanded,
                          );
                        }).toList(),
                      )),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        color: Color.fromRGBO(0, 31, 63, 1),
                        onPressed: () {
                          setState(() {
                            page = 1;
                          });
                        },
                        child: Text(language == 'true' ? 'უკან' : 'Back',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            )));
  }
}

fetchPost(url) async {
  dynamic response = await get(Uri.parse(url));

  if (response.statusCode == 200) {
    // If server returns an OK response, parse the JSON.
    return json.decode(utf8.decode(response.bodyBytes))['plan'];
  } else {
    // If that response was not OK, throw an error.
    throw Exception('Failed to load post');
  }
}

class Item {
  Item({
    this.expandedValue,
    this.headerValue,
    this.isExpanded = false,
  });

  dynamic expandedValue;
  dynamic headerValue;
  bool isExpanded;
}
