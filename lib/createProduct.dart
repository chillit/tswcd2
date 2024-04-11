import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; // Для Uint8List
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file/memory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tswcd/Pages/Registration_page.dart';
class resume extends StatefulWidget {

  resume({super.key});

  @override
  State<resume> createState() => _resumeState();
}

class _resumeState extends State<resume> {
  final user = FirebaseAuth.instance.currentUser!;




  // sign user in method
  void signUserIn() {}
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
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _comment = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _discription = TextEditingController();


  @override
  void dispose() {
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }
  Uint8List? fileBytes;
  String? fileName;

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
  Future<bool> sendDataToDatabase(String? name, String category, String comment, String description, String date, Uint8List fileData, String fileName) async {
    final databaseRef = FirebaseDatabase.instance.ref();
    final id = DateTime.now().millisecondsSinceEpoch.toString(); // Простой способ генерации уникального ID
    final productRef = databaseRef.child('products/${FirebaseAuth.instance.currentUser!.uid}/$id');

    try {
      // Сначала загружаем файл в Firebase Storage и получаем URL изображения
      final ref = FirebaseStorage.instance.ref('products/${FirebaseAuth.instance.currentUser!.uid}/$id/image');
      final result = await ref.putData(fileData);
      final imageUrl = await result.ref.getDownloadURL();

      // Затем сохраняем данные продукта вместе с URL изображения в Firebase Realtime Database
      await productRef.set({
        'name': name,
        'category': category,
        'comment': comment,
        'description': description,
        'date': date,
        'imageUrl': imageUrl, // Сохраняем URL изображения
      });
      return true;
    } catch (e) {
      print(e);
      return false;

    }
  }


  // Определяем GlobalKey для формы





  late List<String> allusers = [];
  late List<String> users = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();
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
              users.add(value["name"]);
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
    _fetchUsers();
  }
  late List<String> filteredUsers = [];
  String? selectedUser;

  String? validateProduct(String? value) {
    if (selectedProductName == null || selectedProductName!.isEmpty) {
      return "Пожалуйста, выберите продукт";
    }
    return null;
  }
  bool isFilePicked = false;  // Добавляем флаг для отслеживания выбора файла

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      try {
        setState(() {
          fileBytes = result.files.first.bytes;
          fileName = result.files.first.name;
          isFilePicked = true;  // Файл выбран
        });
      } catch (e) {
        print('Error processing file picker result: $e');
      }
    } else {
      setState(() {
        isFilePicked = false;  // Файл не выбран
      });
      print('File picker result is null');
    }
  }

  bool isLoading = false;  // Состояние для отслеживания загрузки

  Future<void> handleSubmit(BuildContext context) async {
    if (_formKey.currentState!.validate() && isFilePicked) {
      String? productValidationResult = validateProduct(selectedProductName);
      if (productValidationResult == null) {
        if (fileBytes != null && fileName != null) {
          setState(() {
            isLoading = true;  // Начинаем показ индикатора загрузки
          });
          try {
            bool success = await sendDataToDatabase(selectedProductName!, _categoryController.text, _comment.text, _discription.text, _dateController.text, fileBytes!, fileName!);
            if (success) {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.bottomSlide,
                title: 'Успех',
                desc: 'Товар успешно добавлен!',
                btnOkOnPress: () {},
              )..show();
              _categoryController.clear();
              _comment.clear();
              _discription.clear();
              _dateController.clear();
            } else {
              // Обработка неудачной отправки данных
            }
          } finally {
            setState(() {
              isLoading = false;  // Заканчиваем показ индикатора загрузки
            });
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пожалуйста, выберите файл перед добавлением товара!'))
      );
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isNotEmpty) {
        filteredUsers = allusers.where((user) => user.contains(query)).toList();
      } else {
        filteredUsers = List.from(users);
      }
    });
  }
  Future<String> getUserIdByEmail(String userEmail) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    String userId = '';

    // Предполагается, что структура ваших данных позволяет вам искать по электронной почте напрямую.
    // Если нет, вам может потребоваться использовать другой подход, например, сначала получить все email и искать среди них.
    final query = databaseReference.child('users').orderByChild('email').equalTo(userEmail);
    DataSnapshot snapshot = await query.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
      // Получаем первый ключ, так как orderByChild + equalTo даст нам объект с одним ключом, если email уникален.
      userId = users.keys.first as String;
    } else {
      print("No user found for the provided email");
    }

    return userId;
  }
  Future<void> _addCurrentUserToSelectedUserNotis(String userEmail) async {
    // Предположим, что у вас есть способ получения идентификатора пользователя по его электронной почте.
    // Это может потребовать дополнительного запроса к вашей базе данных.
    String userId = await getUserIdByEmail(userEmail); // Эту функцию нужно реализовать самостоятельно

    if (userId.isNotEmpty) {
      final databaseReference = FirebaseDatabase.instance.ref();
      databaseReference.child('users/$userId/notis/${user.uid}').set(true).then((_) {
        print("Current user UID added successfully to selected user's notis");
      }).catchError((error) {
        print("Failed to add current user UID: $error");
      });
    }
  }
  String selectedemail = "";
  bool isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  String? selectedProductName;
  @override
  Widget build(BuildContext context) {
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
                  _scaffoldKey.currentState?.openEndDrawer(); // Open the end drawer
                },
                icon: Icon(Icons.menu), // Change the icon as needed
              ),
            ],
          )
        ],
      ),
      endDrawer: Drawer(
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
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return allusers.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    selectedemail = selection;
                  },
                ),
                IconButton(
                    onPressed: (){
                      _addCurrentUserToSelectedUserNotis(selectedemail);
                    },
                    icon: Icon(Icons.add))
              ],
            ),
            for (var user in users)
              ListTile(
                title: Text(user),
                onTap: () {
                  // Handle tapping on the user item
                },
              ),
          ],
        ),
      ),


      body: isLoading?Center(child: CircularProgressIndicator()):SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [


                  const SizedBox(height: 0),

                  // logo
                  Container(
                    width: MediaQuery.of(context).size.width.clamp(0, 400),
                    height: MediaQuery.of(context).size.width.clamp(0, 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(67), // Adjust the radius as per your requirement
                      image: DecorationImage(
                        image: AssetImage('assets/images/KupimVmeste.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // welcome back, you've been missed!
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
                              // Находим категорию для выбранного продукта
                              String category = productsByCategory.keys.firstWhere(
                                    (k) => productsByCategory[k]!.contains(selection),
                                orElse: () => 'Категория не найдена',
                              );
                              // Обновляем текстовое поле категории
                              _categoryController.text = category;
                              selectedProductName = selection;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              // This condition checks if the device screen width is 600 or more, indicating desktop or large tablet.
                              bool isWeb = MediaQuery.of(context).size.width >= 600;

                              // Adjust border color based on the device type (desktop or mobile).
                              Color borderColor =  Colors.black; // Black for desktop, white for mobile.

                              return Container(
                                height: 50,
                                width: isWeb? 500:double.infinity,
                                child: TextField(
                                  controller: controller,

                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: borderColor), // Dynamic border color based on the device type.
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black,width: 2),
                                    ),
                                    errorBorder:  OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red, width: 2),
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
                                    width: 300, // Adjust the width as needed
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
                        // Текстовое поле для отображения выбранной категории
                        MyTextField(
                          controller: _categoryController,
                           needToValidate: true, hintText: 'Категория', obscureText: false,
                        ),
                        SizedBox(height: 25,),
                        MyTextField(
                          controller: _comment,
                            obscureText: false, needToValidate: false, hintText: 'Комментарий',
                        ),
                        SizedBox(height: 25,),
                        MyTextField(
                          controller: _discription, hintText: 'Описание', obscureText: false, needToValidate: false,

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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Assuming a width threshold of 600 to differentiate between mobile and desktop
                            bool isDesktop = constraints.maxWidth >= 600;

                            return Center( // This will center the content on desktops
                              child: Container(

                                width: isDesktop ? 600 : null, // Adjust the width as needed for desktop layout
                                child: Row(
                                  mainAxisAlignment: isDesktop ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(width: isDesktop?0:25,),

                                    Text('Выберите фотографию вашего продукта'),
                                    SizedBox(width: isDesktop?25:0),
                                    ElevatedButton(
                                      onPressed: _pickFile,
                                      child: Text(fileName == null? 'Файл не выбран': "Файл выбран",style:
                                      TextStyle(color:  isFilePicked ? Colors.green : Colors.purple ),),
                                    ),
                                    SizedBox(width: isDesktop?0:25,),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),

                      ],
                    ),
                  ),
                  SizedBox(height: 25,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          handleSubmit(context);
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
              borderSide: BorderSide(color: borderColor),
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