import 'dart:async';
import 'dart:io';

import 'dart:typed_data'; // Для Uint8List
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:async';

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
import 'package:tswcd/Pages/eventsList.dart';
import 'package:tswcd/main.dart';
class resume extends StatefulWidget {
  final bool? from;
  resume({this.from});

  @override
  State<resume> createState() => _resumeState();
}

class _resumeState extends State<resume> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _comment = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discription = TextEditingController();
  final TextEditingController count = TextEditingController();
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
  bool isalter = false;
  Product? selectedowner;
  List<Product> products = [];
  Stream<List<UserNotification>> getUserNotisStreamm(String uid) {
    return _controller.stream;
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
  void updateUserNotisStream(String uid) {
    getUserNotisStream(uid).listen((data) {
      userNotisSubject.add(data);
    });
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

  Future<bool> sendDataToDatabase(String? name, String category, String comment, String description, String date, Uint8List fileData, String fileName,int count) async {
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
        'count': count,
        "alter":""
      });
      return true;
    } catch (e) {
      print(e);
      return false;

    }
  }
  Future<bool> sendDataToDatabasealter(String? name, String category, String comment, String description, String date, Uint8List fileData, String fileName,int count,String owneruid) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final productRef = databaseRef.child('products/${FirebaseAuth.instance.currentUser!.uid}/$owneruid/alter/${id}');

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
        'count': count,
        "alter":""
      });
      return true;
    } catch (e) {
      print(e);
      return false;

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
  void loadUserNotis() async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid != null) {
      List<UserNotification> uids = await getUserNotisInfo(userUid);
      setState(() {
        userUids = uids;
      });
    }
  }
  bool _loading = false;
  void initState() {

    super.initState();
    isCurrentUserOwner();
    widget.from!?_startLoading():null;
    updateUserNotisStream(user.uid);
    _fetchUsers();
    loadUserNotis();

    fetchProducts();
  }
  void _startLoading() async {
    _loading = true;
    // Wait for 1 second
    await Future.delayed(Duration(seconds: 2));
    // Change the state to hide CircularProgressIndicator
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
  Future<void> fetchProducts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    DatabaseReference ref = FirebaseDatabase.instance.ref('products/$uid');
    DatabaseEvent event = await ref.once();

    if (event.snapshot.exists) {
      final productsData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      productsData.forEach((key, data) {
        products.add(Product(name: data["name"], imageUrl: data["imageUrl"], owner: key));
      });
    }
    print(products);
  }

  Future<void> handleSubmit() async {
    if (fileBytes != null && fileName != null) {
      await sendDataToDatabase(
          selectedProductName,
          _categoryController.text,
          _comment.text,
          _discription.text,
          _dateController.text,
          fileBytes!,
          fileName!,
          int.parse(count.text));}}


      String? validateProduct(String? value) {
        if (selectedProductName == null || selectedProductName!.isEmpty) {
          return "Пожалуйста, выберите продукт";
        }
        return null;
      }
      bool isFilePicked = false; // Добавляем флаг для отслеживания выбора файла

      Future<void> _pickFile() async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.image);

        if (result != null) {
          try {
            setState(() {
              fileBytes = result.files.first.bytes;
              fileName = result.files.first.name;
              isFilePicked = true; // Файл выбран
            });
          } catch (e) {
            print('Error processing file picker result: $e');
          }
        } else {
          setState(() {
            isFilePicked = false; // Файл не выбран
          });
          print('File picker result is null');
        }
      }

      bool isLoading = false; // Состояние для отслеживания загрузки
  Future<void> handleSubmitAnim(BuildContext context) async {
    if (_formKey.currentState!.validate() && isFilePicked) {
      String? productValidationResult = validateProduct(
          selectedProductName);
      if (productValidationResult == null) {
        if (fileBytes != null && fileName != null) {
          setState(() {
            isLoading = true; // Начинаем показ индикатора загрузки
          });
          try {
            bool success = await sendDataToDatabase(
                selectedProductName!,
                _categoryController.text,
                _comment.text,
                _discription.text,
                _dateController.text,
                fileBytes!,
                fileName!,
                int.parse(count.text)
            );
            if (success) {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.bottomSlide,
                title: 'Успех',
                desc: 'Товар успешно добавлен!',
                btnOkOnPress: () {

                },
                width: MediaQuery.of(context).size.width>=600?600:MediaQuery.of(context).size.width
              )
                ..show();
              _categoryController.clear();
              _comment.clear();
              _discription.clear();
              _dateController.clear();
              count.clear();
            } else {
              // Обработка неудачной отправки данных
            }
          } finally {
            setState(() {
              isLoading = false; // Заканчиваем показ индикатора загрузки
            });
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Пожалуйста, выберите файл перед добавлением товара!'))
      );
    }
  }


  Future<void> handleSubmitAnimalter(BuildContext context,String owner) async {
    if (_formKey.currentState!.validate() && isFilePicked) {
      String? productValidationResult = validateProduct(
          selectedProductName);
      if (productValidationResult == null) {
        if (fileBytes != null && fileName != null) {
          setState(() {
            isLoading = true; // Начинаем показ индикатора загрузки
          });
          try {
            bool success = await sendDataToDatabasealter(

                selectedProductName!,
                _categoryController.text,
                _comment.text,
                _discription.text,
                _dateController.text,
                fileBytes!,
                fileName!,
                int.parse(count.text),
              owner
            );
            if (success) {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.bottomSlide,
                title: 'Успех',
                desc: 'Товар успешно добавлен!',
                btnOkOnPress: () {

                },
                  width: MediaQuery.of(context).size.width>=600?600:MediaQuery.of(context).size.width

              )
                ..show();
              _categoryController.clear();
              _comment.clear();
              _discription.clear();
              _dateController.clear();
            } else {
              // Обработка неудачной отправки данных
            }
          } finally {
            setState(() {
              isLoading = false; // Заканчиваем показ индикатора загрузки
            });
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Пожалуйста, выберите файл перед добавлением товара!'))
      );
    }
  }

      void _filterUsers(String query) {
        setState(() {
          if (query.isNotEmpty) {
            filteredUsers =
                allusers.where((user) => user.contains(query)).toList();
          } else {
            filteredUsers = List.from(users);
          }
        });
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
      Future<void> _addCurrentUserToSelectedUserNotis(String userEmail) async {
        String userId = await getUserIdByEmail(userEmail);

        if (userId.isNotEmpty) {
          final databaseReference = FirebaseDatabase.instance.ref();
          databaseReference.child('users/$userId/notis/${user.uid}')
              .set(true)
              .then((_) {
            print(
                "Current user UID added successfully to selected user's notis");
          }).catchError((error) {
            print("Failed to add current user UID: $error");
          });
        }
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
      Future<void> removeUserOwner(String userUid) async {
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? currentUser = auth.currentUser;
        final databaseReference = FirebaseDatabase.instance.ref();
        await databaseReference.child('users/$userUid/owner').set("");
        await databaseReference.child(
            'users/${currentUser!.uid}/family/${userUid}').remove();
        print("User $userUid owner removed");
      }
      Future<UserNotification> getUserNameeByUid(String uid) async {
        final databaseReference = FirebaseDatabase.instance.ref();
        DataSnapshot nameSnapshot = await databaseReference.child('users/$uid/name').get();
        DataSnapshot emailSnapshot = await databaseReference.child('users/$uid/email').get();

        String name = nameSnapshot.exists ? nameSnapshot.value as String : 'Имя не найдено';
        String email = emailSnapshot.exists ? emailSnapshot.value as String : 'Email не найден';

        return UserNotification(uid:uid,name: name, email: email);
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
        Stream<DatabaseEvent> familyStream = database
            .ref("users/${currentUser.uid}/family")
            .onValue;
        List<String> allProducts = productsByCategory.values.expand((
            list) => list).toList();
        return _loading ? Center(child: CircularProgressIndicator()) :Scaffold(
          floatingActionButton: isowner?FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductList()),
              );
              print('Button Pressed!');
            },
            child: Icon(Icons.shopping_cart),

          ):null,

          backgroundColor: Colors.white,

          key: _scaffoldKey,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyHomePage()),
                );
              },
              icon: Icon(Icons.logout),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  _fetchUsers();
                  _scaffoldKey.currentState?.openEndDrawer();
                  print(isowner);
                },
                icon: Icon(Icons.menu),
              )
            ],
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
                                        subtitle: Text(snapshot.data!.email ?? ""),
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
                  height: MediaQuery.of(context).size.height*0.7,
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
              ],
            ),
          ),


          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: SafeArea(
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const SizedBox(height: 0),

                      Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width>=400?400:MediaQuery.of(context).size.width *0.7,
                        height: MediaQuery
                            .of(context)
                            .size
                            .width>=400?400:MediaQuery.of(context).size.width *0.7,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25.0),
                              child: Autocomplete<String>(
                                optionsBuilder: (
                                    TextEditingValue textEditingValue) {
                                  if (textEditingValue.text == '') {
                                    return const Iterable<String>.empty();
                                  }
                                  return allProducts.where((String option) {
                                    return option.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase());
                                  });
                                },
                                onSelected: (String selection) {
                                  String category = productsByCategory.keys
                                      .firstWhere(
                                        (k) =>
                                        productsByCategory[k]!.contains(
                                            selection),
                                    orElse: () => 'Категория не найдена',
                                  );
                                  // Обновляем текстовое поле категории
                                  _categoryController.text = category;
                                  selectedProductName = selection;
                                },
                                fieldViewBuilder: (context, controller,
                                    focusNode, onFieldSubmitted) {
                                  bool isWeb = MediaQuery
                                      .of(context)
                                      .size
                                      .width >= 600;

                                  Color borderColor = Colors.black;

                                  return Container(
                                    height: 50,
                                    width: isWeb ? 500 : double.infinity,
                                    child: TextField(
                                      controller: controller,

                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: borderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.black, width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 2),
                                        ),
                                        fillColor: Colors.grey.shade200,
                                        filled: true,
                                        hintText: 'Введите название продукта',
                                        hintStyle: TextStyle(
                                            color: Colors.grey[500]),
                                      ),
                                    ),
                                  );
                                },
                                optionsViewBuilder: (context, onSelected,
                                    options) {
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
                                            final option = options.elementAt(
                                                index);
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
                              needToValidate: true,
                              hintText: 'Категория',
                              obscureText: false,
                            ),
                            SizedBox(height: 25,),
                            MyTextField(
                              controller: _comment,
                              obscureText: false,
                              needToValidate: false,
                              hintText: 'Комментарий',
                            ),
                            SizedBox(height: 25,),
                            MyTextField(
                              controller: _discription,
                              hintText: 'Описание',
                              obscureText: false,
                              needToValidate: false,

                            ),
                            SizedBox(height: 25,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Container(
                      width:  MediaQuery.of(context).size.width>=600? 500 : double.infinity, // Width adjustment based on the device type.
                      constraints: BoxConstraints(minHeight: 50), // Устанавливаем минимальную высоту для контейнера
                      decoration: BoxDecoration(),
                      child: TextFormField(
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*$'))],
                        validator: true
                            ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Это поле обязательно!!'; // Возвращает пустую строку вместо текста ошибки
                          }
                          return null;
                        }
                            : null,
                        controller: count,
                        obscureText: false,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10.0).copyWith(left: 10.0), // Настройка внутренних отступов
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black,width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                          fillColor: Colors.grey.shade200,
                          filled: true,
                          hintText: 'Введите кол-во проудкта',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          errorStyle: TextStyle(height: 0, color: Colors.red), // Скрываем текст ошибки
                        ),
                      ),
                    ),
                  ),
                            SizedBox(height: 25,),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 25.0),
                              child: Container(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width >= 600 ? 500 : double.infinity,
                                height: 50,
                                child: TextFormField(
                                  controller: _dateController,
                                  readOnly: true,
                                  // Makes the field not editable; tap only
                                  decoration: InputDecoration(

                                    labelStyle: TextStyle(
                                        color: Colors.grey[500]),
                                    suffixIcon: Icon(Icons.calendar_today),
                                    // Check if the device is a desktop or web to adjust border color
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.black, width: 2),
                                    ),
                                    fillColor: Colors.grey.shade200,
                                    filled: true,
                                    hintText: 'Выберите дату',
                                    hintStyle: TextStyle(
                                        color: Colors.grey[500]),
                                  ),
                                  onTap: () {
                                    // Assuming _selectDate is a method that shows a date picker dialog
                                    _selectDate(context);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 25,),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Assuming a width threshold of 600 to differentiate between mobile and desktop
                                bool isDesktop = constraints.maxWidth >= 600;

                                return Center( // This will center the content on desktops
                                  child: Container(

                                    width: isDesktop ? 600 : null,
                                    // Adjust the width as needed for desktop layout
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: isDesktop ? 0 : 25,),

                                        Text(
                                            'Выберите фотографию'),
                                        SizedBox(width:  25),
                                        ElevatedButton(
                                          onPressed: _pickFile,
                                          child: Text( isFilePicked
                                              ? 'Файл выбран'
                                              : "Файл не выбран", style:
                                          TextStyle(color: isFilePicked
                                              ? Colors.green
                                              : Colors.purple)),
                                        ),
                                        SizedBox(width: isDesktop ? 0 : 25,),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Есть ли этому товару альтернатива?'),
                                SizedBox(width: 5,),
                                Switch(
                                  value: isalter,
                                  onChanged: (value) {
                                    setState(() {
                                      isalter = value;
                                    });
                                  },
                                  activeTrackColor: Colors.lightGreenAccent,
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                            SizedBox(height: isalter?15:0),
                            isalter?Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 1.0), // Add border decoration
                                borderRadius: BorderRadius.circular(5.0), // Optional: Add border radius for rounded corners
                              ),
                              child: DropdownButton<Product>(
                                value: selectedowner,
                                onChanged: (Product? newValue) {
                                  setState(() {
                                    selectedowner = newValue;
                                  });
                                },
                                items: products.map<DropdownMenuItem<Product>>((Product product) {
                                  return DropdownMenuItem<Product>(
                                    value: product,
                                    child: Row(
                                      children: <Widget>[
                                        Image.network(product.imageUrl, width: 50, height: 50),
                                        SizedBox(width: 10),
                                        Text(product.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                                :SizedBox(),
                          ],
                        ),
                      ),
                      SizedBox(height: 25,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              isalter?handleSubmitAnimalter(context,selectedowner!.owner):handleSubmitAnim(context);
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.black, // Background color
                              padding: const EdgeInsets.all(25),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "ДОБАВИТЬ ТОВАР",
                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 30,)


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
class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool needToValidate;
  final String? Function(String?)? validator;

  const MyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.needToValidate,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This condition checks if the device screen width is 600 or more, indicating desktop or large tablet.
    bool isWeb = MediaQuery.of(context).size.width >= 600;

    // Adjust border color based on the device type (desktop or mobile).
    Color borderColor = Colors.black; // Initially black for desktop

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        width: isWeb ? 500 : double.infinity, // Width adjustment based on the device type.
        constraints: BoxConstraints(minHeight: 50), // Устанавливаем минимальную высоту для контейнера
        decoration: BoxDecoration(),
        child: TextFormField(
          validator: needToValidate
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'Это поле обязательно!!'; // Возвращает пустую строку вместо текста ошибки
            }
            return null;
          }
              : null,
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 10.0).copyWith(left: 10.0), // Настройка внутренних отступов
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor,width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            fillColor: Colors.grey.shade200,
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            errorStyle: TextStyle(height: 0, color: Colors.red), // Скрываем текст ошибки
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
class Product {
  final String name;
  final String imageUrl;
  final String owner;

  Product({required this.name, required this.imageUrl,required this.owner});
}