import 'dart:html';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:table_calendar/table_calendar.dart';
import 'package:tswcd/Pages/EcentPage.dart';

import '../main.dart';
class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference? databaseReference;
  String currentUseruid = "";
  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    currentUseruid = _auth.currentUser!.uid;
    if (currentUser != null) {
      databaseReference = FirebaseDatabase.instance.reference().child('products/${currentUser.uid}');
    }
  }
  Future<String> getImageUrl(String imagePath) async {
    String imageUrl = await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Список товаров"),
      ),
      body: databaseReference == null
          ? Center(child: Text("Пользователь не аутентифицирован"))
          : StreamBuilder<DatabaseEvent>(
        stream: databaseReference!.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
            Map<String, dynamic> productsMap = snapshot.data!.snapshot.value as Map<String, dynamic>;
            List<dynamic> products = productsMap.values.toList();
            List<String> ids = productsMap.keys.toList();

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Количество столбцов
                childAspectRatio: 1, // Соотношение сторон плитки
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                var imageRef = "products/${currentUseruid}/${ids[index]}"; // Путь к изображению

                return Card(
                  clipBehavior: Clip.antiAlias, // Обрезать содержимое карточки по ее границам
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем содержимое на всю ширину карточки
                    children: [
                      Expanded(
                        child: FutureBuilder<String>(
                          future: getImageUrl(imageRef),
                          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                            if (snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasData) {
                              return Image.network(
                                snapshot.data!, // URL изображения товара
                                fit: BoxFit.cover, // Заполнить доступное пространство, сохранив пропорции изображения
                              );
                            } else {
                              // Заглушка или индикатор загрузки
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product['name'] ?? 'Название не указано', // Название товара
                          style: TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class EventList extends StatefulWidget {
  @override
  _EventListState createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  late Map<String, dynamic> currentUserData;
  final currentUser = FirebaseAuth.instance.currentUser;
  bool loading = true;

  void getCurrentUserData() {
    DatabaseReference usersRef = FirebaseDatabase.instance
        .reference()
        .child('users')
        .child(currentUser!.uid);
    usersRef.once().then((DatabaseEvent snapshot) {
      if (snapshot.snapshot.value != null) {
        setState(() {
          currentUserData = Map<String, dynamic>.from(snapshot.snapshot.value as Map<String, dynamic>);
          loading = false;
        });
      }
    });
  }
  Map<String, IconData> categoryIconMap = {};
  @override
  void initState() {
    super.initState();
    getCurrentUserData();
  }
  List<String> _categories = ['IT', 'study', 'charity', 'sport', 'culture', 'music', 'comedy'];
  List<String> _selectedCategories = [];
  final databaseReference = FirebaseDatabase.instance.reference().child('events');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  DateTime? _selectedDay;
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
      return Icons.event; // Возвращаем заглушку, если категория не найдена
    }
  }
  List<List<String>> setsOfCategories = [
    ['IT', 'study', 'charity'],
    ['sport', 'culture'], // Example of a second set of categories
    ["comedy",'music']
  ];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to log out the user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // You can add any additional cleanup or navigation logic here
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading?Center(child: CircularProgressIndicator(),):
    Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(child: Text('NEskuchnoPtr')),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState!.openEndDrawer();
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: StreamBuilder<DatabaseEvent>(

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
                events.sort((a, b) {
                  int aPoints = currentUserData['interests'][a['type']] ?? 0;
                  int bPoints = currentUserData['interests'][b['type']] ?? 0;
                  if (aPoints == bPoints) {
                    return Random().nextInt(2) * 2 - 1; // Randomly shuffle equal categories
                  }
                  return bPoints.compareTo(aPoints); // Sort based on points
                });

                events = events.where((event) {
                  DateTime eventStartDate = DateTime.parse(event['date']);
                  DateTime eventEndDate = DateTime.parse(event['end_date']);

                  // Проверяем, содержится ли выбранный тип в событии
                  bool isTypeMatched = _selectedCategories.isEmpty ||
                      _selectedCategories.contains(event['type']);

                  // Проверяем, попадает ли событие в выбранный временной промежуток
                  bool isDateInRange = _selectedDay == null ||
                      (eventStartDate.isBefore(_selectedDay!.add(Duration(days: 1))) &&
                          eventEndDate.isAfter(_selectedDay!.subtract(Duration(days: 1))));

                  return isTypeMatched && isDateInRange;
                }).toList();

                final double screenWidth = MediaQuery.of(context).size.width;
                final double screenHeight = MediaQuery.of(context).size.height;
                int crossAxisCount = 2;
                if (screenWidth>screenHeight) {
                  crossAxisCount = 4;
                }


                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1,
                  ),
                  itemCount: events.length,
                  itemBuilder: (BuildContext context, int index) {


                    bool isPhone=screenWidth<600;

                    return GestureDetector(
                      onTap: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        DatabaseReference usersRef = FirebaseDatabase.instance.reference().child('users').child(currentUser!.uid).child('interests').child(events[index]['type']);
                        usersRef.once().then((DatabaseEvent snapshot) {
                          if (snapshot.snapshot.value != null) {
                            // Если значение уже существует, увеличиваем его на 1
                            usersRef.set((snapshot.snapshot.value as int) + 1);
                          } else {
                            // Если значение не существует, устанавливаем его как 1
                            usersRef.set(1);
                          }
                        });

                        // Переход на страницу деталей события
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailsPage(
                              startDate: events[index]['date'],
                              endDate: events[index]['end_date'],
                              title: events[index]['title'],
                              type: events[index]['type'],
                              smallDescription: events[index]['small_description'],
                              largeDescription: events[index]['full_description'],
                            ),
                          ),
                        );
                      },

                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              if (!isPhone) Expanded( // This will hide the icon on phone screens
                                child: Icon(
                                  getIconForCategory(events[index]['type']),
                                  size: 100,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                events[index]['title'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.0),
                              Text(events[index]['small_description']),
                              SizedBox(height: 8.0),
                              Text(
                                "${events[index]['date']} : ${events[index]['end_date']}",
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Center(child: Text('Данные не найдены'));
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      endDrawer: Drawer(
        child: Column(
          children: <Widget>[
            SizedBox(height: 15,),

            TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: DateTime.now().subtract(Duration(
                  hours: DateTime.now().hour,
                  minutes: DateTime.now().minute,
                  seconds: DateTime.now().second)),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  if (isSameDay(_selectedDay, selectedDay)) {
                    // The selected day is already chosen, so clear the filter
                    _selectedDay = null;
                    _selectedCategories.clear();
                  } else {
                    _selectedDay = selectedDay;
                  }
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            SizedBox(height: 5,),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 16,end: 16),
              child: Divider(
                thickness: 0.5,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 5,),
            Padding(padding: EdgeInsetsDirectional.only(start: 16),
              child: Text(
                'Фильтры:',
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black,fontFamily: 'Futura'),
              ),),
            SizedBox(height: 10,),
            ...setsOfCategories.map((set) => Wrap(
              spacing: 8.0, // Horizontal spacing between chips
              runSpacing: 16.0, // Vertical spacing between lines of chips
              children: set.map((category) => FilterChip(
                label: Text(category),
                selected: _selectedCategories.contains(category),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.removeWhere((String name) => name == category);
                    }
                  });
                },
              )).toList(),
            )).toList(),
            SizedBox(height: 20,),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 20, end: 20),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedDay = null;
                    _selectedCategories.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Замените на ваш цвет по вашему выбору
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Сбросить фильтры',
                      style: TextStyle(
                        fontWeight: FontWeight.w100,
                        fontFamily: 'Futura',
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5,),
            currentUserData["role"]=="Busi"?Padding(
              padding: EdgeInsetsDirectional.only(start: 16,end: 16),
              child: Divider(
                thickness: 0.5,
                color: Colors.grey[700],
              ),
            ):Container(),
            SizedBox(height: 10,),
            currentUserData["role"]=="Busi"?Padding(
              padding: EdgeInsetsDirectional.only(start: 20,end: 20),
              child: ElevatedButton(onPressed: (){}, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Создать событие',
                    style: TextStyle(
                      fontWeight: FontWeight.w100,
                      fontFamily: 'Futura',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),),
            ):Container(),
            SizedBox(height: 15,),
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
                Text('ОПАСНАЯ ЗОНА',style: TextStyle(color: Colors.red),),
                SizedBox(width: 6,),
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 16,),
              ],
            ),
            SizedBox(height: 16,),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 20,end: 20),
              child: ElevatedButton(onPressed:
                  (){
                signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Выйти с аккаунта',
                      style: TextStyle(
                        fontWeight: FontWeight.w100,
                        fontFamily: 'Futura',
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),),
            ),

          ],
        ),
      ),
    );
  }
}
