import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; // Для Uint8List
import 'package:file_picker/file_picker.dart';
import 'package:file/memory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        fileBytes = result.files.first.bytes; // Сохраняем байты файла
        fileName = result.files.first.name; // Сохраняем имя файла
      });
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
    final id = DateTime.now().millisecondsSinceEpoch.toString(); // Простой способ генерации уникального ID
    final productRef = databaseRef.child('products/${FirebaseAuth.instance.currentUser!.uid}/$id');

    try {
      // Сначала загружаем файл в Firebase Storage и получаем URL изображения
      final ref = FirebaseStorage.instance.ref('products/${FirebaseAuth.instance.currentUser!.uid}/$id/$fileName');
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
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> handleSubmit() async {
    if (fileBytes != null && fileName != null) {
      await sendDataToDatabase(selectedProductName,_categoryController.text, _comment.text, _discription.text, _dateController.text, fileBytes!, fileName!);
      // Очистите контроллеры или покажите сообщение об успехе
    }
  }
  final _formKey = GlobalKey<FormState>();
  String? selectedProductName;
  @override
  Widget build(BuildContext context) {
    List<String> allProducts = productsByCategory.values.expand((list) => list).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          IconButton(
                              onPressed: (){
                                FirebaseAuth.instance.signOut();
                              },
                              icon: Icon(Icons.logout)),
                          SizedBox(width: 10,),
                          IconButton(
                            onPressed: (){
                            },
                            icon: Icon(Icons.history, color: Colors.black,),

                          ),
                        ],
                      ),
                    ),
                  ),
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