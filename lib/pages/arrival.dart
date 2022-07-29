import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:android_bus2/main.dart';
import 'package:android_bus2/components/BuildDrawer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';

class Arrival extends StatefulWidget {
  final stopid;
  final name;
  final nameEn;

  const Arrival({
    Key key,
    this.stopid,
    this.name,
    this.nameEn,
  }) : super(key: key);

  @override
  _ArrivalState createState() => _ArrivalState();
}

class _ArrivalState extends State<Arrival> {
  List stops;
  bool favorite = false;
  var favorites = [];
  var timer;
  var activeAlarm;
  AudioPlayer audioPlayer = AudioPlayer();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  fetchPost() async {
    var response;
    try {
      response = language == 'true'
          ? await get(Uri.parse(
              'http://transfer.ttc.com.ge:8080/otp/routers/ttc/stopArrivalTimes?stopId=${widget.stopid}'))
          : await get(Uri.parse(
              'http://transferen.ttc.com.ge:18080/otp/routers/ttc/stopArrivalTimes?stopId=${widget.stopid}'));
    } catch (e) {
      response = language == 'true'
          ? await get(Uri.parse(
              'http://transfer.ttc.com.ge:18080/otp/routers/ttc/stopArrivalTimes?stopId=${widget.stopid}'))
          : await get(Uri.parse(
              'http://transfer.ttc.com.ge:8080/otp/routers/ttc/stopArrivalTimes?stopId=${widget.stopid}'));
    }

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      return json.decode(utf8.decode(response.bodyBytes))['ArrivalTime'];
    } else {
      // If that response was not OK, throw an error.
      return false;
    }
  }

  var notificationDetails;
  watchbus(int routeNumber, alarmTime) async {
    audioPlayer.setAsset('assets/blank.mp3');
    // audioPlayer.setUrl('http://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg');
    // audioPlayer.setLoopMode(LoopMode.one);
    audioPlayer.setVolume(0);
    audioPlayer.play();
    audioPlayer.setSpeed(0.00000000001);

    if (flutterLocalNotificationsPlugin == null) {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      var initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification'); // android settings
      var initializationSettingsIOS = IOSInitializationSettings(
          onDidReceiveLocalNotification:
              (data, bla, bly, blu) async {}); // ios settings

      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS); // apply settings
      flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (String payload) async {});
      var vibrationpattern = Int64List(4);
      vibrationpattern[0] = 0;
      vibrationpattern[1] = 1000;
      vibrationpattern[2] = 800;
      vibrationpattern[3] = 1000;
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'your channel id', 'your channel name',
          color: Color.fromRGBO(0, 31, 63, 1),
          enableVibration: true,
          vibrationPattern: vibrationpattern,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      notificationDetails = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
    }
    if (timer != null) {
      timer.cancel();
    }
    timer = Timer.periodic(Duration(seconds: 30), (data) {
      setState(() {});
      fetchPost().then((response) {
        stops = response;
        Future.delayed(Duration(seconds: 1), () {
          var route = stops.singleWhere(
              (element) => int.tryParse(element['RouteNumber']) == routeNumber);
          print("$routeNumber ${route['ArrivalTime']}");
          if (route['ArrivalTime'] <= alarmTime) {
            flutterLocalNotificationsPlugin.show(
                0,
                language == 'true'
                    ? "მარშრუტი: #${route['RouteNumber']}"
                    : "Route: #${route['RouteNumber']}",
                language == 'true'
                    ? "დრო: ${route['ArrivalTime']} წთ"
                    : "Time: ${route['ArrivalTime']} min",
                notificationDetails);
          }
        });
      });
    });
  }

  void initState() {
    (() async {
      favorites = await db.rawQuery(
          'SELECT stopid FROM favorites where stopid=?', [widget.stopid]);
      if (favorites.length > 0) {
        favorite = true;
      }
      setState(() {});
    })();

    super.initState();
  }

  @override
  void dispose() {
    if (timer != null) {
      timer.cancel();
    }
    // print('disposed');
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
          backgroundColor: Colors.grey[300],
          appBar: new BuildAppBar(
            name: widget.name,
            nameEn: widget.nameEn,
            stopid: widget.stopid,
            favorite: favorite,
            db: db,
          ),
          body: GestureDetector(
            onTap: () {
              setState(() {});
            },
            child: FutureBuilder(
                future: fetchPost(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    stops = snapshot.data;
                    // print(snapshot.data);
                    return ListView(
                        children: snapshot.data
                            .map<Widget>((stop) => Column(
                                  children: <Widget>[
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(' ' +
                                              stop['RouteNumber'].toString()),
                                          Text(stop['DestinationStopName']),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              GestureDetector(
                                                child: Icon(Icons.alarm,
                                                    color: activeAlarm ==
                                                            stop['RouteNumber']
                                                        ? Colors.greenAccent
                                                        : Colors.black),
                                                onTap: () => buildAlertDialog(
                                                    context, (alarmTime) {
                                                  setState(() {
                                                    activeAlarm =
                                                        stop['RouteNumber'];
                                                  });
                                                  watchbus(
                                                      int.parse(
                                                          stop['RouteNumber']),
                                                      alarmTime);
                                                }),
                                              ),
                                              Container(
                                                  width: 25,
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                      stop['ArrivalTime']
                                                              .toString() +
                                                          ' '))
                                            ],
                                          )
                                        ]),
                                    Divider(
                                      color: Colors.white,
                                    )
                                  ],
                                ))
                            .toList());
                  }

                  return Center(child: CircularProgressIndicator());
                }),
          )),
    );
  }
}

class BuildAppBar extends StatefulWidget implements PreferredSizeWidget {
  final name;
  final nameEn;
  final stopid;
  final favorite;
  final db;
  BuildAppBar(
      {Key key, this.name, this.nameEn, this.stopid, this.favorite, this.db})
      : super(key: key ?? ValueKey(favorite));

  @override
  _BuildAppBarState createState() => _BuildAppBarState(favorite: this.favorite);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _BuildAppBarState extends State<BuildAppBar> {
  var favorite;

  _BuildAppBarState({this.favorite});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Color.fromRGBO(0, 31, 63, 1),
      title: Text(language == 'true' ? widget.name : widget.nameEn),
      actions: <Widget>[
        IconButton(
          icon: favorite
              ? Icon(
                  Icons.star,
                  color: Colors.greenAccent,
                  size: 40,
                )
              : Icon(Icons.star_border, size: 40),
          onPressed: () {
            setState(() {
              favorite = !favorite;
              if (favorite == true) {
                widget.db.execute('INSERT INTO favorites VALUES (?,?,?)',
                    [widget.stopid, widget.name, widget.nameEn]);
                db
                    .rawQuery('SELECT * FROM favorites')
                    .then((data) => {favorites.value = data});
              } else {
                widget.db.execute(
                    'DELETE FROM favorites WHERE stopid=?', [widget.stopid]);
                db
                    .rawQuery('SELECT * FROM favorites')
                    .then((data) => {favorites.value = data});
              }
            });
          },
        )
      ],
    );
  }
}

buildAlertDialog(BuildContext context, callback) {
  TextEditingController dialogController = new TextEditingController();
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Color.fromRGBO(0, 31, 63, 0.9),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                language == 'true' ? 'დრო: ' : 'time: ',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Icon(
              Icons.alarm,
              color: Colors.white,
            )
          ],
        ),
        content: TextField(
          style: TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          autofocus: true,
          controller: dialogController,
          onSubmitted: (smth) {
            callback(int.parse(dialogController.text));
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          RaisedButton(
            onPressed: () {
              callback(int.parse(dialogController.text));
              Navigator.pop(context);
            },
            child: Text('submit'),
          )
        ],
      );
    },
  );
}
