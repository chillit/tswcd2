import 'dart:html' hide VoidCallback;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:table_calendar/table_calendar.dart';
import 'package:tswcd/Pages/EcentPage.dart';
import 'package:rxdart/rxdart.dart';
import '../createProduct.dart';
import '../main.dart';
import 'Registration_page.dart';
class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late List<String> allusers = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isowner = false;
  DatabaseReference? databaseReference;
  String currentUseruid = "";
  String selectedemail = "";
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  final BehaviorSubject<List<UserNotification>> userNotisSubject = BehaviorSubject();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<UserNotification> userUids = [];
  String _searchQuery = '';
  void updateUserNotisStream(String uid) {
    getUserNotisStream(uid).listen((data) {
      userNotisSubject.add(data);
    });
  }
  Future<List<UserNotification>> getUserNotisInfo(String userUid) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    final snapshot = await databaseReference.child('users/$userUid/notis')
        .get();

    List<UserNotification> usersInfo = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> notis = snapshot.value as Map<dynamic, dynamic>;

      for (var uid in notis.keys) {
        final userSnapshot = await databaseReference.child(
            'users/$uid/name').get();
        if (userSnapshot.exists) {
          String name = userSnapshot.value as String;
          usersInfo.add(UserNotification(uid: uid, name: name));
        }
      }
    }

    return usersInfo;
  }
  late List<UserNotification> users = [];
  @override
  void loadUserNotis() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      List<UserNotification> uids = await getUserNotisInfo(userUid);
      setState(() {
        userUids = uids;
      });
    }
  }
  List<String> _selectedCategories = [];
  List<String> categories = [
    'Мясные продукты', 'Овощи', 'Фрукты и ягоды', 'Молочные продукты', 'Бакалея',
    'Напитки', 'Выпечка и сладости', 'Консервированные продукты', 'Специи и приправы'
  ];

  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    currentUseruid = _auth.currentUser!.uid;
    isCurrentUserOwner();
    if (currentUser != null) {
      databaseReference = FirebaseDatabase.instance.reference().child('products/${currentUser.uid}');
    }
    updateUserNotisStream(currentUseruid);
    _fetchUsers();
    loadUserNotis();
    isCurrentUserOwner();
  }
  Stream<List<UserNotification>> getUserNotisStream(String userUid) async* {
    final databaseReference = FirebaseDatabase.instance.ref();

    Stream<DatabaseEvent> stream = databaseReference
        .child('users/$userUid/notis')
        .onValue;

    await for (var event in stream) {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> notis = snapshot.value as Map<dynamic,
            dynamic>;
        List<UserNotification> usersInfo = [];

        for (var uid in notis.keys) {
          final databaseReference = FirebaseDatabase.instance.ref();
          DataSnapshot nameSnapshot = await databaseReference.child('users/$uid/name').get();
          DataSnapshot emailSnapshot = await databaseReference.child('users/$uid/email').get();

          String name = nameSnapshot.exists ? nameSnapshot.value as String : 'Имя не найдено';
          String email = emailSnapshot.exists ? emailSnapshot.value as String : 'Email не найден';

          usersInfo.add(UserNotification(uid: uid, name: name,email: email));
        }
        yield usersInfo;
      } else {
        yield [];
      }
    }
  }
  Future<String> getImageUrl(String imagePath) async {
    String imageUrl = await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    return imageUrl;
  }
  String owneruid = "";
  Future<void> _addCurrentUserToSelectedUserNotis(String userEmail) async {
    String userId = await getUserIdByEmail(userEmail);

    if (userId.isNotEmpty) {
      final databaseReference = FirebaseDatabase.instance.ref();
      databaseReference.child('users/$userId/notis/${currentUseruid}')
          .set(true)
          .then((_) {
        print(
            "Current user UID added successfully to selected user's notis");
      }).catchError((error) {
        print("Failed to add current user UID: $error");
      });
    }
  }
  Future<String> getUserIdByEmail(String userEmail) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    String userId = '';
    final query = databaseReference.child('users')
        .orderByChild('email')
        .equalTo(userEmail);
    DataSnapshot snapshot = await query.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> users = snapshot.value as Map<
          dynamic,
          dynamic>;
      userId = users.keys.first as String;
    } else {
      print("No user found for the provided email");
    }

    return userId;
  }
  Future<void> acceptUser(String userUid) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference.child('users/$currentUserUid/owner').set(
        userUid);
    await databaseReference.child(
        'users/${userUid}/family/${currentUserUid}').set(true);
    await databaseReference.child('users/$currentUserUid/notis/$userUid')
        .remove();
  }
  Future<void> rejectUser(String userUid) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    final databaseReference = FirebaseDatabase.instance.ref();

    await databaseReference.child('users/$currentUserUid/notis/$userUid')
        .remove();

    print("User $userUid rejected");
  }
  Future<void> isCurrentUserOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    owneruid = user!.uid;
    if (user == null) {
      print("No user logged in");
      isowner = false;
    }
    final userUid = user!.uid;
    final databaseReferenc = FirebaseDatabase.instance.ref();
    try {
      final snapshot = await databaseReferenc.child('users/$userUid/role').get();
      if (snapshot.exists && snapshot.value == 'Глава семьи') {
        isowner = true;
      } else {
        isowner = false;
        final ownerSnapshot = await databaseReferenc.child('users/$userUid/owner').get();
        if (ownerSnapshot.exists) {
          final owner = ownerSnapshot.value;
          owneruid = ownerSnapshot.value.toString();
          if (owner != null) {
            databaseReference = FirebaseDatabase.instance.reference().child('products/$owner');
          }
        }
      }
    } catch (error) {
      print("Error checking if user is owner: $error");
      isowner = false;
    }
  }
  Future<void> _fetchUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final currentUserUid = currentUser.uid;
      final dataSnapshot = await _database.child('users').once();
      final usersMap = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;
      if (usersMap != null) {
        usersMap.forEach((key, value) {
          if (value['owner'] == currentUserUid) {
            setState(() {
              users.add(UserNotification(uid: key, name: value["name"],email: value["email"]));
            });
          } else {
            if (value["role"] == "Член семьи") {
              allusers.add(value["email"]);
            }
          }
        });
      }
      print(allusers);
    }
  }
  Future<UserNotification> getUserNameeByUid(String uid) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    DataSnapshot nameSnapshot = await databaseReference.child('users/$uid/name').get();
    DataSnapshot emailSnapshot = await databaseReference.child('users/$uid/email').get();

    String name = nameSnapshot.exists ? nameSnapshot.value as String : 'Имя не найдено';
    String email = emailSnapshot.exists ? emailSnapshot.value as String : 'Email не найден';

    return UserNotification(uid:uid,name: name, email: email);
  }
  Future<void> removeUserOwner(String userUid) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference.child('users/$userUid/owner').set("");
    await databaseReference.child(
        'users/${currentUser!.uid}/family/${userUid}').remove();
    print("User $userUid owner removed");
  }
  @override
  Widget build(BuildContext context) {
    final FirebaseDatabase database = FirebaseDatabase.instance;
    Stream<DatabaseEvent> familyStream = database
        .ref("users/${currentUseruid}/family")
        .onValue;
    bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    String textedit = "";
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: isowner?FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => resume(from: false,)),
          );
          print('Button Pressed!');
        },
        child: Icon(Icons.create_new_folder),

      ):null,

      appBar: AppBar(
        actions: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage()),
                        );
                      },
                      icon: Icon(Icons.logout),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _fetchUsers();
                  _scaffoldKey.currentState?.openEndDrawer();
                  print(isowner);
                },
                icon: Icon(Icons.menu),
              )
            ],
          )
        ],
        title: Text("Список товаров"),
      ),
      endDrawer: isowner ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            Column(
              children: <Widget>[
                SizedBox(height: 30,),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[700],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 10, end: 10),
                      child: Text("Добавление члена семьи"),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10,),


                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text("Введите почту пользователя"),
                    ),
                    SizedBox(height: 8,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(),

                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 3),
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              textedit = textEditingValue.text;
                              if (textEditingValue.text == '') {
                                textedit = textEditingValue.text;
                                return const Iterable<String>.empty();
                              }
                              return allusers.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              }).toSet().toList();
                            },
                            onSelected: (String selection) {
                              selectedemail = selection;
                              textedit = selection;
                            },
                            fieldViewBuilder: (
                                BuildContext context,
                                TextEditingController fieldTextEditingController,
                                FocusNode fieldFocusNode,
                                VoidCallback onFieldSubmitted
                                ) {
                              return TextField(
                                controller: fieldTextEditingController,
                                focusNode: fieldFocusNode,
                                onSubmitted: (String value) => onFieldSubmitted(),
                                decoration: InputDecoration(

                                  border: InputBorder.none, // Убираем подчеркивание
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25,),
                ElevatedButton(
                  onPressed: () {
                    String emailToUse = selectedemail.isEmpty ? textedit : selectedemail;
                    if (emailToUse.isNotEmpty) {
                      _addCurrentUserToSelectedUserNotis(emailToUse);
                    }
                  },
                  child: Text("Отправить запрос"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Скругление углов
                      side: BorderSide(
                        color: Colors.black54, // Цвет границы
                        width: 1, // Толщина границы
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Добавление отступов
                    elevation: 5, // Поднятие кнопки для создания теневого эффекта
                  ),
                ),
                SizedBox(height: 30,),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[700],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 10, end: 10),
                      child: Text("Ваша семья"),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10,),
                Container(
                  height: 400,
                  child: StreamBuilder<DatabaseEvent>(
                    stream: familyStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState
                          .waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text("Ошибка: ${snapshot.error}"));
                      } else if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return Center(child: Text("Данные отсутствуют"));
                      } else {
                        Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                        List<String> uids = values.keys.cast<String>().toList();
                        return ListView.builder(
                          itemCount: uids.length,
                          itemBuilder: (context, index) {
                            return FutureBuilder<UserNotification>(
                              future: getUserNameeByUid(uids[index]),
                              builder: (BuildContext context, AsyncSnapshot<UserNotification> snapshot) {
                                Widget tileContent;
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  tileContent = ListTile(
                                    title: Center(child: Text("Загрузка...")),
                                  );
                                } else if (snapshot.hasError) {
                                  tileContent = ListTile(
                                    title: Text("Ошибка: ${snapshot.error}"),
                                  );
                                } else {
                                  tileContent = ListTile(
                                    title: Text(snapshot.data!.name ?? "Никнейм не найден"),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Удалить пользователя?'),
                                            content: Text('Вы уверены, что хотите удалить этого пользователя?'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('Отмена'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text('Удалить'),
                                                onPressed: () {
                                                  removeUserOwner(uids[index]).then((_) => Navigator.of(context).pop());
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                }

                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Отступы вокруг контейнера
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey, // Цвет границы
                                      width: 1, // Толщина границы
                                    ),
                                    borderRadius: BorderRadius.circular(8), // Скругление углов границы
                                  ),
                                  child: tileContent,
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                _buildCategoryFilters(),
                SizedBox(height:20),

              ],
            ),

          ],
        ),
      ) : Drawer(
        child: Column(
          children: [
            SizedBox(height: 20,),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[700],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 10, end: 10),
                  child: Text("Приглашения в семью"),
                ),
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Container(
              height: MediaQuery.of(context).size.height*0.5,
              child: StreamBuilder<List<UserNotification>>(
                stream: userNotisSubject.stream,
                builder: (BuildContext context,
                    AsyncSnapshot<List<UserNotification>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Text('Нет приглашений');
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final userNoti = snapshot.data![index];
                        return ListTile(
                          title: Text(userNoti.name),
                          subtitle: Text(userNoti.email ?? ""),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () {
                                  acceptUser(userNoti.uid);
                                },
                              ),
                              SizedBox(width: 5,),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  rejectUser(userNoti.uid);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            _buildCategoryFilters(),
          ],
        ),
      ),
      body: databaseReference == null
          ? Center(child: Text("Пользователь не аутентифицирован"))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Поиск',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: databaseReference!.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
                  Map<String, dynamic> productsMap = snapshot.data!.snapshot.value as Map<String, dynamic>;
                  List<dynamic> products = productsMap.values.toList();
                  List<String> ids = productsMap.keys.toList();

                  List<dynamic> filteredProducts = productsMap.entries
                      .where((entry) =>
                  (_selectedCategories.isEmpty || _selectedCategories.contains(entry.value['category'])) &&
                      (entry.value['name'].toLowerCase().contains(_searchQuery)))
                      .map((e) => e.value)
                      .toList();

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 5 : 2,
                      childAspectRatio: 1,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      var product = filteredProducts[index];
                      var id = ids[index];
                      var imageRef = "products/${owneruid}/${ids[index]}/image";

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EventDetailsPage(startDate: product["date"], title: product["name"], type: product["category"], smallDescription: product["comment"], largeDescription: product["description"], imageurl: product["imageUrl"], uid: ids[index], owner: owneruid,)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: FutureBuilder<String>(
                                    future: getImageUrl(imageRef),
                                    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                      switch (snapshot.connectionState) {
                                        case ConnectionState.waiting:
                                          return Center(child: CircularProgressIndicator());
                                        default:
                                          if (snapshot.hasError) {
                                            return Text('Error: ${snapshot.error}');
                                          } else {
                                            return Image.network(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                      }
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        product['name'] ?? 'Название не указано',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      CheckedButton(isOwner:isowner, owner: owneruid, id:ids[index], counts: product["count"],),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: Text("No products available", style: TextStyle(fontSize: 20)));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCategoryFilters() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 16.0,
      children: categories.map((category) => FilterChip(
        label: Text(category),
        selected: _selectedCategories.contains(category),
        onSelected: (bool selected) {
          setState(() {
            if (selected) {
              _selectedCategories.add(category);
            } else {
              _selectedCategories.remove(category);
            }
          });
        },
      )).toList(),
    );
  }
}


class CheckedButton extends StatefulWidget {
  final  String owner;
  final String id;
  int counts;
  final bool isOwner;
  CheckedButton({required this.owner,required this.id,required this.counts,required this.isOwner});
  @override
  _CheckedButtonState createState() => _CheckedButtonState();
}

class _CheckedButtonState extends State<CheckedButton> {
  DatabaseReference? databaseReference = FirebaseDatabase.instance.ref();



  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            widget.isOwner?IconButton(
              onPressed: () {
                setState(() {
                  widget.counts++;
                  updateCount();
                });
              },
              icon: Icon(Icons.add),
            ): SizedBox(height: 0,),
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
                  }
                });
              },
              icon: Icon(Icons.remove),
            ),
          ],
        ),
        SizedBox(width: 5,),
        InkWell(
          onTap: () {
            setState(() {
              String path = 'products/${widget.owner}/${widget.id}';
              databaseReference!.child(path).remove();
            });
          },
          child: Container(
            padding: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey,
                width: 2.0,
              ),
            ),
            child: Icon(
              Icons.done_all,
              color: Colors.black,
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
