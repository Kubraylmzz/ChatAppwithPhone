import 'dart:io';

import 'package:chat_app/models/User.dart';
import 'package:chat_app/services/FBService.dart';
import 'package:chat_app/widgets/CustomAppbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserProfil extends StatefulWidget {
  @override
  _UserProfilState createState() => _UserProfilState();
}

class _UserProfilState extends State<UserProfil> {
  @override
  void initState() {
    _setScreen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppbarCustom(
        title: "Profilim",
        backButton: true,
      ),
      body: UserProfilWidget(),
    );
  }

  Future<void> _setScreen() async {}
}

class UserProfilWidget extends StatefulWidget {
  @override
  _UserProfilWidgetState createState() => _UserProfilWidgetState();
}

class _UserProfilWidgetState extends State<UserProfilWidget> {
  File _profilFoto;
  FBService fbService = FBService();
  Userr currentUser;

  Future<void> _kameradanAl() async {
    _profilFoto = File((await ImagePicker()
            .getImage(source: ImageSource.camera, imageQuality: 60))
        .path);
    if (_profilFoto != null) await _userProfilGuncelle();
    setState(() {
      _profilFoto = _profilFoto;
    });
    Navigator.pop(context);
  }

  Future<void> _galeridenAl() async {
    _profilFoto = File((await ImagePicker()
            .getImage(source: ImageSource.gallery, imageQuality: 60))
        .path);
    if (_profilFoto != null) await _userProfilGuncelle();
    setState(() {
      _profilFoto = _profilFoto;
    });
    Navigator.pop(context);
  }

  Future<void> _userProfilGuncelle() async {
    await fbService.uploadProfilFoto(currentUser.userid, "JPG", _profilFoto);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Userr>(
      future: fbService.currentUser(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        currentUser = snapshot.data;
        if (currentUser != null) {
          var _namecontroller = TextEditingController();
          _namecontroller.text = currentUser.name;
          var _mailcontroller = TextEditingController();
          _mailcontroller.text = currentUser.mail;
          var _phonecontroller = TextEditingController();
          _phonecontroller.text = currentUser.phone;
          return ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.camera),
                                  title: Text("Kameradan al."),
                                  onTap: () {
                                    _kameradanAl();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.image),
                                  title: Text("Galeriden al."),
                                  onTap: () {
                                    _galeridenAl();
                                  },
                                ),
                              ],
                            ),
                          );
                        });
                  },
                  child: Center(
                    child: CircleAvatar(
                      child: Stack(children: <Widget>[
                        Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                              ),
                            )),
                      ]),
                      backgroundImage:
                          currentUser != null && currentUser.photoUrl.isNotEmpty
                              ? NetworkImage(currentUser.photoUrl)
                              : AssetImage("assets/images/profil.jpg"),
                      radius: 75,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                      hintText: 'Ad Soyad',
                      border: OutlineInputBorder(),
                      labelText: "İsim"),
                  controller: _namecontroller,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                      hintText: 'Telefon',
                      border: OutlineInputBorder(),
                      labelText: "Telefon"),
                  controller: _phonecontroller,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                      hintText: 'E-Posta',
                      border: OutlineInputBorder(),
                      labelText: "E-Posta"),
                  controller: _mailcontroller,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () async {
                    if (_namecontroller.text.length > 2) {
                      if (currentUser.name != _namecontroller.text ||
                          currentUser.mail != _mailcontroller.text) {
                        await fbService.updateUser(currentUser.userid,
                            _namecontroller.text, _mailcontroller.text);
                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text("Bilgiler Kaydedildi")));
                      } else {
                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text("Değişiklik algılanmadı.")));
                      }
                    } else {
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("İsim geçersiz.")));
                    }
                  },
                  child: Text(
                    "Kaydet",
                  ),
                ),
              )
            ],
          );
        } else
          return CircularProgressIndicator();
      },
    );
  }
}
