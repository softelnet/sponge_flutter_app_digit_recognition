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

Future<void> showAboutDigitsAppDialog(BuildContext context) async {
  final ThemeData themeData = Theme.of(context);
  final TextStyle headerTextStyle =
      themeData.textTheme.bodyText2.apply(fontWeightDelta: 2);
  final TextStyle standardTextStyle = themeData.textTheme.bodyText2;
  final TextStyle noteTextStyle =
      themeData.textTheme.bodyText2.apply(color: getSecondaryColor(context));
  final TextStyle linkStyle =
      themeData.textTheme.bodyText2.copyWith(color: themeData.accentColor);

  var buildNumber = await CommonUtils.getPackageBuildNumber();

  await showDefaultAboutAppDialog(
    context,
    contents: RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            style: headerTextStyle,
            text:
                '\n\nThis is a showcase of a customized Sponge client application in Flutter that calls a Sponge'
                ' action that recognizes handwritten digits. The app is released under the open-source Apache 2.0 license.',
          ),
          TextSpan(
            style: standardTextStyle,
            text:
                '\n\nThe Sponge action uses a typical convolutional neural network trained on the MNIST dataset.'
                ' The machine learning engine is TensorFlow.',
          ),
          TextSpan(
            style: noteTextStyle,
            text:
                '\n\nThe aim of this application is to show how to build a mobile application with Flutter'
                ' that use Sponge as a backend. It is not designed to provide any state of the art recognition model.'
                ' The actual recognition is performed on the server so you may experience visible lags.',
          ),
          TextSpan(
            style: standardTextStyle,
            text: '\n\nFor more information please visit the ',
          ),
          LinkTextSpan(
            style: linkStyle,
            url: 'https://sponge.openksavi.org',
            text: 'Sponge',
          ),
          TextSpan(
            style: standardTextStyle,
            text: ' project home page.',
          ),
          TextSpan(
            style: standardTextStyle,
            text: '\n\nBuild number: $buildNumber.',
          ),
        ],
      ),
    ),
  );
}
