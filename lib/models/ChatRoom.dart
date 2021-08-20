import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  String id;
  String user1;
  String user2;
  String read;
  String messageCount;
  Timestamp lastMessageDate;
  ChatRoom({this.id, this.user1, this.user2});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sides': [user1, user2, user1 + "--" + user2]
    };
  }

  ///[userid] gönderilirse read alanına senderid'nin okuduğu mesaj sayısı düşer.
  ChatRoom.fromMap(Map<String, dynamic> map, {String userid})
      : id = map['id'],
        user1 = map['sides'][0],
        user2 = map['sides'][1],
        read = map[userid] ,
        messageCount = map['messageCount'],
        lastMessageDate = map['lastMessageDate']
        ;
}
