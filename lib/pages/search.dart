import 'package:android_bus2/components/BuildDrawer.dart';
import 'package:android_bus2/pages/map.dart' show Gmap;
import 'package:flutter/material.dart';

import 'arrival.dart' show Arrival;
import '../main.dart' show db, favorites;

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  var stops = [];
  @override
  @override
  Widget build(BuildContext context) {
    final Map arguments = ModalRoute.of(context).settings.arguments as Map;
    ScrollController _controller = ScrollController();
    return MaterialApp(
      routes: {
        '/Search': (context) => Search(),
        '/Gmap': (context) => Gmap(),
      },
      home: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(0, 31, 63, 1),
          centerTitle: true,
          title: Text(language == 'true' ? 'ძებნა' : 'Search'),
        ),
        drawer: new BuildDrawer(
          currentPage: 'Search',
          parent: this,
        ),
        body: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Color.fromRGBO(0, 31, 63, 1),
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) async {
                stops = await db.rawQuery(
                    'SELECT stopid,name,name_en,lat,lon FROM stops WHERE instr(stopid,?)>0 OR instr(name,?)>0  OR instr(lower(name_en),?)>0 ',
                    [value, value, value.toLowerCase()]);
                _controller.jumpTo(_controller.position.minScrollExtent);
                setState(() {});
              },
            ),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                    controller: _controller,
                    itemCount: stops.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return new Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // print(stops[index]['stopid']);
                                    Navigator.pushReplacement(
                                        arguments['ctx'],
                                        MaterialPageRoute(
                                            builder: (context) => Arrival(
                                                  stopid: stops[index]
                                                      ['stopid'],
                                                  name: stops[index]['name'],
                                                  nameEn: stops[index]
                                                      ['name_en'],
                                                )));
                                  },
                                  child: Row(children: [
                                    Expanded(
                                        flex: 1,
                                        child: Text(' ' +
                                            stops[index]['stopid'].toString())),
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
                              ),
                              GestureDetector(
                                child: Icon(Icons.map),
                                onTap: () {
                                  Navigator.pushReplacement(
                                      arguments['ctx'],
                                      MaterialPageRoute(
                                          builder: (context) => Gmap(
                                                markerloc: stops[index],
                                              )));
                                },
                              )
                            ],
                          ),
                          Divider(
                            color: Colors.white,
                          )
                        ],
                      );
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }
}
