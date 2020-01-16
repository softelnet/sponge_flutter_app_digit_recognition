// Copyright 2020 The Sponge authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_flutter_app_digit_recognition/application_constants.dart';
import 'package:sponge_flutter_app_digit_recognition/src/about_dialog.dart';

class DigitsDrawer extends StatelessWidget {
  DigitsDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = getSecondaryColor(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DefaultDrawerHeader(applicationName: APPLICATION_NAME_SHORT),
          ListTile(
            leading: Icon(Icons.cloud, color: iconColor),
            title: Text('Connections'),
            onTap: () async =>
                showChildScreen(context, DefaultRoutes.CONNECTIONS),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info, color: iconColor),
            title: Text('About'),
            onTap: () async => await showAboutDigitsAppDialog(context),
          ),
        ],
      ),
    );
  }
}
