import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:android_bus2/main.dart' as main show db;
import 'package:android_bus2/components/BuildPlan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
import 'dart:ui' as ui;
// import 'package:sqflite/sqflite.dart';
import 'arrival.dart';
import 'package:android_bus2/components/BuildDrawer.dart' show language;

BuildContext mapContext;
var _fromController = new TextEditingController();
var _toController = new TextEditingController();
var controller = new TextEditingController();
var favorites = ValueNotifier([]);
var db = main.db;
Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
      .buffer
      .asUint8List();
}

class Gmap extends StatefulWidget {
  final markerloc; // from search section map click
  const Gmap({Key key, this.markerloc}) : super(key: key);

  @override
  _GmapState createState() => _GmapState();
}

class _GmapState extends State<Gmap> with WidgetsBindingObserver {
  GoogleMapController _mapcontroller;
  List markers = [];
  List polylines = [];
  List planPolylines = [];
  List planMarkerIcons = [];
  List stopMarkers = [];
  List busMarkers = [];
  String oldbus;
  bool destroy = false;
  var oldKey = 0.0;
  var zoom = 15.0;
  Map planmarkers = {'From': '', 'To': ''};
  CameraPosition cameraposition =
      CameraPosition(target: LatLng(41.7967686, 44.7953876), zoom: 15.0);
  var StopIconData = (() async {
    return BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/stopIcon.png', 75));
  })();
  var BusIconData = (() async {
    return BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/busIcon.png', 75));
  })();
  var BusIconData2 = (() async {
    return BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/busIcon2.png', 135));
  })();
  var TrainIconData = (() async {
    return BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/trainIcon.png', 135));
  })();
  var WalkIconData = (() async {
    return BitmapDescriptor.fromBytes(
        await getBytesFromAsset('assets/walkIcon.png', 135));
  })();

  @override
  void initState() {
    // (() async {
    //   var dbDir = await getDatabasesPath();
    //   var dbPath = join(dbDir, "db.db");
    //   db = await openDatabase(dbPath);
    // })();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appstate) {
    if (appstate == AppLifecycleState.resumed) {
      destroy = true;
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    mapContext = context;
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
    refresh(task) async {
      if (task == 'delFromMarker') {
        planmarkers['From'] = '';
        markers.removeWhere((mark) {
          return mark.markerId.value == 'From';
        });
      } else if (task == 'delToMarker') {
        planmarkers['To'] = '';
        markers.removeWhere((mark) {
          return mark.markerId.value == 'To';
        });
      } else if (task is List) {
        // print(PolylinePoints().decodePolyline(task[0]['legGeometry']['points'])[0].latitude);
        for (var polyline in planPolylines) {
          polylines.remove(polyline);
        }
        for (var planMarkerIcon in planMarkerIcons) {
          markers.remove(planMarkerIcon);
        }
        planMarkerIcons = [];
        planPolylines = [];
        List boundpoints = [];
        for (var item in task) {
          // print(item['mode']);
          var iconData = item['mode'] == 'WALK'
              ? WalkIconData
              : item['mode'] == 'BUS'
                  ? BusIconData2
                  : TrainIconData;
          List<LatLng> coordinates = [];
          var result =
              PolylinePoints().decodePolyline(item['legGeometry']['points']);
          for (var point in result) {
            coordinates.add(LatLng(point.latitude, point.longitude));
            boundpoints.add([point.longitude, point.latitude]);
          }
          boundpoints.sort((a, b) => a[1].compareTo(b[
              1])); // create bounds of plan polyline, find path after chosing from left big panel

          var MaxNorth = boundpoints[boundpoints.length - 1][1];
          var MaxSouth = boundpoints[0][1];

          boundpoints.sort((a, b) => a[0].compareTo(b[0]));

          var MaxWest = boundpoints[0][0];
          var MaxEast = boundpoints[boundpoints.length - 1][0];

          LatLngBounds bound = LatLngBounds(
              southwest: LatLng(MaxSouth, MaxWest),
              northeast: LatLng(MaxNorth, MaxEast));
          _mapcontroller.animateCamera(CameraUpdate.newLatLngBounds(bound, 60));

          var polyline = Polyline(
            polylineId: PolylineId(Random().nextInt(1000).toString() + 'plan'),
            color: Colors.green,
            jointType: JointType.round,
            points: coordinates,
            width: 5,
          );

          planPolylines.add(polyline);
          var marker = Marker(
              markerId: MarkerId(Random().nextInt(1000).toString() + 'plan'),
              icon: await iconData,
              position: coordinates[0]);
          planMarkerIcons.add(marker);
        }
        for (var polyline in planPolylines) {
          polylines.add(polyline);
        }
        for (var iconmarker in planMarkerIcons) {
          markers.add(iconmarker);
        }
      } else if (task is int) {
        polylines.removeWhere((swap) {
          return swap == planPolylines[task];
        });
        for (var line in planPolylines) {
          // print(line.color.value);

          if (line.color.value == 4286259106) {
            // print(line.color.value);
            polylines.remove(line);
          }
        }
        polylines.add(planPolylines[planPolylines.length - 1]
            .copyWith(colorParam: Colors.green));

        polylines
            .add(planPolylines[task].copyWith(colorParam: Colors.purple[700]));
        planPolylines.removeWhere((test) {
          return test.color.value == 4294967040;
        });
        planPolylines
            .add(planPolylines[task].copyWith(colorParam: Colors.purple[700]));
      } else if (task is Map) {
        if (task['direction'] == 'From') {
          planmarkers['From'] =
              '${task['position'].latitude},${task['position'].longitude}';
        } else {
          planmarkers['To'] =
              '${task['position'].latitude},${task['position'].longitude}';
        }
        markers.add(Marker(
            markerId: MarkerId(task['direction']),
            position: task['position'],
            consumeTapEvents: true,
            onTap: () {
              _mapcontroller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: task['position'], zoom: zoom)));
              _mapcontroller.showMarkerInfoWindow(MarkerId(task['direction']));
            },
            infoWindow: InfoWindow(
                title: 'X',
                snippet: task['direction'] == 'To' ? 'დასასრული' : 'დასაწყისი',
                onTap: () {
                  markers.removeWhere((mark) {
                    return mark.markerId.value == task['direction'];
                  });
                  setState(() {
                    if (task['direction'] == 'To') {
                      planmarkers['To'] = '';
                      _toController.text = '';
                    } else {
                      planmarkers['From'] = '';
                      _fromController.text = '';
                    }
                  });
                })));
      }
      setState(() {});
    }

    // print('refreshed');

    return MaterialApp(
        // key: ValueKey((() {
        //   if (destroy == true) {
        //     destroy = false;
        //     oldKey = new Random().nextDouble();
        //     return oldKey;
        //   } else {
        //     return oldKey;
        //   }
        // })()),
        title: 'Welcome to Flutter',
        routes: {
          '/Arrival': (context) => Arrival(),
        },
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.grey[300],
          appBar: AppBar(
            backgroundColor: Color.fromRGBO(0, 31, 63, 1),
            centerTitle: true,
            title: Text(language == 'true' ? 'რუკა' : 'Map'),
          ),
          drawer: new BuildPlan(
            latlon: planmarkers,
            notifyParent: refresh,
            fromController: _fromController,
            toController: _toController,
          ),
          body: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    keyboardType: TextInputType.number,
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (notImportant) {
                      FocusScope.of(mapContext).unfocus();
                      getbuslocation();
                    },
                  )),
                  SizedBox(
                    height: 47,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(primary: Colors.greenAccent),
                      onPressed: getbuslocation,
                      child:
                          Text('Search', style: TextStyle(color: Colors.black)),
                    ),
                  )
                ],
              ),
              Expanded(
                child: Stack(children: <Widget>[
                  buildGoogleMap(context),
                  Align(
                    alignment: Alignment.topRight,
                    child: FloatingActionButton(
                      onPressed: _currentlocation,
                      backgroundColor: Color.fromARGB(20, 25, 25, 25),
                      elevation: 0,
                      mini: true,
                      child: Icon(Icons.my_location),
                    ),
                  )
                ]),
              ),
            ],
          ),
        ));
  }

  GoogleMap buildGoogleMap(context) {
    return GoogleMap(
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      initialCameraPosition: cameraposition,
      onMapCreated: (controller) async {
        _mapcontroller = controller;
        if (widget.markerloc != null) {
          // tu searchidan markeri movida, cameris animacia am markerze
          _fromController.text =
              '${widget.markerloc['lat']},${widget.markerloc['lon']}';
          Marker marker = Marker(
            markerId: MarkerId(widget.markerloc['stopid'].toString()),
            position: LatLng(widget.markerloc['lat'], widget.markerloc['lon']),
            icon: await StopIconData,
            consumeTapEvents: true,
            onTap: () {
              _mapcontroller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: LatLng(
                          widget.markerloc['lat'], widget.markerloc['lon']),
                      zoom: zoom)));
              _mapcontroller.showMarkerInfoWindow(
                  MarkerId(widget.markerloc['stopid'].toString()));
            },
            infoWindow: InfoWindow(
                title: widget.markerloc['name'],
                snippet: widget.markerloc['stopid'].toString(),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Arrival(
                              stopid: widget.markerloc['stopid'],
                              name: widget.markerloc['name'],
                              nameEn: widget.markerloc['name_en'])));
                }),
          );
          markers.add(marker);
          stopMarkers.add(marker);
          _mapcontroller.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target:
                      LatLng(widget.markerloc['lat'], widget.markerloc['lon']),
                  zoom: zoom)));
          setState(() {});
        }
      },
      onLongPress: (position) {
        var hasAlready = markers.any((mark) {
          return mark.markerId.value == 'From';
        });
        var markerid = hasAlready ? MarkerId('To') : MarkerId('From');
        markers.add(Marker(
            markerId: markerid,
            position: position,
            consumeTapEvents: true,
            onTap: () {
              _mapcontroller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: position, zoom: zoom)));
              _mapcontroller.showMarkerInfoWindow(markerid);
            },
            infoWindow: InfoWindow(
                title: 'X',
                snippet: hasAlready ? 'დასასრული' : 'დასაწყისი',
                onTap: () {
                  markers.removeWhere((mark) {
                    return mark.markerId.value == markerid.value;
                  });
                  setState(() {
                    if (hasAlready) {
                      planmarkers['To'] = '';
                      _toController.text = '';
                    } else {
                      planmarkers['From'] = '';
                      _fromController.text = '';
                    }
                  });
                })));
        setState(() {
          if (hasAlready) {
            planmarkers['To'] = '${position.latitude},${position.longitude}';
          } else {
            planmarkers['From'] = '${position.latitude},${position.longitude}';
          }
        });
      },
      markers: Set.from(markers),
      polylines: Set.from(polylines),
      onCameraMove: (position) {
        zoom = position.zoom;

        cameraposition = CameraPosition(target: position.target, zoom: zoom);
      },
      onCameraIdle: () async {
        var bounds = await _mapcontroller.getVisibleRegion();

        if (zoom > 16) {
          var stops = await db.rawQuery(
              'SELECT * FROM stops WHERE lat>? AND lat< ? AND lon>? AND lon<?',
              [
                bounds.southwest.latitude,
                bounds.northeast.latitude,
                bounds.southwest.longitude,
                bounds.northeast.longitude
              ]);
          for (var stop in stops) {
            Marker marker = Marker(
              markerId: MarkerId(stop['stopid'].toString()),
              position: LatLng(stop['lat'], stop['lon']),
              icon: await StopIconData,
              consumeTapEvents: true,
              onTap: () {
                _mapcontroller.animateCamera(CameraUpdate.newCameraPosition(
                    CameraPosition(
                        target: LatLng(stop['lat'], stop['lon']), zoom: zoom)));
                _mapcontroller
                    .showMarkerInfoWindow(MarkerId(stop['stopid'].toString()));
              },
              infoWindow: InfoWindow(
                  title: stop['name'],
                  snippet: stop['stopid'].toString(),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Arrival(
                                stopid: stop['stopid'],
                                name: stop['name'],
                                nameEn: stop['name_en'])));
                  }),
            );

            if (!markers.contains(marker)) {
              markers.add(marker);
              stopMarkers.add(marker);
            }
          }
          setState(() {});
        } else if (zoom < 13) {
          setState(() {
            for (var stopmarker in stopMarkers) {
              markers.remove(stopmarker);
            }
          });
        }
      },
    );
  }

  void _currentlocation() async {
    var currentLocation;
    Location location = new Location();
    location.changeSettings(accuracy: LocationAccuracy.high);

    try {
      currentLocation = await location.getLocation();
      // print(currentLocation);
      _mapcontroller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 0,
          target: LatLng(currentLocation.latitude, currentLocation.longitude),
          zoom: 15.0,
        ),
      ));
    } on Exception {
      currentLocation = null;
    }
  }

  fetchPost(url) async {
    dynamic response = await get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      return json.decode(utf8.decode(response.bodyBytes))['bus'];
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

  void getbuslocation() async {
    var data;
    FocusScope.of(mapContext).unfocus();
// polylinebii
// polyline 1

    if (oldbus != controller.text) {
      polylines.removeWhere((element) {
        return !planPolylines.contains(element);
      });
      data = await db.rawQuery(
          'SELECT shape from shape WHERE route LIKE ?', [controller.text]);
      var points = data[0]['shape'].split(',');
      var points2 = data[1]['shape'].split(',');
      List<LatLng> coordinates = [];
      List boundpoints = [];

      for (var point in points) {
        var latlon = point.split(':');

        try {
          boundpoints.add([double.parse(latlon[0]), double.parse(latlon[1])]);
          coordinates
              .add(LatLng(double.parse(latlon[1]), double.parse(latlon[0])));
        } catch (e) {
          print(e);
        }
      }
      var polyline = Polyline(
        polylineId: PolylineId('0'),
        color: Colors.blue,
        jointType: JointType.round,
        points: coordinates,
        width: 2,
      );

// polyline 2
      coordinates = [];
      for (var point in points2) {
        var latlon = point.split(':');
        try {
          boundpoints.add([double.parse(latlon[0]), double.parse(latlon[1])]);

          coordinates
              .add(LatLng(double.parse(latlon[1]), double.parse(latlon[0])));
        } catch (e) {
          print(e);
        }
      }
      var polyline2 = Polyline(
        polylineId: PolylineId('1'),
        color: Colors.red,
        jointType: JointType.round,
        points: coordinates,
        width: 2,
      );
      polylines.add(polyline);
      polylines.add(polyline2);
      oldbus = controller.text;

      boundpoints.sort((a, b) => a[1].compareTo(b[1]));

      var MaxNorth = boundpoints[boundpoints.length - 1][1];
      var MaxSouth = boundpoints[0][1];

      boundpoints.sort((a, b) => a[0].compareTo(b[0]));

      var MaxWest = boundpoints[0][0];
      var MaxEast = boundpoints[boundpoints.length - 1][0];

      LatLngBounds bound = LatLngBounds(
          southwest: LatLng(MaxSouth, MaxWest),
          northeast: LatLng(MaxNorth, MaxEast));
      _mapcontroller.animateCamera(CameraUpdate.newLatLngBounds(bound, 60));
      setState(() {});
    }

    List livebuses = [];
    data = await fetchPost(
        'http://transfer.ttc.com.ge:8080/otp/routers/ttc/buses?routeNumber=' +
            controller.text +
            '&forward=0');
    livebuses.add(data);
    data = await fetchPost(
        'http://transfer.ttc.com.ge:8080/otp/routers/ttc/buses?routeNumber=' +
            controller.text +
            '&forward=1');
    livebuses.add(data);
    for (var busmarker in busMarkers) {
      markers.remove(busmarker);
    }
    for (var buses in livebuses) {
      for (var bus in buses) {
        Marker marker = Marker(
            markerId: MarkerId('${bus["lat"] + bus["lon"]}'),
            position: LatLng(bus['lat'], bus['lon']),
            icon: await BusIconData,
            consumeTapEvents: true,
            onTap: () {
              _mapcontroller.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: LatLng(bus['lat'], bus['lon']), zoom: zoom)));
            });

        markers.add(marker);
        busMarkers.add(marker);
      }
    }
    setState(() {});
  }
}
