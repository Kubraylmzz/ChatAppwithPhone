import 'dart:io';

import 'package:chat_app/models/Message.dart';
import 'package:chat_app/models/User.dart';
import 'package:chat_app/services/NotificationService.dart';
import 'package:chat_app/services/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class FBService {
  void dispose() {
    this.dispose();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<List<Userr>> getAllUserr() async {
    List<Userr> userlist = [];
    var querySnapshot = await _firestore.collection("users").get();
    userlist = querySnapshot.docs.map((f) => Userr.fromMap(f.data())).toList();
    return userlist;
  }

  Future<Userr> currentUser() async {
    String id = firebaseAuth.currentUser.uid;

    Userr user;
    await _firestore.collection("users").doc(id).get().then((onValue) {
      if (onValue.exists) user = Userr.fromMap(onValue.data());
    });
    return user;
  }

  Future<void> saveUserr(Userr user) async {
    await _firestore
        .collection("users")
        .doc(user.userid)
        .set(user.toMap())
        .then((onValue) {
      print("Ok");
    }).catchError((onError) {
      print(onError);
    });
    return null;
  }

  Future<Userr> getUserbyId(String id) async {
    Userr user;
    await _firestore.collection("users").doc(id).get().then((onValue) {
      if (onValue.data != null) if (onValue.data().length > 0)
        user = Userr.fromMap(onValue.data());
    });

    return user;
  }

  Future<String> uploadProfilFoto(
      String userid, String fileType, File file) async {
    var _storageRef = FirebaseStorage.instance
        .ref()
        .child("ProfilFoto")
        .child(userid)
        .child(fileType)
        .child("profilfoto.png")
        .putFile(file);
    String dUrl;
    await _storageRef.whenComplete(() async {
      var url = _storageRef.snapshot.ref;
      dUrl = await url.getDownloadURL();
      await _firestore
          .collection("users")
          .doc(userid)
          .update({'photoUrl': dUrl});
    });

    return dUrl;
  }

  Future<void> updateUser(String userid, String name, String mail) async {
    await _firestore.collection("users").doc(userid).update({
      'name': name,
      'mail': mail,
    });
  }

  Stream<List<Message>> getMyMessages(String userid, String receiverid) {
    var snapShot = _firestore
        .collection("messagesTemp")
        .doc(userid)
        .collection(receiverid)
        .orderBy("date", descending: true)
        .snapshots();
    var messageList = snapShot.map((messages) => messages.docs
        .map((message) => Message.fromMap(message.data()))
        .toList());

    return messageList;
  }

  Future<void> syncUsers() async {
    List<Contact> contactList = [];
    List<Contact> contacts = [];
    contactList = await Contacts.streamContacts(withThumbnails: false).toList();

    contactList.removeWhere((element) => element.phones.length == 0);

    for (var c in contactList) {
      c.phones.first.value = c.phones.first.value.replaceAll(" ", "");
      if (!c.phones.first.value.startsWith("+9")) {
        c.phones.first.value = "+9" + c.phones.first.value;
      }
      if (c.phones.first.value != firebaseAuth.currentUser.phoneNumber) {
        contacts.add(c);
      }
    }
    var userList = (await getContacts(contacts));
    DatabaseHelper().insertAllUsers(userList);
  }

  Future<List<Userr>> getContacts(List<Contact> contacts) async {
    List<Userr> res = [];
    QuerySnapshot<Map<String, dynamic>> querySnapshot;
    for (int i = 0; i < contacts.length; i += 10) {
      var s =
          contacts.skip(i).take(10).map((e) => e.phones.first.value).toList();

      querySnapshot =
          await _firestore.collection("users").where("phone", whereIn: s).get();

      if (querySnapshot.docs.length > 0) {
        querySnapshot.docs.forEach((element) {
          Userr user = Userr.fromMap(element.data());
          var c = contacts.firstWhere(
              (element) => element.phones.first.value == user.phone);
          user.name = c.displayName ?? c.phones.first.value;
          res.add(user);
        });
      }
    }
    return res;
  }

  Future<String> saveMessage(Message message, Userr sender, String token,
      {File file}) async {
    CollectionReference ref = _firestore
        .collection("messagesTemp")
        .doc(message.receiverid)
        .collection(sender.userid);
    String path = "";
    var url;
    if (file != null) {
      Directory klasor = await getExternalStorageDirectory();
      String sd = klasor.parent.parent.parent.parent.path;
      path = join(
          sd,
          "ChatApp",
          "sendFiles",
          message.date.replaceAll(".", "").replaceAll(":", "") +
              message.fileType.toLowerCase());

      file.copySync(path);
      var _storageRef = FirebaseStorage.instance
          .ref()
          .child("MessageAttachTemp")
          .child(message.receiverid)
          .child(message.date.toString())
          .child("attach" + file.path.substring(file.path.lastIndexOf('.')))
          .putFile(file);
      url = _storageRef.snapshot.ref.fullPath;
    }

    message.imageUrl = url;
    message.receiverid = sender.userid;
    await ref.add(message.toMap()).then((onValue) {});
    ref.parent.update({message.receiverid: FieldValue.increment(1)});

    if (token.isNotEmpty) {
      NotificationHelper().bildirimGonder(
          message: message.message,
          senderUser: sender,
          token: token,
          chatRoomid: message.receiverid);
    }
    return path;
  }

  Future<void> checkUser() async {
    var user = await currentUser();
    if (user == null) {
      user = Userr(
          userid: firebaseAuth.currentUser.uid,
          phone: firebaseAuth.currentUser.phoneNumber);
      saveUserr(user);
    }
  }
}
