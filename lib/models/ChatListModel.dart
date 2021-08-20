import 'User.dart';

class ChatListModel {
  String userid;
  String name;
  String mail;
  String photoUrl;
  String read;
  ChatListModel({this.userid, this.name, this.mail, this.photoUrl, this.read});

  ///[userid] gönderilirse read alanına senderid'nin okuduğu mesaj sayısı düşer.
  ChatListModel.fromMap(Userr user)
      : read = "0",
        userid = user.userid,
        name = user.name ?? user.phone,
        mail = user.mail,
        photoUrl = user.photoUrl;
}
