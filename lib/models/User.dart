class Userr {
  String userid;
  String name;
  String phone;
  String mail;
  String photoUrl;
  String token;

  Userr(
      {this.userid,
      this.mail,
      this.name,
      this.phone,
      this.photoUrl,
      this.token});

  Map<String, dynamic> toMap() {
    return {
      'userid': userid,
      'name': name ?? '',
      'phone': phone ?? '',
      'mail': mail,
      'photoUrl': photoUrl,
      'token': token ?? ''
    };
  }

  Userr.fromMap(Map<String, dynamic> map)
      : userid = map['userid'],
        name = map['name'],
        phone = map['phone'] ?? '',
        mail = map['mail'],
        photoUrl = map['photoUrl'] ?? '',
        token = map['token'] ?? '';
}
