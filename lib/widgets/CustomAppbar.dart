import 'package:flutter/material.dart';

class AppbarCustom extends StatelessWidget implements PreferredSizeWidget {
  const AppbarCustom({
    this.context,
    this.title = "",
    this.backButton = false,
    this.circleAvatarinLeftButton,
    this.rightWidget,
    this.centerWidget,
  });
  final String title;
  final CircleAvatar circleAvatarinLeftButton;
  final Widget rightWidget;
  final Widget centerWidget;
  final BuildContext context;
  final bool backButton;

  @override
  Widget build(BuildContext context) {
    return new PreferredSize(
      child: new Container(
        padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Stack(
                children: <Widget>[
                  backButton
                      ? Positioned(
                          left: 0,
                          bottom: 4,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                circleAvatarinLeftButton ?? Container(),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.only(left: 30),
                        ),
                  Padding(
                    padding: const EdgeInsets.only(left: 100.0, right: 100),
                    child: Center(
                      child: centerWidget != null
                          ? centerWidget
                          : Text(
                              title.toString(),
                              style: new TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 4,
                    child: rightWidget ?? Container(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      preferredSize: new Size(MediaQuery.of(context).size.width, 150.0),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (0.0));
}
