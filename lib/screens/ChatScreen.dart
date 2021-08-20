import 'dart:async';
import 'dart:io';

import 'package:chat_app/models/Message.dart';
import 'package:chat_app/models/User.dart';
import 'package:chat_app/services/FBService.dart';
import 'package:chat_app/services/FileTypeHelper.dart';
import 'package:chat_app/services/database_helper.dart';
import 'package:chat_app/widgets/CustomAppbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_icon/file_icon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  ChatScreen({this.receiverid});
  final String receiverid;
  @override
  _ChatScreenState createState() => _ChatScreenState(receiverid);
}

class _ChatScreenState extends State<ChatScreen> {
  _ChatScreenState(this.receiverid);
  DatabaseHelper databaseHelper = DatabaseHelper();
  FBService fbService = FBService();
  Userr currentUser;
  Userr receiverUser;
  String receiverid;
  List<Message> searchAllMessage;
  List<Message> allMessages;
  TextEditingController _messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  File file;
  StreamSubscription<QuerySnapshot> _streamListener;
  bool sendFileinMessage = false;
  Widget searchWidget;
  TextEditingController searchControler = TextEditingController();
  @override
  void initState() {
    super.initState();
    _setChatScreen();
    fbService.syncUsers().then((value) async {
      _setChatScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (receiverUser == null || currentUser == null)
      return Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.grey,
        ),
      );
    else
      return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppbarCustom(
            backButton: true,
            title: receiverUser.name.isNotEmpty
                ? receiverUser.name
                : receiverUser.phone,
            circleAvatarinLeftButton: CircleAvatar(
              radius: 20,
              backgroundImage: receiverUser.photoUrl.isNotEmpty
                  ? NetworkImage(receiverUser.photoUrl)
                  : AssetImage('assets/images/profil.jpg'),
            ),
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
                          if (s.length > 2) {
                            // arama için en az 3 karakter zorunluluğu
                            searchAllMessage = allMessages
                                .where((element) => element.message
                                    .toLowerCase()
                                    .trim()
                                    .contains(s.toLowerCase().trim()))
                                .toList();
                          } else {
                            searchAllMessage = allMessages;
                          }
                          setState(() {});
                        },
                      );
                    } else {
                      searchControler.text = "";
                      searchWidget = null;
                      searchAllMessage = allMessages;
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
                TextButton(
                    onPressed: () async {
                      file = File((await FilePicker.platform.pickFiles())
                          .files
                          .first
                          .path);
                      if (file != null) {
                        setState(() {});
                      }
                    },
                    child: Icon(AntDesign.addfile, color: Colors.orange))
              ],
            ),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              file != null
                  ? !sendFileinMessage
                      ? (([".jpg", ".png", ".jpeg"].contains(file.path
                              .substring(file.path.lastIndexOf('.'))
                              .toLowerCase()))
                          ? Expanded(
                              child: GestureDetector(
                              onTap: () async {
                                await OpenFile.open(file.path,
                                    type: FileTypeHelper().extentionToType(
                                        file.path.substring(
                                            file.path.lastIndexOf("."))));
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(child: Image.file(file)),
                                  Text(
                                    file.path.substring(
                                        file.path.lastIndexOf("/") + 1),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            ))
                          : Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  await OpenFile.open(file.path,
                                      type: FileTypeHelper().extentionToType(
                                          file.path.substring(
                                              file.path.lastIndexOf("."))));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: FileIcon(
                                        file.path.substring(
                                            file.path.lastIndexOf('.')),
                                        size: 100,
                                      ),
                                    ),
                                    Text(
                                      file.path.substring(
                                          file.path.lastIndexOf("/") + 1),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ),
                            ))
                      : Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Center(child: CircularProgressIndicator()),
                                Center(child: Text("Dosya Gönderiliyor.")),
                              ],
                            ),
                          ),
                        )
                  : Expanded(child: _streamBuilder()),
              Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: () {
                          _scrollController.animateTo(0.0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut);
                        },
                        controller: _messageController,
                        decoration: InputDecoration(
                            hintText: "Bir mesaj yazın",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(70.0),
                            )),
                      ),
                    ),
                    Container(
                      child: FloatingActionButton(
                        elevation: 20,
                        backgroundColor: Colors.orange[400],
                        child: Icon(FontAwesome.send_o),
                        onPressed: () async {
                          if (_messageController.text.trim().isNotEmpty ||
                              file != null) {
                            if (file != null) sendFileinMessage = true;
                            setState(() {});
                            Message message = Message();
                            message.message = _messageController.text.trim();
                            message.receiverid = receiverid;

                            _messageController.text = "";

                            message.fileType = file != null
                                ? file.path
                                    .substring(file.path.lastIndexOf('.'))
                                : "";
                            message.date = DateTime.now().toString();
                            message.imageUrl = await fbService.saveMessage(
                                message, currentUser, receiverUser.token,
                                file: file);
                            message.isMyMessage = 1;
                            message.receiverid = receiverid;
                            databaseHelper.insertMessage(message);
                            file = null;
                            allMessages.insert(0, message);
                            searchAllMessage = allMessages
                                .where((element) => element.message.contains(
                                    searchControler.text.trim().toLowerCase()))
                                .toList();
                            sendFileinMessage = false;
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
  }

  Widget _showMessageWitget(Message message) {
    if (message.isMyMessage == 1) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.orange[400]),
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(4),
                child: InkWell(
                  onLongPress: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text("Dikkat"),
                          content: Text(
                              "Mesajı silmek istediğinizden emin misiniz?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () async {
                                await databaseHelper.messageSil(message.id);
                                allMessages.removeWhere(
                                    (test) => test.id == message.id);
                                searchAllMessage = allMessages
                                    .where((element) => element.message
                                        .contains(searchControler.text
                                            .trim()
                                            .toLowerCase()))
                                    .toList();
                                setState(() {});
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
                  child: message.imageUrl.isEmpty
                      ? Text(message.message)
                      : GestureDetector(
                          onTap: () async {
                            final result = await OpenFile.open(message.imageUrl,
                                type: FileTypeHelper()
                                    .extentionToType(message.fileType));

                            if (result.type == ResultType.noAppToOpen) {
                              await Scaffold.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          "Dosya için uygun yazılım bulunamadı.\nDosya türü: '" +
                                              message.fileType +
                                              "'")))
                                  .closed;
                              await launch(
                                  "https://play.google.com/store/search?q=" +
                                      message.fileType);
                            }
                          },
                          child: Column(
                            children: <Widget>[
                              ([".jpg", ".png", ".jpeg"]
                                      .contains(message.fileType.toLowerCase()))
                                  ? Image.file(
                                      File(message.imageUrl),
                                      height: 150,
                                      width: 150,
                                    )
                                  : FileIcon(message.imageUrl, size: 100),
                              Text(message.message)
                            ],
                          ),
                        ),
                ))
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.orange[100]),
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(4),
                child: InkWell(
                  onLongPress: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text("Dikkat"),
                          content: Text(
                              "Mesajı silmek istediğinizden emin misiniz?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () async {
                                await databaseHelper.messageSil(message.id);
                                allMessages.removeWhere(
                                    (test) => test.id == message.id);
                                searchAllMessage = allMessages
                                    .where((element) => element.message
                                        .contains(searchControler.text
                                            .trim()
                                            .toLowerCase()))
                                    .toList();
                                setState(() {});
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
                  child: message.imageUrl.isEmpty
                      ? Text(message.message)
                      : GestureDetector(
                          onTap: () async {
                            final result = await OpenFile.open(message.imageUrl,
                                type: FileTypeHelper()
                                    .extentionToType(message.fileType));

                            if (result.type == ResultType.noAppToOpen) {
                              await Scaffold.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          "Dosya için uygun yazılım bulunamadı.\nDosya türü: '" +
                                              message.fileType +
                                              "'")))
                                  .closed;
                              await launch(
                                  "https://play.google.com/store/search?q=" +
                                      message.fileType);
                            }
                          },
                          child: Column(
                            children: <Widget>[
                              ([".jpg", ".png", ".jpeg"]
                                      .contains(message.fileType.toLowerCase()))
                                  ? Image.file(
                                      File(message.imageUrl),
                                      height: 150,
                                      width: 150,
                                    )
                                  : FileIcon(
                                      message.imageUrl,
                                      size: 100,
                                    ),
                              Text(message.message)
                            ],
                          ),
                        ),
                ))
          ],
        ),
      );
    }
  }

  Widget _streamBuilder() {
    if (searchAllMessage == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (searchAllMessage.length == 0)
      return Container();
    else {
      return ListView.builder(
          reverse: true,
          controller: _scrollController,
          itemCount: searchAllMessage.length,
          itemBuilder: (contex, i) {
            return _showMessageWitget(searchAllMessage[i]);
          });
    }
  }

  Future<bool> _onBackPressed() {
    if (file != null) {
      file = null;
      setState(() {});
    } else {
      Navigator.of(context).pop(true);
    }
    return Future.value(false);
  }

  void _setChatScreen() async {
    receiverUser = (await databaseHelper.getUserFromId(receiverid)) ??
        (await fbService.getUserbyId(receiverid));

    currentUser = await fbService.currentUser();
    searchAllMessage = await databaseHelper.senderMessages(receiverid);
    allMessages = searchAllMessage;
    setState(() {});

    var ref = FirebaseFirestore.instance
        .collection("messagesTemp")
        .doc(currentUser.userid)
        .collection(receiverid);

    _streamListener = ref
        .orderBy("date", descending: false)
        .snapshots()
        .listen((querySnapshot) {
      ref.parent
          .set({receiverid: FieldValue.delete()}, SetOptions(merge: true));
      List<Message> list = [];
      querySnapshot.docChanges.forEach((change) async {
        if (change.newIndex != -1) {
          list.add(Message.fromMap(change.doc.data()));
          await ref.doc(change.doc.id).delete();
        }
      });
      _incomingMessage(list);
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (_streamBuilder() != null) _streamListener.cancel();
    super.dispose();
  }

  void _incomingMessage(List<Message> newMessageList) async {
    if (newMessageList != null) if (newMessageList.length > 0) {
      await databaseHelper.incomingMessages(newMessageList);
      allMessages = await databaseHelper.senderMessages(receiverid);
      searchAllMessage = allMessages
          .where((element) => element.message
              .contains(searchControler.text.trim().toLowerCase()))
          .toList();
      setState(() {});
    }
  }
}
