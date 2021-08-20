import 'dart:async';
import 'dart:io';
import 'package:chat_app/models/ChatListModel.dart';
import 'package:chat_app/models/Message.dart';
import 'package:chat_app/models/User.dart';
import 'package:chat_app/services/DownloadService.dart';
import 'package:chat_app/services/FBService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper;
  static Database _database;
  String _folderName = "ChatApp";

  //Sutun adları string olarak tanımlanır
  String _messageTable = 'message';
  String _id = 'id';
  String _receiverid = 'receiverid';
  String _isMyMessage = 'isMyMessage';
  String _message = 'message';
  String _date = 'date';
  String _imageUrl = 'imageUrl';
  String _fileType = 'fileType';
  // Userrs
  String _usersTable = 'users';
  String _userId = "userid";
  String _name = "name";
  String _phone = "phone";
  String _photoUrl = "photoUrl";
  String _token = "token";
  String _mail = "mail";

  FBService fbService = FBService();

  DatabaseHelper._internal();
  void logOut() {
    _databaseHelper = null;
    _database = null;
  }

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      print("DATA BASE HELPER NULL, OLUSTURULACAK");
      _databaseHelper = DatabaseHelper._internal();
      return _databaseHelper;
    } else {
      print("DATA BASE HELPER NULL DEGIL");
      return _databaseHelper;
    }
  }

  Future<Stream<List<Map<String, dynamic>>>> chatlistener() async {
    var db = await _getDatabase();
    var sonuc = db.rawQuery("Select * from message").asStream();
    return sonuc;
  }

  Future<Database> _getDatabase() async {
    if (_database == null) {
      print("DATA BASE NESNESI NULL, OLUSTURULACAK");
      _database = await _initializeDatabase();
      return _database;
    } else {
      print("DATA BASE NESNESI NULL DEĞİL");
      return _database;
    }
  }

  Directory klasor;
  String sd;
  _initializeDatabase() async {
    klasor = await getExternalStorageDirectory(); // C://Users/Emre/message.db
    sd = klasor.parent.parent.parent.parent.path;
    String dbName = FirebaseAuth.instance.currentUser.uid;
    String path = join(sd, _folderName, dbName + ".db");
    print("Olusan veritabanının tam yolu : $path");
    if (!(await Directory(join(sd, _folderName)).exists())) {
      await Directory(join(sd, _folderName)).create(recursive: true);
    }
    var messageDB = await openDatabase(path, version: 1, onCreate: _createDB);
    if (!(await Directory(join(sd, _folderName, "sendFiles")).exists())) {
      Directory(join(sd, _folderName, "sendFiles")).create(recursive: true);
      Directory(join(sd, _folderName, "incoming")).create();
    }
    return messageDB;
  }

  Future _createDB(Database db, int version) async {
    print("CREATE DB METHODU CALISTI TABLO OLUSTURULACAK");
    await db.execute(
        "CREATE TABLE $_messageTable ($_id INTEGER PRIMARY KEY AUTOINCREMENT, $_message TEXT, $_isMyMessage INTEGER ,$_receiverid TEXT, $_date TEXT, $_imageUrl TEXT, $_fileType TEXT )");
    await db.execute(
        "CREATE TABLE $_usersTable ($_id INTEGER PRIMARY KEY AUTOINCREMENT, $_userId TEXT,$_name TEXT, $_phone TEXT, $_imageUrl TEXT, $_token TEXT, $_photoUrl TEXT, $_mail TEXT)");
  }

  Future<Userr> getUserrFromPhone(String phone) async {
    var db = await _getDatabase();
    var sonuc = await db
        .query(_usersTable, where: '$_phone = ?', whereArgs: [phone.trim()]);
    Userr c;
    if (sonuc.isNotEmpty) {
      c = Userr.fromMap(sonuc.first);
    }
    return c;
  }

  Future<Userr> getUserFromId(String id) async {
    var db = await _getDatabase();
    var sonuc = await db
        .query(_usersTable, where: '$_userId = ?', whereArgs: [id.trim()]);
    Userr c;
    if (sonuc.isNotEmpty) {
      c = Userr.fromMap(sonuc.first);
    }
    return c;
  }

  Future<int> insertAllUsers(List<Userr> users) async {
    for (var user in users) {
      await insertUser(user);
    }
    return 1;
  }

  Future<int> insertUser(Userr user) async {
    var db = await _getDatabase();
    if ((await getUserrFromPhone(user.phone)) != null) {
      await updateUserr(user);
    } else {
      await db.insert(_usersTable, user.toMap());
    }
    return 1;
  }

  Future<List<Userr>> getAllUserrs() async {
    var db = await _getDatabase();
    var sonuc = await db.query(_usersTable, orderBy: '$_id DESC');
    var ct = sonuc.map((e) => Userr.fromMap(e)).toList();
    return ct;
  }

  Future<int> updateUserr(Userr user) async {
    var db = await _getDatabase();
    var sonuc = db.update(_usersTable, user.toMap(),
        where: '$_userId = ?', whereArgs: [user.userid]);
    return sonuc;
  }

  Future<int> insertMessage(Message message) async {
    var db = await _getDatabase();
    var sonuc = await db.insert(_messageTable, message.toMap());
    return sonuc;
  }

  Future<List<Message>> senderMessages(String userid) async {
    var db = await _getDatabase();
    var sonuc = await db.rawQuery(
        "Select * from message WHERE receiverid= ? order by id desc", [userid]);
    var messages = sonuc.map((f) => Message.fromMap(f)).toList();
    return messages;
  }

  Future<List<Map<String, dynamic>>> tumMessageler() async {
    var db = await _getDatabase();
    var sonuc = await db.query(_messageTable, orderBy: '$_id DESC');
    return sonuc;
  }

  Future<int> messageGuncelle(Message message) async {
    var db = await _getDatabase();
    var sonuc = db.update(_messageTable, message.toMap(),
        where: '$_id = ?', whereArgs: [message.id]);

    return sonuc;
  }

  Future<int> messageSil(int id) async {
    var db = await _getDatabase();
    var sonuc = db.delete(_messageTable, where: '$_id = ?', whereArgs: [id]);
    return sonuc;
  }

  Future<int> tumMessageTablesunuSil() async {
    var db = await _getDatabase();
    var sonuc = db.delete(_messageTable);

    return sonuc;
  }

  Future<void> incomingMessages(List<Message> newMessageList) async {
    for (var message in newMessageList) {
      if (message.imageUrl.isNotEmpty) {
        DownloadService downloadService = DownloadService();
        String path = join(
            sd,
            _folderName,
            "incoming",
            message.date.replaceAll(".", "").replaceAll(":", "") +
                message.fileType.toLowerCase());
        await downloadService.downloadFileFromFireStore(message.imageUrl, path);
        message.imageUrl = path;
      }
      message.id = null;
      await insertMessage(message);
    }
  }

  Future<List<ChatListModel>> getMyChatRooms(String userid) async {
    List<ChatListModel> list = [];

    var db = await _getDatabase();
    var localMessages = (await db.rawQuery(
            "Select receiverid from message Group By receiverid order by date desc"))
        .toList();

    for (var message in localMessages) {
      var receiverid = message['receiverid'];
      var user = (await getUserFromId(receiverid)) ??
          (await fbService.getUserbyId(receiverid));
      ChatListModel chatRoom;
      if (user != null) {
        chatRoom = ChatListModel.fromMap(user);
        list.add(chatRoom);
      }
    }
    var newMessages = await FirebaseFirestore.instance
        .collection("messagesTemp")
        .doc(userid)
        .get();
    if (newMessages.exists) if (newMessages.data().isNotEmpty)
      for (var sender in newMessages.data().entries) {
        if (sender.value != null) {
          if (list.any((room) => room.userid == sender.key)) {
            list.firstWhere((test) => test.userid == sender.key).read =
                sender.value.toString();
          } else {
            var user = (await getUserFromId(sender.key)) ??
                (await fbService.getUserbyId(sender.key));
            if (user != null) {
              ChatListModel cm = ChatListModel.fromMap(user);
              cm.read = sender.value.toString();
              list.insert(0, cm);
            }
          }
        }
      }

    return list;
  }

  Future<void> deleteChat(String userid) async {
    var db = await _getDatabase();
    await db
        .delete(_messageTable, where: '$_receiverid = ?', whereArgs: [userid]);
  }
}
