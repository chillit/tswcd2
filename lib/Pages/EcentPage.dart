
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

import '';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EventDetailsPage extends StatelessWidget {
  final String startDate;
  final String endDate;
  final String title;
  final String type;
  final String smallDescription;
  final String largeDescription;

  EventDetailsPage({
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.type,
    required this.smallDescription,
    required this.largeDescription,
  });

  String getMonthInText(String date) {
    DateTime dateTime = DateTime.parse(date);
    List<String> months = [
      '', // Пустой элемент для компенсации индексации с 1
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[dateTime.month];
  }
  Map<String, List<IconData>> categoryIcons = {
    'IT': [Icons.computer, Icons.desktop_mac, Icons.router],
    'study': [Icons.menu_book, Icons.school, Icons.library_books],
    'charity': [Icons.favorite, Icons.volunteer_activism, Icons.favorite_border],
    'sport': [Icons.sports_soccer, Icons.sports_basketball, Icons.sports_baseball],
    'culture': [Icons.palette, Icons.movie, Icons.music_note], // Updated culture icon
    'music': [Icons.music_note, Icons.headset, Icons.queue_music], // Added music icons
    'comedy': [Icons.mic_rounded, Icons.sentiment_satisfied, Icons.face] // Added comedy icons
  };

  IconData getIconForCategory(String category) {
    if (categoryIcons.containsKey(category)) {
      List<IconData> icons = categoryIcons[category]!;
      return icons[Random().nextInt(icons.length)];
    } else {
      return Icons.event;
    }
  }
  String formatDateTimeToUtc(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString).toUtc();
    String formattedDate = "${dateTime.year.toString().padLeft(4, '0')}"
        "${dateTime.month.toString().padLeft(2, '0')}"
        "${dateTime.day.toString().padLeft(2, '0')}T"
        "${dateTime.hour.toString().padLeft(2, '0')}"
        "${dateTime.minute.toString().padLeft(2, '0')}00Z";
    return formattedDate;
  }

  Future<void> _addToGoogleCalendar() async {
    final String eventTitle = Uri.encodeComponent(title);
    final String eventDetails = Uri.encodeComponent(largeDescription);
    final String eventLocation = Uri.encodeComponent('Place');
    final String eventStartTime = formatDateTimeToUtc(startDate);
    final String eventEndTime = formatDateTimeToUtc(endDate);
    final String googleCalendarUrl =
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$eventTitle&details=$eventDetails&location=$eventLocation&dates=$eventStartTime/$eventEndTime';

    if (await canLaunchUrl(Uri.parse(googleCalendarUrl))) {
      await launchUrl(Uri.parse(googleCalendarUrl));
    } else {
      throw 'Could not launch $googleCalendarUrl';
    }
  }

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateTime.parse(startDate).day.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${getMonthInText(startDate)}',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _addToGoogleCalendar,
                    child: Text('Добавить в Google Календарь'),
                    style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor, // Use the theme's primary color
                      onPrimary: Colors.white, // Use white text color
                    ),
                  ),
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
                          '$startDate : $endDate',
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
                  )
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
                Text('Похожие мероприятия',style: TextStyle(color: Colors.black),),
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
                                        endDate: events[index]['end_date'],
                                        title: events[index]['title'],
                                        type: events[index]['type'],
                                        smallDescription: events[index]['small_description'],
                                        largeDescription: events[index]['full_description'])),
                                  );
                                },

                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      children: <Widget>[
                                        Expanded(
                                          child: Icon(
                                            getIconForCategory(events[index]['type']),
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