import 'package:chat_app/models/User.dart';
import 'package:chat_app/services/FBService.dart';
import 'package:chat_app/services/database_helper.dart';
import 'package:chat_app/widgets/CustomAppbar.dart';
import 'package:flutter/material.dart';

import 'ChatScreen.dart';

class NewMessagePage extends StatefulWidget {
  @override
  _NewMessagePageState createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  FBService fb = FBService();
  List<Userr> searchUserList;
  List<Userr> userLists;
  DatabaseHelper databaseHelper = DatabaseHelper();
  Widget searchWidget;
  TextEditingController searchControler = TextEditingController();
  @override
  void initState() {
    super.initState();
    initPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppbarCustom(
          title: "Persons",
          backButton: true,
          centerWidget: searchWidget,
          rightWidget: GestureDetector(
            onTap: () {
              if (searchWidget == null) {
                searchWidget = TextField(
                  decoration: InputDecoration(hintText: "Search"),
                  controller: searchControler,
                  onChanged: (s) {
                    searchUserList = userLists
                        .where((element) => element.name
                            .toLowerCase()
                            .trim()
                            .contains(s.toLowerCase().trim()))
                        .toList();
                    setState(() {});
                  },
                );
              } else {
                searchControler.text = "";
                searchWidget = null;
                searchUserList = userLists;
              }
              setState(() {});
            },
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 24,
              child: Icon(
                Icons.search,
                color: Colors.orange,
              ),
            ),
          ),
        ),
        body: searchUserList == null
            ? Center(child: CircularProgressIndicator())
            : searchUserList.length == 0
                ? Center(
                    child: Text("Not Found."),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                    child: ListView.builder(
                        itemCount: searchUserList.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          return ListTile(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                        receiverid:
                                            searchUserList[index].userid)),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundImage: searchUserList[index]
                                      .photoUrl
                                      .isNotEmpty
                                  ? NetworkImage(searchUserList[index].photoUrl)
                                  : AssetImage('assets/images/profil.jpg'),
                            ),
                            title: Text(searchUserList[index].name ??
                                searchUserList[index].phone),
                          );
                        }),
                  ));
  }

  Future<void> initPage() async {
    fb.syncUsers().then((value) async {
      userLists = await databaseHelper.getAllUserrs();
      searchUserList = userLists
          .where((element) => element.name
              .toLowerCase()
              .trim()
              .contains(searchControler.text.trim().toLowerCase()))
          .toList();
      setState(() {});
    });
    userLists = await databaseHelper.getAllUserrs();
    searchUserList = userLists
        .where((element) => element.name
            .toLowerCase()
            .trim()
            .contains(searchControler.text.trim().toLowerCase()))
        .toList();
    setState(() {});
  }
}
