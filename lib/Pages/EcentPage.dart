
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

import '';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EventDetailsPage extends StatelessWidget {
  final String startDate;
  final String title;
  final String type;
  final String smallDescription;
  final String largeDescription;
  final String imageurl;

  EventDetailsPage({
    required this.startDate,
    required this.title,
    required this.type,
    required this.smallDescription,
    required this.largeDescription,
    required this.imageurl
  });


  final databaseReference = FirebaseDatabase.instance.reference().child('events');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мероприятия'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${type == "charity"?"Благотворительноость":type == "sport"?"Спорт":type == "culture"?"Культура":type == "study"?"Учеба":type == "IT"?"IT":type == "comedy"?"Комедия":type == "music"?"Музыка":""}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$startDate',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$smallDescription',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '$largeDescription',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Image.network(imageurl)
                ],
              ),

              SizedBox(height: 30),
              Row(
                children: [
                  SizedBox(width: 16,),
                  Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[700],
                  ),
                ),
                  SizedBox(width: 6,),
                Text('альтернативы',style: TextStyle(color: Colors.black),),
                  SizedBox(width: 6,),
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 16,),  ],
              ),
              SizedBox(height: 30),
              StreamBuilder<DatabaseEvent>(
                stream: databaseReference.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    DataSnapshot dataValues = snapshot.data!.snapshot;
                    if (dataValues.value != null) {
                      List<dynamic> events = [];
                      dynamic data = dataValues.value;
                      if (data is List) {
                        events.addAll(data);
                      } else if (data is Map) {
                        data.forEach((key, value) {
                          events.add(value);
                        });
                      }

                      events = events.where((event) {
                        DateTime eventDate = DateTime.parse(event['date']);
                        return (type.contains(event['type']) && title!=event["title"]);
                      }).toList();

                      final double screenWidth = MediaQuery.of(context).size.width;
                      final double screenHeight = MediaQuery.of(context).size.height;
                      int crossAxisCount = 2;
                      if (screenWidth>screenHeight) {
                        crossAxisCount = 4;
                      }

                      return Align(
                        alignment: Alignment.center,
                        child: Container( 
                          height: 600,
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 1,
                            ),
                            itemCount: events.length,
                            itemBuilder: (BuildContext context, int index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => EventDetailsPage(
                                        startDate: events[index]['date'],
                                        title: events[index]['title'],
                                        type: events[index]['type'],
                                        smallDescription: events[index]['small_description'],
                                        largeDescription: events[index]['full_description'], imageurl: imageurl,)

                                    ),
                                  );
                                },

                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      children: <Widget>[
                                        Expanded(
                                          child: Icon(
                                            Icons.add,
                                            size: 100,
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(
                                          events[index]['title'],
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(events[index]['small_description']),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      return Center(child: Text('Данные не найдены'));
                    }
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}