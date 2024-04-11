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


  // text editing controllers
  final busNum = TextEditingController();

  final sprem = TextEditingController();

  final sts = TextEditingController();

  final N = TextEditingController();

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
      backgroundColor: Colors.grey[300],
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => resume()),
                              );
                            },
                            icon: Icon(Icons.history, color: Colors.black,),

                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),

                  // logo
                  Icon(Icons.directions_bus_rounded, size:200),

                  const SizedBox(height: 0),

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
                        Autocomplete<String>(
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
                        ),
                        SizedBox(height: 20),
                        // Текстовое поле для отображения выбранной категории
                        TextField(
                          controller: _categoryController,
                          readOnly: false, // Сделаем его только для чтения
                          decoration: InputDecoration(labelText: 'Категория'),
                        ),
                        SizedBox(height: 15,),
                        TextField(
                          controller: _comment,
                          readOnly: false, // Сделаем его только для чтения
                          decoration: InputDecoration(labelText: 'Комментарий'),
                        ),
                        SizedBox(height: 15,),
                        TextField(
                          controller: _discription,
                          readOnly: false, // Сделаем его только для чтения
                          decoration: InputDecoration(labelText: 'Описание'),
                        ),
                        SizedBox(height: 15,),
                        TextFormField(
                          controller: _dateController,
                          readOnly: false, // Сделаем его только для чтения, чтобы открыть диалоговое окно при касании
                          decoration: InputDecoration(
                            labelText: 'Выберите дату',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () {
                            _selectDate(context);
                          },
                        ),
                        SizedBox(height: 15,),
                        ElevatedButton(
                          onPressed: _pickFile,
                          child: Text('Выбрать файл'),
                        ),
                        SizedBox(height: 20),
                        Text(fileName ?? 'Файл не выбран'),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
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
  final controller;
  final String hintText;
  final bool obscureText;
  final bool needToValidate;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.needToValidate
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        validator: needToValidate ? (value) {
          if (value == null || value.isEmpty) {
            return 'Вы не ввели данные!';
          }
          return null;
        } : null,
        controller: controller,
        decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            fillColor: Colors.grey.shade200,
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500])),
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