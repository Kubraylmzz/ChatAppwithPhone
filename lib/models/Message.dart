class Message {
  int id;
  int isMyMessage;
  String receiverid;
  String message;
  String date;
  String imageUrl;
  String fileType;

  Message(
      {this.id,
      this.isMyMessage,
      this.message,
      this.date,
      this.receiverid,
      this.imageUrl,
      this.fileType});

  Map<String, dynamic> toMap() {
    return {
      'isMyMessage':isMyMessage,
      'receiverid':receiverid,
      'message': message,
      'date': DateTime.now().toString(),
      'imageUrl': imageUrl,
      'fileType': fileType
    };
  }

  Message.fromMap(Map<String, dynamic> map)
      : id = map['id']??0,
        receiverid = map['receiverid'],
        isMyMessage = map['isMyMessage']??0,
        message = map['message'],
        date = map['date'],
        imageUrl = map['imageUrl'] ?? '',
        fileType = map['fileType'] ?? '';
}
