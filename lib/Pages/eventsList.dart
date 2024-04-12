import 'dart:html';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:table_calendar/table_calendar.dart';
import 'package:tswcd/Pages/EcentPage.dart';

import '../main.dart';
import 'Registration_page.dart';
class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isowner = false;
  DatabaseReference? databaseReference;
  String currentUseruid = "";
  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    currentUseruid = _auth.currentUser!.uid;
    isCurrentUserOwner();
    if (currentUser != null) {
      databaseReference = FirebaseDatabase.instance.reference().child('products/${currentUser.uid}');
    }
  }
  Future<String> getImageUrl(String imagePath) async {
    String imageUrl = await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    return imageUrl;
  }
  String owneruid = "";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            ],
          )
        ],
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
                crossAxisCount: 6, // Количество столбцов
                childAspectRatio: 1, // Соотношение сторон плитки
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                var id = ids[index];
                var imageRef = "products/${owneruid}/${ids[index]}/image";


                return GestureDetector(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventDetailsPage(startDate: product["date"], title: product["name"], type: product["category"], smallDescription: product["comment"], largeDescription: product["description"], imageurl: product["imageUrl"], uid: ids[index],  owner: owneruid,)),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем содержимое на всю ширину карточки
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
                              CheckedButton(owner: owneruid,id:ids[index],counts: product["count"],), // Проверяем isOwner и добавляем CheckedButton, если он равен false
                            ],
                          ),
                        ),
                      ],
                    ),
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


class CheckedButton extends StatefulWidget {
  String owner;
  String id;
  int counts;
  CheckedButton({required this.owner,required this.id,required this.counts});
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
              databaseReference!.child(path).remove();
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
            child: Icon(
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
