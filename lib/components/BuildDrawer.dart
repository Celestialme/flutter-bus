import 'package:android_bus2/main.dart' show db;
import 'package:flutter/material.dart';

import 'UpdateDataBase.dart';

class BuildDrawer extends StatefulWidget {
  final currentPage;
  final favorites;
  final parent;
  final language;
  const BuildDrawer(
      {Key key, this.currentPage, this.favorites, this.parent, this.language})
      : super(key: key);

  @override
  _BuildDrawerState createState() => _BuildDrawerState();
}

var updated = 'false';
var updateprogress = '';
var language;

class _BuildDrawerState extends State<BuildDrawer> {
  @override
  Widget build(BuildContext context) {
    progress(prog) {
      updateprogress = prog;
      setState(() {});
    }

    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 31, 63, 1),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    size: 50.0,
                    color: Colors.white,
                  ),
                ),
                ListTile(
                  selected: widget.currentPage == 'Gmap' ? true : false,
                  title: Row(children: <Widget>[
                    Icon(Icons.map),
                    Expanded(
                        child: Center(
                            child: Text(
                      language == 'true' ? 'რუკა' : 'Map',
                      style: TextStyle(fontSize: 18.0),
                    ))),
                    SizedBox(
                      width: 70.0,
                    )
                  ]),
                  onTap: widget.currentPage == 'Gmap'
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/Gmap',
                              arguments: {'ctx': context});
                        },
                ),
                ListTile(
                  selected: widget.currentPage == 'Favorites' ? true : false,
                  title: Row(children: <Widget>[
                    Icon(Icons.star),
                    Expanded(
                        child: Center(
                            child: Text(
                      language == 'true' ? 'ფავორიტები' : 'Favorites',
                      style: TextStyle(fontSize: 18.0),
                    ))),
                    SizedBox(
                      width: 70.0,
                    )
                  ]),
                  onTap: widget.currentPage == 'Favorites'
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/Favorites',
                              arguments: {'ctx': context});
                        },
                ),
                ListTile(
                  selected: widget.currentPage == 'Search' ? true : false,
                  title: Row(children: <Widget>[
                    Icon(Icons.search),
                    Expanded(
                        child: Center(
                            child: Text(
                      language == 'true' ? 'ძებნა' : 'Search',
                      style: TextStyle(fontSize: 18.0),
                    ))),
                    SizedBox(
                      width: 70.0,
                    )
                  ]),
                  onTap: widget.currentPage == 'Search'
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/Search', arguments: {
                            'ctx': context
                          }).then((onValue) => {
                                db
                                    .rawQuery('SELECT * FROM favorites')
                                    .then((data) => {
                                          widget.favorites.value = data,
                                        })
                              });
                        },
                ),
                ListTile(
                  selected: widget.currentPage == 'Schedule' ? true : false,
                  title: Row(children: <Widget>[
                    Icon(Icons.schedule),
                    Expanded(
                        child: Center(
                            child: Text(
                      language == 'true' ? 'გრაფიკი' : 'Schedule',
                      style: TextStyle(fontSize: 18.0),
                    ))),
                    SizedBox(
                      width: 70.0,
                    )
                  ]),
                  onTap: widget.currentPage == 'Schedule'
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/Schedule',
                              arguments: {'ctx': context});
                        },
                ),
                ListTile(
                  selected: widget.currentPage == 'Update' ? true : false,
                  title: Row(children: <Widget>[
                    Icon(Icons.cloud_download),
                    Expanded(
                        child: Center(
                            child: Text(
                      language == 'true'
                          ? 'განახლება $updateprogress'
                          : 'Update $updateprogress',
                      style: TextStyle(
                          fontSize: 18.0,
                          color: updated == 'false'
                              ? Colors.black
                              : updated == 'true'
                                  ? Colors.green
                                  : Colors.red),
                    ))),
                    SizedBox(
                      width: 70.0,
                    )
                  ]),
                  onTap: () async {
                    updated = await updateDataBase(db, progress);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          //switch between langauges
          ListTile(
              selected: widget.currentPage == 'Update' ? true : false,
              title: Row(
                children: <Widget>[
                  Expanded(
                    child: Text('English'),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(right: 20),
                      child: Switch(
                          inactiveTrackColor: Color.fromRGBO(0, 31, 63, 1),
                          activeTrackColor: Color.fromRGBO(0, 31, 63, 1),
                          activeColor: Colors.white,
                          value: language == 'true' ? true : false,
                          onChanged: (val) {
                            setState(() {
                              language = val.toString();
                              db.rawUpdate(
                                  'UPDATE language SET language=?', [language]);
                              widget.parent.setState(() {});
                            });
                          }),
                    ),
                  ),
                  Expanded(
                    child: Text('ქართული'),
                  )
                ],
              ))
        ],
      ),
    );
  }
}
