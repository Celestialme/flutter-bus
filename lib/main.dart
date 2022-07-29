import 'dart:io';

import 'package:android_bus2/pages/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/BuildDrawer.dart';
import 'pages/arrival.dart';
import 'pages/schedule.dart';
import 'pages/search.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Database db;
var favorites = ValueNotifier([]);
void main() => runApp(MaterialApp(
    title: 'Welcome to Flutter',
    routes: {
      '/Arrival': (context) => Arrival(),
      '/Search': (context) => Search(),
      '/Favorites': (context) => Favorites(),
      '/Schedule': (context) => Schedule(),
      '/Gmap': (context) => Gmap(),
    },
    home: Favorites()));

class Favorites extends StatefulWidget {
  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  @override
  void initState() {
    (() async {
      var dbDir = await getDatabasesPath();
      var directory = new Directory(dbDir);
      var check = await directory.exists();
      if (check == false) {
        directory.create();
      }

      var dbPath = join(dbDir, "db.db");

      var value = await databaseExists(dbPath);
      if (value == false) {
        // Create the writable database file from the bundled demo database file:
        ByteData data = await rootBundle.load("assets/db.db");

        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(dbPath).writeAsBytes(bytes);
      }

      db = await openDatabase(dbPath);
      favorites.value = await db.rawQuery('SELECT * FROM favorites');
      await db
          .rawQuery('SELECT language FROM language')
          .then((data) => language = data[0]['language']);

      setState(() {});
    })();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromRGBO(0, 31, 63, 1),
        title: Text(language == 'true' ? 'ფავორიტები' : 'Favorites'),
      ),
      drawer: new BuildDrawer(
        currentPage: 'Favorites',
        favorites: favorites,
        parent: this,
        language: language,
      ),
      body: ValueListenableBuilder(
        valueListenable: favorites,
        builder: (BuildContext context, List value, Widget child) {
          return ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  favorites.value = List.of(favorites.value);

                  final item = favorites.value.removeAt(oldIndex);
                  favorites.value.insert(newIndex, item);
                  db
                      .execute('DELETE FROM favorites;VACUUM')
                      .then((notImportant) => {
                            for (var index = 0;
                                index < favorites.value.length;
                                index++)
                              {
                                // print('esaa $index'),
                                db.execute(
                                    'INSERT INTO favorites VALUES(?,?,?)', [
                                  favorites.value[index]['stopid'],
                                  favorites.value[index]['name'],
                                  favorites.value[index]['name_en']
                                ])
                              }
                          });
                });
              },
              children: favorites.value
                  .map<Widget>((stop) => GestureDetector(
                        key: ValueKey(stop),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Arrival(
                                      stopid: stop['stopid'],
                                      name: stop['name'],
                                      nameEn: stop['name_en'])));
                        },
                        child: Container(
                          padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Theme.of(context).dividerColor))),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                  flex: 4,
                                  child: Text(
                                    language == 'true'
                                        ? stop['name']
                                        : stop['name_en'],
                                    textAlign: TextAlign.center,
                                  )),
                              Expanded(
                                  flex: 1,
                                  child: Text('#${stop["stopid"]}  ',
                                      textAlign: TextAlign.end))
                            ],
                          ),
                        ),
                      ))
                  .toList());
        },
      ),
    );
  }
}
