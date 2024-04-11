import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file/memory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tswcd/Pages/Registration_page.dart';
class resume extends StatefulWidget {

  resume({super.key});

  @override
  State<resume> createState() => _resumeState();
}

class _resumeState extends State<resume> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _comment = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discription = TextEditingController();
  Uint8List? fileBytes;
  String? fileName;
  bool isowner = false;
  late List<String> allusers = [];
  late List<UserNotification> users = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
  late List<String> filteredUsers = [];
  String? selectedUser;
  List<UserNotification> userUids = [];
  String selectedemail = "";
  bool isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  String? selectedProductName;
  StreamController<List<UserNotification>> _controller = StreamController<List<UserNotification>>.broadcast();
  final BehaviorSubject<List<UserNotification>> userNotisSubject = BehaviorSubject();

  void updateUserNotisStream(String uid) {
    getUserNotisStream(uid).listen((data) {
      userNotisSubject.add(data);
    });
  }
  Stream<List<UserNotification>> getUserNotisStreamm(String uid) {
    return _controller.stream;
  }
  final Map<String, List<String>> productsByCategory = {
    'Мясные продукты': ['Куриное филе', 'Говядина', 'Свинина', 'Куриные окорочка', 'Рыба', 'Креветки', 'Мидии'],
    'Овощи': ['Картофель', 'Лук', 'Морковь', 'Капуста', 'Огурцы', 'Помидоры', 'Чеснок', 'Сельдерей', 'Брокколи', 'Грибы'],
    'Фрукты и ягоды': ['Яблоки', 'Бананы', 'Апельсины', 'Лимоны', 'Виноград', 'Клубника'],
    'Молочные продукты': ['Молоко', 'Сливочное масло', 'Сыр', 'Творог', 'Кефир', 'Йогурт', 'Сметана'],
    'Бакалея': ['Сахар', 'Соль', 'Мука пшеничная', 'Рис', 'Гречка', 'Макароны', 'Подсолнечное масло', 'Соевый соус', 'Рыбный соус', 'Вустерширский соус', 'Кукурузный сироп'],
    'Напитки': ['Вода бутилированная', 'Сок', 'Чай', 'Кофе', 'Какао', 'Энергетический напиток', 'Вино', 'Пиво', 'Водка', 'Коньяк', 'Квас'],
    'Выпечка и сладости': ['Хлеб', 'Шоколад', 'Конфеты', 'Печенье', 'Варенье', 'Мед', 'Сахарная пудра'],
    'Замороженные и консервированные продукты': ['Зеленый горошек', 'Маслины', 'Оливки'],
    'Специи и приправы': ['Соус томатный', 'Майонез', 'Горчица', 'Кетчуп', 'Базилик', 'Петрушка', 'Укроп', 'Хрен', 'Имбирь', 'Куркума', 'Корица', 'Мускатный орех', 'Ваниль'],
    'Снеки и быстрые перекусы': ['Чипсы', 'Попкорн'],
  };

  @override
  void dispose() {
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      try {
        setState(() {
          fileBytes = result.files.first.bytes;
          fileName = result.files.first.name;
        });
      } catch (e) {
        print('Error processing file picker result: $e');
      }
    } else {
      print('File picker result is null');
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      locale: const Locale("ru","RU"),
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> sendDataToDatabase(String? name, String category, String comment, String description, String date, Uint8List fileData, String fileName) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final productRef = databaseRef.child('products/${FirebaseAuth.instance.currentUser!.uid}/$id');

    try {
      final ref = FirebaseStorage.instance.ref('products/${FirebaseAuth.instance.currentUser!.uid}/$id/image');
      final result = await ref.putData(fileData);
      final imageUrl = await result.ref.getDownloadURL();
      await productRef.set({
        'name': name,
        'category': category,
        'comment': comment,
        'description': description,
        'date': date,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> isCurrentUserOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in");
      isowner = false;
    }
    final userUid = user!.uid;
    final databaseReference = FirebaseDatabase.instance.ref();


    try {
      final snapshot = await databaseReference.child('users/$userUid/role').get();
      if (snapshot.exists && snapshot.value == 'Глава семьи') {
        isowner = true;
      } else {
        isowner = false;
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
              users.add(UserNotification(uid: key, name: value["name"]));
            });
          }
          else{
            allusers.add(value["email"]);
          }
        });
      }
    }
  }
  void initState() {

    super.initState();
    updateUserNotisStream(user.uid);
    _fetchUsers();
    loadUserNotis();
    isCurrentUserOwner();
  }

  Future<void> handleSubmit() async {
    if (fileBytes != null && fileName != null) {
      await sendDataToDatabase(selectedProductName,_categoryController.text, _comment.text, _discription.text, _dateController.text, fileBytes!, fileName!);
    }
  }
  void loadUserNotis() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      List<UserNotification> uids = await getUserNotisInfo(userUid);
      setState(() {
        userUids = uids;
      });
    }
  }
  Future<List<UserNotification>> getUserNotisInfo(String userUid) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    final snapshot = await databaseReference.child('users/$userUid/notis').get();

    List<UserNotification> usersInfo = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> notis = snapshot.value as Map<dynamic, dynamic>;

      for (var uid in notis.keys) {
        final userSnapshot = await databaseReference.child('users/$uid/name').get();
        if (userSnapshot.exists) {
          String name = userSnapshot.value as String;
          usersInfo.add(UserNotification(uid: uid, name: name));
        }
      }
    }

    return usersInfo;
  }
  Future<String> getUserIdByEmail(String userEmail) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    String userId = '';
    final query = databaseReference.child('users').orderByChild('email').equalTo(userEmail);
    DataSnapshot snapshot = await query.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
      userId = users.keys.first as String;
    } else {
      print("No user found for the provided email");
    }

    return userId;
  }
  Future<void> _addCurrentUserToSelectedUserNotis(String userEmail) async {
    String userId = await getUserIdByEmail(userEmail);

    if (userId.isNotEmpty) {
      final databaseReference = FirebaseDatabase.instance.ref();
      databaseReference.child('users/$userId/notis/${user.uid}').set(true).then((_) {
        print("Current user UID added successfully to selected user's notis");
      }).catchError((error) {
        print("Failed to add current user UID: $error");
      });
    }
  }
  Stream<List<UserNotification>> getUserNotisStream(String userUid) async* {
    final databaseReference = FirebaseDatabase.instance.ref();

    Stream<DatabaseEvent> stream = databaseReference.child('users/$userUid/notis').onValue;

    await for (var event in stream) {
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> notis = snapshot.value as Map<dynamic, dynamic>;
        List<Future<UserNotification>> futures = [];

        for (var uid in notis.keys) {
          futures.add(getUserNameByUid(uid));
        }
        List<UserNotification> usersInfo = await Future.wait(futures);
        yield usersInfo;
      } else {
        yield [];
      }
    }
  }


  Future<UserNotification> getUserNameByUid(String uid) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    final snapshot = await databaseReference.child('users/$uid/name').get();

    if (snapshot.exists) {
      String name = snapshot.value as String;
      return UserNotification(uid: uid, name: name);
    } else {
      return UserNotification(uid: uid, name: 'Unknown');
    }
  }
  Future<void> acceptUser(String userUid) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference.child('users/$currentUserUid/owner').set(userUid);
    await databaseReference.child('users/${userUid}/family/${currentUserUid}').set(true);
    await databaseReference.child('users/$currentUserUid/notis/$userUid').remove();
  }
  Future<void> rejectUser(String userUid) async {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    final databaseReference = FirebaseDatabase.instance.ref();

    await databaseReference.child('users/$currentUserUid/notis/$userUid').remove();

    print("User $userUid rejected");
  }
  Future<void> removeUserOwner(String userUid) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference.child('users/$userUid/owner').set("");
    await databaseReference.child('users/${currentUser!.uid}/family/${userUid}').remove();
    print("User $userUid owner removed");
  }
  Future<String> getUserNameeByUid(String uid) async {
    final databaseReference = FirebaseDatabase.instance.ref();

    DataSnapshot snapshot = await databaseReference.child('users/$uid/name').get();

    if (snapshot.exists) {
      return snapshot.value as String;
    } else {
      return 'Имя не найдено';
    }
  }
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseDatabase database = FirebaseDatabase.instance;
    final User? currentUser = auth.currentUser;

    if (currentUser == null) {
      return Center(child: Text("Пользователь не авторизован"));
    }
    String textedit = "";
    Stream<DatabaseEvent> familyStream = database.ref("users/${currentUser.uid}/family").onValue;
    List<String> allProducts = productsByCategory.values.expand((list) => list).toList();
    return Scaffold(

      backgroundColor: Colors.white,

      key: _scaffoldKey,
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
                        _fetchUsers();
                        FirebaseAuth.instance.signOut();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Registration()),
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
                  _scaffoldKey.currentState?.openEndDrawer();
                  print(isowner);
                },
                icon: Icon(Icons.menu),
              ),
            ],
          )
        ],
      ),
      endDrawer: isowner?Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('Sidebar'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            Column(
              children: <Widget>[
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    textedit = textEditingValue.text;
                    if (textEditingValue.text == '') {
                      textedit = textEditingValue.text;
                      return const Iterable<String>.empty();

                    }
                    return allusers.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    selectedemail = selection;
                    textedit = selection;
                  },
                ),
                IconButton(
                    onPressed: (){
                      String emailToUse = selectedemail.isEmpty ? textedit : selectedemail;
                      if(emailToUse.isNotEmpty) {
                        _addCurrentUserToSelectedUserNotis(emailToUse);
                      }
                    },
                    icon: Icon(Icons.add)),
                Container(
                  height: 400,
                  child: StreamBuilder<DatabaseEvent>(
                    stream: familyStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Ошибка: ${snapshot.error}"));
                      } else if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                        return Center(child: Text("Данные отсутствуют"));
                      } else {
                        Map<dynamic, dynamic> values = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                        List<String> uids = values.keys.cast<String>().toList();
                        return ListView.builder(
                          itemCount: uids.length,
                          itemBuilder: (context, index) {
                            return FutureBuilder<String>(
                              future: getUserNameeByUid(uids[index]),
                              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return ListTile(
                                    title: Text("Загрузка..."),
                                  );
                                } else if (snapshot.hasError) {
                                  return ListTile(
                                    title: Text("Ошибка: ${snapshot.error}"),
                                  );
                                } else {
                                  return ListTile(
                                    title: Text(snapshot.data ?? "Никнейм не найден"),
                                    onTap: (){
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
                                      },);
                                    },
                                  );

                                }
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),

              ],
            ),

          ],
        ),
      ):Drawer(
        child: Column(
          children: [
            Container(
              height: 700,
              child: StreamBuilder<List<UserNotification>>(
                stream: userNotisSubject.stream,
                builder: (BuildContext context, AsyncSnapshot<List<UserNotification>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Text('No data');
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final userNoti = snapshot.data![index];
                        return ListTile(
                          title: Text(userNoti.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () {
                                  acceptUser(userNoti.uid);
                                },
                              ),
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
          ],
        ),
      ),


      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [


                  const SizedBox(height: 0),

                  Container(
                    width: MediaQuery.of(context).size.width.clamp(0, 400),
                    height: MediaQuery.of(context).size.width.clamp(0, 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(67),
                      image: DecorationImage(
                        image: AssetImage('assets/images/KupimVmeste.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Добро пожаловать, ${user.email} ',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') {
                                return const Iterable<String>.empty();
                              }
                              return allProducts.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (String selection) {

                              String category = productsByCategory.keys.firstWhere(
                                    (k) => productsByCategory[k]!.contains(selection),
                                orElse: () => 'Категория не найдена',
                              );
                              // Обновляем текстовое поле категории
                              _categoryController.text = category;
                              selectedProductName = selection;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {

                              bool isWeb = MediaQuery.of(context).size.width >= 600;

                              Color borderColor =  Colors.black;

                              return Container(
                                height: 50,
                                width: isWeb? 500:double.infinity,
                                child: TextField(
                                  controller: controller,

                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black,width: 2),
                                    ),
                                    fillColor: Colors.grey.shade200,
                                    filled: true,
                                    hintText: 'Введите название продукта',
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  child: Container(
                                    width: 300,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(option),
                                          onTap: () {
                                            onSelected(option);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 25),
                        MyTextField(
                          controller: _categoryController,
                           needToValidate: true, hintText: 'Категория', obscureText: false,
                        ),
                        SizedBox(height: 25,),
                        MyTextField(
                          controller: _comment,
                            obscureText: false, needToValidate: true, hintText: 'Комментарий',
                        ),
                        SizedBox(height: 25,),
                        MyTextField(
                          controller: _discription, hintText: 'Описание', obscureText: false, needToValidate: true,

                        ),
                        SizedBox(height: 25,),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0),
                          child: Container(
                            width: MediaQuery.of(context).size.width >= 600? 500:double.infinity,
                            height: 50,
                            child: TextFormField(
                              controller: _dateController,
                              readOnly: true, // Makes the field not editable; tap only
                              decoration: InputDecoration(

                                labelStyle: TextStyle(color: Colors.grey[500]),
                                suffixIcon: Icon(Icons.calendar_today),
                                // Check if the device is a desktop or web to adjust border color
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color:   Colors.black ,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black,width: 2),
                                ),
                                fillColor: Colors.grey.shade200,
                                filled: true,
                                hintText: 'Выберите дату',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                              ),
                              onTap: () {
                                // Assuming _selectDate is a method that shows a date picker dialog
                                _selectDate(context);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 25,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Выберите фотографию вашего продукта'),

                            ElevatedButton(
                              onPressed: _pickFile,
                              child: Text(fileName ?? 'Файл не выбран'),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                      ],
                    ),
                  ),
                  SizedBox(height: 25,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                      onTap: (){
                        handleSubmit();
                        },
                          child: Container(
                            padding: const EdgeInsets.all(25),
                            margin: const EdgeInsets.symmetric(horizontal: 25),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "Вычислить и скачать",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(width: 20,),
                      MyButton1(text: 'Добавить в историю', onTap: () {  }, isActive: false,)
                    ],
                  ),
                  SizedBox(height: 20,),

                  // not a member? register now
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class MyButton extends StatelessWidget {
  const MyButton({super.key, required this.formKey, required this.onTap});
  final formKey;
  final void Function() onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
      },
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            "Вычислить и скачать",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class MyButton1 extends StatelessWidget {
  MyButton1({super.key, required this.onTap, required this.text, required this.isActive});
  final Function()? onTap;
  final String text;
  bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool needToValidate;

  const MyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.needToValidate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This condition checks if the device screen width is 600 or more, indicating desktop or large tablet.
    bool isWeb = MediaQuery.of(context).size.width >= 600;

    // Adjust border color based on the device type (desktop or mobile).
    Color borderColor =  Colors.black;  // Black for desktop, white for mobile.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        width: isWeb ? 500 : double.infinity, // Width adjustment based on the device type.
        height: 50,
        decoration: BoxDecoration(),
        child: TextFormField(
          validator: needToValidate
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'Вы не ввели данные!';
            }
            return null;
          }
              : null,
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor), // Dynamic border color.
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black,width: 2),
            ),
            fillColor: Colors.grey.shade200,
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}

class SquareTile extends StatelessWidget {
  final String imagePath;
  const SquareTile({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: Image.asset(
        imagePath,
        height: 40,
      ),
    );
  }
}

class Field extends StatelessWidget {
  Field({Key? key, required this.text, required this.controller, required this.needToValidate}) : super(key: key);
  final String text;
  final TextEditingController controller;
  final bool needToValidate;
  @override
  Widget build(BuildContext context) {
    return Column(children: [Padding(
      padding: const EdgeInsets.symmetric(horizontal: 37),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  color: Colors.blueGrey,),),
            ),
          ),
        ],
      ),
    ),
      SizedBox(height: 5,),
      MyTextField(
        controller: controller,
        hintText: 'Введите данные',
        obscureText: true,
        needToValidate: needToValidate,
      ),
      const SizedBox(height: 10),],);
  }
}
class UserNotification {
  final String uid;
  final String name;
  final String? email;

  UserNotification({required this.uid,required this.name, this.email});
}