
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

import '';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EventDetailsPage extends StatefulWidget {
  final String startDate;
  final String title;
  final String type;
  final String smallDescription;
  final String largeDescription;
  final String imageurl;
  final String owner;
  final String uid;

  EventDetailsPage({
    required this.startDate,
    required this.title,
    required this.type,
    required this.smallDescription,
    required this.largeDescription,
    required this.imageurl,
    required this.uid,
    required this.owner
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final databaseReference = FirebaseDatabase.instance.reference().child('events');
  DatabaseReference databaseReferencee = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    databaseReferencee = FirebaseDatabase.instance.ref('products/${widget.owner}/${widget.uid}/alter');
  }

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
                          '${widget.title}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${widget.type == "charity"?"Благотворительноость":widget.type == "sport"?"Спорт":widget.type == "culture"?"Культура":widget.type == "study"?"Учеба":widget.type == "IT"?"IT":widget.type == "comedy"?"Комедия":widget.type == "music"?"Музыка":""}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${widget.startDate}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${widget.smallDescription}',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${widget.largeDescription}',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Image.network(widget.imageurl)
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
                stream: databaseReferencee.onValue,
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
                        return (widget.type.contains(event['type']) && widget.title!=event["title"]);
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