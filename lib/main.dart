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
import 'package:provider/provider.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_flutter_app_digit_recognition/application_constants.dart';
import 'package:sponge_flutter_app_digit_recognition/logger_configuration.dart';
import 'package:sponge_flutter_app_digit_recognition/src/digits_widget.dart';

void main() async {
  configLogger();

  WidgetsFlutterBinding.ensureInitialized();

  var service = await _createApplicationService();

  runApp(SongeDigitRecognitionApp(service));
}

Future<ApplicationService> _createApplicationService() async {
  var service = FlutterApplicationService();
  await service.init();
  if (service.activeConnection?.name == null) {
    await service.setActiveConnection(ApplicationConstants.DEMO_SERVICE_NAME);
  }
  return service;
}

class SongeDigitRecognitionApp extends StatelessWidget {
  SongeDigitRecognitionApp(this.service);

  final ApplicationService service;

  @override
  Widget build(BuildContext context) {
    return ApplicationProvider(
      service: service,
      child: MaterialApp(
        title: APPLICATION_TITLE,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          brightness: Brightness.dark,
        ),
        home: Provider<ApplicationService>(
          create: (_) => service,
          //lazy: false,
          child: DigitsPage(
            title: APPLICATION_TITLE,
          ),
        ),
        routes: {
          Routes.CONNECTIONS: (context) => ConnectionsWidget(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
