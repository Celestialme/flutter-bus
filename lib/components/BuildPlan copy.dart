import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
var page = 1;
var planData;
var active;
List <Item>  items;

class BuildPlan extends StatefulWidget {
  final latlon;
  final Function notifyParent;
  const BuildPlan({
    Key key,
    this.latlon,
    this.notifyParent
  }) : super(key: key);

  @override
  _BuildPlanState createState() => _BuildPlanState(latlon:this.latlon);
}
var typedropdownValue='ავტობუსით და მეტროთი';
var feetdropdownValue = '1000 მეტრი';
class _BuildPlanState extends State<BuildPlan> {
  var latlon;
  _BuildPlanState({this.latlon});
  @override
  Widget build(BuildContext context) {
   
    return page == 1 ? drawerFirstPage() : drawerSecondtPage();}
  
  Drawer drawerFirstPage() {
    
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
      decoration: BoxDecoration(
        color:Colors.blue
      ),
      child: Icon(Icons.directions_bus,
      size: 50.0,
      color: Colors.white,
      ),
    ),
                 ),
               ],
             ),

            Expanded(
              child: SingleChildScrollView(scrollDirection: Axis.vertical, child: Column(children: <Widget>[

                 Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                
                Icon(Icons.location_on),
                Expanded(child: TextField(controller: new TextEditingController(text: latlon['From']),decoration: InputDecoration(hintText: 'აქედან'),)),
                GestureDetector(onTap: (){
                  widget.notifyParent('delFromMarker');

                },child: Icon(Icons.clear)),

              ],
          ),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(Icons.keyboard_tab),
                Expanded(child: TextField(controller: new TextEditingController(text: latlon['To']),decoration: InputDecoration(hintText: 'აქეთ'),)),
                GestureDetector(onTap: (){
                  widget.notifyParent('delToMarker');

                },child: Icon(Icons.clear)),

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
                    items:  <String>['ავტობუსით და მეტროთი', 'მხოლოდ ავტობუსით', 'მხოლოდ მეტროთი']
        .map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        
        value: value,
        child: Text(value),
        
      );
    }).toList(),
                  onChanged: (String newValue) {
                    setState(() {
       typedropdownValue = newValue;
    });
  } 
                  
                  ),
                )

              ],
          ),

           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(Icons.transfer_within_a_station),
                Expanded(child: DropdownButton(
                          value: feetdropdownValue,
                          iconSize: 24,
                          items:  <String>["100 მეტრი", "200 მეტრი", "300 მეტრი", "400 მეტრი", "500 მეტრი", "750 მეტრი", "1000 მეტრი", "1500 მეტრი", "2000 მეტრი", "2500 მეტრი", "5000 მეტრი", "7500 მეტრი", "10000 მეტრი"]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              
              value: value,
              child: Text(value),
              
            );
          }).toList(),
                        onChanged: (String newValue) {
                          setState(() {
            feetdropdownValue = newValue;
          });
        } 
                  
                  ), )

              ],
          ),
               
              ],),),
            ),

            // Expanded(child:Container())
            // ,
           Row(
             children: <Widget>[
               Expanded(
                 child: RaisedButton(
          onPressed: () async {
                          RegExp re = RegExp(r'(\d+)-(\d+)-(\d+)');
                          var match =  re.allMatches(DateTime.now().toString()).elementAt(0); 
                          
                          var fromplace = latlon['From'];
                          var toplace = latlon['To'];
                          var time=TimeOfDay.now().format(context).replaceAll(' ', '');
                          var date='${match.group(2)}-${match.group(3)}-${match.group(1)}';
                          var mode= typedropdownValue =='მხოლოდ ავტობუსით' ? 'BUS,WALK':typedropdownValue=='მხოლოდ მეტროთი'? 'TRAM,RAIL,SUBWAY,FUNICULAR,GONDOLA,WALK': 'TRANSIT,WALK' ;
                          var maxwalkingdistance = new RegExp(r'\d+').stringMatch(feetdropdownValue);
                          planData = await fetchPost('http://transfer.ttc.com.ge:8080/otp/routers/ttc/plan?fromPlace=$fromplace&toPlace=$toplace&time=$time&date=$date&mode=$mode&maxWalkDistance=$maxwalkingdistance&arriveBy=false&wheelchair=false&locale=ka');
                           items = planData['itineraries'].map<Item>((item){
                          return Item(
                            headerValue: [item['legs'],item['duration']],
                            expandedValue: item['legs'],
                            isExpanded: false,
                            );
    }).toList();
            setState((){
              page = 2;
              
            });
          },
          child: Text('დაგეგმვა'),
        ),
               ),
             ],
           )

        ],




      ),

    )
  
  );
  }

  Drawer drawerSecondtPage(){
    
     return Drawer(child: SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Column(children: <Widget>[

           Row(
               children: <Widget>[
                 Expanded(
                   child: DrawerHeader(
      decoration: BoxDecoration(
        color:Colors.blue
      ),
      child: Icon(Icons.directions_bus,
      size: 50.0,
      color: Colors.white,
      ),
    ),
                 ),
               ],
             ),

      Expanded(child: SingleChildScrollView(scrollDirection: Axis.vertical,child: ExpansionPanelList(expansionCallback: (int index, bool isExpanded) {
        setState(() {
          active=null;
          widget.notifyParent(items[index].expandedValue);
          items[index].isExpanded = !isExpanded;
        });
      },      
      children: items.map<ExpansionPanel>((Item item) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              dense: true,
              title: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,children: item.headerValue[0].map<Widget>((itm){
                  return itm['mode'] == 'WALK' ? Icon(Icons.directions_walk) : itm['mode'] == 'BUS' ? Row(children: <Widget>[Text('№'+itm['route']),Icon(Icons.directions_bus)],) : Icon(Icons.directions_subway);
                }).toList(),),
              ),
            );
          },
          body: Container(
            height: 150,
            child: ListView.builder(scrollDirection: Axis.vertical,itemCount: item.expandedValue.length,itemBuilder: (BuildContext context, int index) {
              return GestureDetector(

                onTap: (){
                  widget.notifyParent(index);
                  active = index;
                },
                child: SingleChildScrollView(
                  
                  padding: EdgeInsets.only(top: 5,bottom: 5),
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    
                    color: active==index ? Colors.green:Colors.white,
                    child: Row(children: <Widget>[
                      item.expandedValue[index]['mode'] == 'WALK' ? Icon(Icons.directions_walk) : item.expandedValue[index]['mode'] == 'BUS' ? Icon(Icons.directions_bus) : Icon(Icons.directions_subway),
                      item.expandedValue[index]['mode'] == 'BUS'? Text('№'+item.expandedValue[index]['route']+' '):Container(),
                      item.expandedValue[index]['mode'] == 'WALK' ? Text('გაიარე ${item.expandedValue[index]['distance'].round()}მ'):Container(),
                      Text('${item.expandedValue[index]['from']['name']!='Origin'?item.expandedValue[index]['from']['name']:''} - ${item.expandedValue[index]['to']['name']!='Destination'?item.expandedValue[index]['to']['name']:'დანიშნულების ადგილი'} ')
                    ],),
                  ),
                ),
              );
            },),
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),


      ) 
      
      
      
      
      ),),


       Row(
             children: <Widget>[
               Expanded(
                 child: RaisedButton(
          onPressed: (){
            
            setState(() {
              page = 1;
            });
          },
          child: Text('უკან'),
        ),
               ),
             ],
           )


      ],)
      
      )
      );
  }




    }


     fetchPost(url) async {
    dynamic response = await get(url);

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