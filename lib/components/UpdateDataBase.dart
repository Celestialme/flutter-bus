import 'dart:convert';

import 'package:http/http.dart';
import 'package:sqflite/sqflite.dart';

updateDataBase(Database db, Function progress) async {
  var percentage = 0;
  var index = 1;
  var length = 0;
  try {
    List dict = [];
    var data = await fetchPost(
        'http://transfer.ttc.com.ge:8080/otp/routers/ttc/routes?type=3');
    List routes = data['Route'].map((routn) {
      return routn['RouteNumber'];
    }).toList(); // get all routes
    Batch batch = db.batch();
    batch.execute('DELETE FROM schedule;'); // delete old schedule
    batch.execute('DELETE FROM description;'); // delete old description
    batch.execute('DELETE FROM shape'); // delete old shape
    batch.commit();
    db.execute('vacuum;');
    length = routes.length * 2; // N1 of 2 heavy computation task
    for (var route in routes) {
      percentage = (index / length * 100).floor();
      progress(' - ' + percentage.toString() + '%');
      index++;
      for (var forward = 0; forward < 2; forward++) {
        var data = await fetchPost(
            'http://transfer.ttc.com.ge:8080/otp/routers/ttc/routeSchedule?routeNumber=$route&type=3&forward=$forward'); // get all forward 0 buses in routes  of schedule
        if (data != null) dict.add(data);

        data = await fetchPost(
            'http://transfer.ttc.com.ge:8080/otp/routers/ttc/routeSchedule?routeNumber=$route&type=3&forward=$forward'); // get all forward 1 buses in routes of schedule
        if (data != null) dict.add(data);
      }
    }

    batch = db.batch(); //computes too fast to update any progress
    for (var item in dict) {
      var forward = (item['Forward'] == true ? 1 : 0);

      batch.execute('INSERT INTO description VALUES (?,?,?)', [
        item['RouteNumber'] * 1,
        forward == 0 || forward == 1 ? forward : 0,
        item['DirectionDescription']
      ]); // insert description
      for (var weekday in item['WeekdaySchedules']) {
        // inner loop because weekdays are located into item.weekdayschedule
        var fromday = weekday['FromDay'];
        var today = weekday['ToDay'];
        for (var stop in weekday['Stops']) {
          if (stop['Type'] == 'bus') {
            batch.execute('INSERT INTO schedule VALUES (?,?,?,?,?,?)', [
              item['RouteNumber'] * 1,
              fromday,
              today,
              stop['StopId'],
              stop['ArriveTimes'],
              forward
            ]); // insert schedule
          }
        }
      }
    }
    progress(' - 50%');
    // shape creation
    dict = [];
    length = routes.length * 2; // N2 of 2 heavy computation task
    index = 0;
    for (var route in routes) {
      percentage = 50 + (index / length * 100).floor();
      progress(' - ' + percentage.toString() + '%');
      index++;
      for (var i = 0; i < 2; i++) {
        var data = await fetchPost(
            'http://transfer.ttc.com.ge:8080/otp/routers/ttc/routeInfo?routeNumber=$route&type=bus&forward=$i');
        if (data == null) continue;
        dict.add({
          'route': data['RouteNumber'],
          'shape': data['Shape'],
          'forward': i
        });
      }
    }
    for (var item in dict) {
      batch.execute('INSERT INTO shape VALUES (?,?,?)',
          [item['route'], item['forward'], item['shape']]);
    }
    batch.commit();
    progress(' - 100%');
    return 'true';
  } catch (e) {
    return 'error';
  }
}

fetchPost(url) async {
  dynamic response = await get(Uri.parse(url), headers: {
    'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
    'Accept': 'application/json, */*; q=0.01'
  });

  if (response.statusCode == 200) {
    // If server returns an OK response, parse the JSON.
    return json.decode(utf8.decode(response.bodyBytes));
  } else {
    // If that response was not OK, throw an error.
    return null;
  }
}
