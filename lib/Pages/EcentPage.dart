
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
                          '${widget.type}',
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


                      final double screenWidth = MediaQuery.of(context).size.width;
                      final double screenHeight = MediaQuery.of(context).size.height;
                      int crossAxisCount = 2;
                      if (screenWidth>screenHeight) {
                        crossAxisCount = 4;
                      }
                      Map<String, dynamic> productsMap = snapshot.data!.snapshot.value as Map<String, dynamic>;
                      List<dynamic> products = productsMap.values.toList();
                      List<String> ids = productsMap.keys.toList();

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
                              var product = products[index];
                              var id = ids[index];
                              return GestureDetector(
                                onTap: () {

                                },
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      children: <Widget>[
                                        Expanded(
                                          child: Image.network(
                                              events[index]['imageUrl']
                                          )
                                        ),
                                        SizedBox(height: 8.0),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                events[index]['name'],
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              CheckedButton(owner: widget.owner,id:widget.uid,counts: events[index]["count"],),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(events[index]['comment']),
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
class CheckedButton extends StatefulWidget {
  String owner;
  String id;
  int counts;
  CheckedButton({required this.owner,required this.id,required this.counts});
  @override
  _CheckedButtonState createState() => _CheckedButtonState();
}

class _CheckedButtonState extends State<CheckedButton> {
  bool isChecked = false;
  DatabaseReference? databaseReference = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  widget.counts++;
                  updateCount();
                });
              },
              icon: Icon(Icons.add),
            ),
            Text(
              widget.counts.toString(),
              style: TextStyle(fontSize: 20),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  if (widget.counts > 0) {
                    widget.counts--;
                    updateCount();
                    if(widget.counts <= 0){
                      String path = 'products/${widget.owner}/${widget.id}';
                      databaseReference!.child(path).remove();
                    }
                    Navigator.pop(context);
                  }
                });
              },
              icon: Icon(Icons.remove),
            ),
          ],
        ),
        InkWell(
          onTap: () {
            setState(() {
              String path = 'products/${widget.owner}/${widget.id}';
              print(path);
              databaseReference!.child(path).remove();
              Navigator.pop(context);
            });
          },
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey,
                width: 2.0,
              ),
            ),
            child:Icon(
              Icons.check_box_outline_blank,
              color: Colors.grey,
              size: 20.0,
            ),
          ),
        ),
      ],
    );
  }

  void updateCount() {
    // Update count in the database
    String countPath = 'products/${widget.owner}/${widget.id}/count';
    databaseReference!.child(countPath).set(widget.counts);
  }
}
