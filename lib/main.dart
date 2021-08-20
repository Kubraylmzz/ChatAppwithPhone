import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'services/AuthService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          return MaterialApp(
            title: 'Flutter Demo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: snapshot.hasError
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : AuthService().handleAuth(),
          );
        });
  }
}
