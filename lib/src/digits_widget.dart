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

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';
import 'package:sponge_flutter_app_digit_recognition/src/digits_mvp.dart';
import 'package:sponge_flutter_app_digit_recognition/src/drawer.dart';

class DigitsPage extends StatefulWidget {
  DigitsPage({
    Key key,
    @required this.title,
  }) : super(key: key);

  final String title;

  @override
  createState() => _DigitsPageState();
}

class _DigitsPageState extends State<DigitsPage> implements DigitsView {
  DigitsPresenter _presenter;

  PainterController _controller;

  @override
  void dispose() {
    _presenter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    _presenter ??= DigitsPresenter(service, DigitsViewModel(), this);

    return StreamBuilder<SpongeConnectionState>(
      stream: _presenter.connectionBlocStream,
      initialData: SpongeConnectionStateConnecting(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var connectionState = snapshot.data;

          if (connectionState is SpongeConnectionStateNotConnected) {
            return _buildScaffold(context,
                child: ConnectionNotInitializedWidget(
                  hasConnections: _presenter.hasConnections,
                ));
          } else if (connectionState is SpongeConnectionStateConnecting) {
            _controller?.clear();

            return _buildScaffold(context, child: CircularProgressIndicator());
          } else if (connectionState is SpongeConnectionStateConnected) {
            return FutureBuilder<ActionData>(
              future: _presenter.getActionData(),
              builder: (context, snapshot) => snapshot.hasData
                  ? _buildRecognitionScaffold(context, snapshot.data.actionMeta)
                  : _buildActionFailureScaffold(context, snapshot),
            );
          } else if (connectionState is SpongeConnectionStateError) {
            return _buildScaffold(
              context,
              child: NotificationPanelWidget(
                notification: connectionState.error,
                type: NotificationPanelType.error,
              ),
            );
          }
        }

        return _buildScaffold(
          context,
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildRecognitionScaffold(
      BuildContext context, ActionMeta actionMeta) {
    _controller ??= PainterController();

    return BlocBuilder<ActionCallBloc, ActionCallState>(
        bloc: _presenter.actionCallBloc,
        builder: (BuildContext context, ActionCallState state) {
          _presenter.state = state;

          if (actionMeta != null) {
            _presenter.viewModel.actionMeta = actionMeta;
            _presenter.initValue();
          }

          return _buildScaffold(
            context,
            bottom: _buildAppBarBottom(
                backgroundColor: (_presenter.state is ActionCallStateError)
                    ? Colors.red
                    : (_presenter.recognizing
                        ? getSecondaryColor(context)
                        : Theme.of(context).dialogBackgroundColor),
                onTap: (_presenter.state is ActionCallStateError)
                    ? () => showErrorDialog(context,
                        '${(_presenter.state as ActionCallStateError).error}')
                    : null),
            child: _buildMainWidget(context),
          );
        });
  }

  Widget _buildActionFailureScaffold(
      BuildContext context, AsyncSnapshot<ActionData> snapshot) {
    return _buildScaffold(
      context,
      child: Center(
        child: snapshot.hasError
            ? NotificationPanelWidget(
                notification: snapshot.error,
                type: NotificationPanelType.error,
              )
            : (_presenter.connected
                ? CircularProgressIndicator()
                : ConnectionNotInitializedWidget(
                    hasConnections: _presenter.hasConnections)),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    @required Widget child,
    PreferredSizeWidget bottom,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: _buildAppBarActions(),
        bottom: bottom,
      ),
      body: SafeArea(
        child: Center(child: child),
      ),
      drawer: DigitsDrawer(),
    );
  }

  Widget _buildMainWidget(BuildContext context) {
    if (_presenter.connected) {
      if (_presenter.state is ActionCallStateNoAction) {
        return NotificationPanelWidget(
          notification:
              'The Sponge service you are connected to has no support for digit recognition',
          type: NotificationPanelType.error,
        );
      } else {
        return _buildRecognitionWidget(context);
      }
    } else {
      return Center(
        child: ConnectionNotInitializedWidget(
          hasConnections: _presenter.hasConnections,
        ),
      );
    }
  }

  Widget _buildRecognitionWidget(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var size = mediaQuery.size;
    double minSize = [size.height, size.width].reduce(min);

    var themeData = Theme.of(context);
    final TextStyle resultTextStyle = themeData.textTheme.headline2
        .apply(fontWeightDelta: 2)
        .apply(color: Colors.white);

    var elements = <Widget>[
      AspectRatio(
        aspectRatio: _presenter.value.aspectRatio,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: minSize, height: minSize),
          child: Card(
            elevation: 10.0,
            margin: EdgeInsets.all(10.0),
            child: PainterPanel(
              controller: _controller,
              drawingBinary: _presenter.value,
              onStrokeEnd: _recognizeDigit,
            ),
          ),
        ),
      ),
      Expanded(
        child: Center(
          child: InkResponse(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: isDarkTheme(context)
                  ? themeData.buttonColor
                  : themeData.accentColor,
              foregroundColor: Colors.white,
              child: Text(
                _presenter.digitText,
                style: resultTextStyle,
              ),
            ),
            onTap: _clear,
          ),
        ),
      ),
    ];

    return mediaQuery.orientation == Orientation.portrait
        ? Column(children: elements)
        : Row(children: elements);
  }

  List<Widget> _buildAppBarActions() => <Widget>[
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
          tooltip: 'Information',
        ),
      ];

  PreferredSize _buildAppBarBottom({
    Color backgroundColor,
    GestureTapCallback onTap,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(2.0),
      child: InkResponse(
        onTap: onTap,
        child: LinearProgressIndicator(
          value: 0.0,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  Future<void> _recognizeDigit() async {
    if (_presenter.value == null) {
      return;
    }

    _presenter.recognizeDigit(DrawingBinaryValue.copyWith(
      _presenter.value,
      displaySize: convertToSize(_controller.size),
      strokes: convertToStrokes(_controller.strokes),
    ));
  }

  void _clear() {
    _controller.clear();
    _presenter.clearDigit();
  }

  _showInfo() async {
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = themeData.textTheme.bodyText1;

    await showModalDialog(
      context,
      'Information',
      Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                style: textStyle,
                text:
                    'Draw one large digit in the centre of the black square and wait for the recognition.'
                    '\n\nThe recognized digit will be displayed in the green circle.'
                    '\n\nTouch the circle to clear the drawing.',
              ),
            ],
          ),
        ),
      ),
      closeButtonLabel: 'CLOSE',
    );
  }
}
