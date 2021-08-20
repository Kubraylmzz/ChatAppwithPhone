import 'dart:async';
import 'dart:io';

import 'package:badges/badges.dart';
import 'package:chat_app/models/ChatListModel.dart';
import 'package:chat_app/models/User.dart';
import 'package:chat_app/screens/ChatScreen.dart';
import 'package:chat_app/screens/NewMessagePage.dart';
import 'package:chat_app/screens/UserProfil.dart';
import 'package:chat_app/services/FBService.dart';
import 'package:chat_app/services/database_helper.dart';
import 'package:chat_app/widgets/CustomAppbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MyChatRooms extends StatefulWidget {
  MyChatRooms(this.userid);
  final String userid;

  @override
  _MyChatRoomsState createState() => _MyChatRoomsState();
}

class _MyChatRoomsState extends State<MyChatRooms> {
  var currentUser = FirebaseAuth.instance.currentUser;
  Userr user;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _streamListener;
  StreamSubscription<String> tokenListener;
  FBService fbService = FBService();
  List<ChatListModel> searchChatList;
  List<ChatListModel> chatList;
  Widget searchWidget;
  TextEditingController searchControler = TextEditingController();
  DatabaseHelper db = DatabaseHelper();
  @override
  void initState() {
    super.initState();
    fbService.syncUsers().then((value) async {
      _setLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (searchChatList == null || user == null)
      return Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.grey,
        ),
      );
    else
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewMessagePage(),
                ));
            _setLayout();
          },
          child: Icon(Icons.message),
          backgroundColor: Colors.orange[400],
        ),
        appBar: AppbarCustom(
          title: "Messages",
          centerWidget: searchWidget,
          rightWidget: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (searchWidget == null) {
                    searchWidget = TextField(
                      decoration: InputDecoration(hintText: "Search"),
                      controller: searchControler,
                      onChanged: (s) {
                        searchChatList = chatList
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
                    searchChatList = chatList;
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
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfil(),
                      ));
                },
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 24,
                  child: Icon(
                    Icons.person,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          backgroundColor: Colors.lightBlue,
          child: ListView.builder(
            itemBuilder: (context, i) {
              return ListTile(
                onLongPress: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text("Dikkat!"),
                        content: Text(searchChatList[i].name +
                            "\nile olan görüşmeyi silmek istediğinizden emin misiniz?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () async {
                              await db.deleteChat(searchChatList[i].userid);
                              _setLayout();
                              Navigator.pop(context);
                            },
                            child: Text("Evet"),
                          ),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Hayır")),
                        ],
                      );
                    },
                  );
                },
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ChatScreen(receiverid: searchChatList[i].userid)),
                  );
                  _setLayout();
                },
                title: Text(searchChatList[i].name),
                leading: CircleAvatar(
                  backgroundImage: searchChatList[i].photoUrl.isNotEmpty
                      ? NetworkImage(searchChatList[i].photoUrl)
                      : AssetImage('assets/images/profil.jpg'),
                ),
                trailing: int.tryParse(searchChatList[i].read ?? "0") > 0
                    ? Badge(
                        badgeColor: Colors.orange,
                        badgeContent: Text(searchChatList[i].read),
                        child: Icon(Icons.message, size: 30),
                      )
                    : null,
              );
            },
            itemCount: searchChatList.length,
          ),
          onRefresh: () {
            return _setLayout();
          },
        ),
      );
  }

  @override
  void dispose() {
    if (_streamListener != null) _streamListener.cancel();
    tokenListener.cancel();
    super.dispose();
  }

  Future<void> _setLayout() async {
    tokenListener =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .doc("users/" + currentUser.uid)
            .update({"token": newToken});
        print("new Token: $newToken");
      }
    });
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .doc("users/" + currentUser.uid)
          .update({"token": await FirebaseMessaging.instance.getToken()});
      print("new Token: ${await FirebaseMessaging.instance.getToken()}");
    }
    tokenListener.resume();
    //await TestNotify().initializeFCMNotification(context);
    if (await Permission.contacts.request().isGranted &&
        await Permission.camera.request().isGranted &&
        await Permission.storage.request().isGranted) {
      searchChatList = await db.getMyChatRooms(widget.userid);
      chatList = searchChatList;
      setState(() {});
      var ref = FirebaseFirestore.instance
          .collection("messagesTemp")
          .doc(widget.userid);
      user = await fbService.currentUser();
      _streamListener = ref.snapshots().listen((event) async {
        searchChatList = await db.getMyChatRooms(widget.userid);
        chatList = searchChatList;
        setState(() {});
      });
    } else {
      exit(0);
    }
  }
}
