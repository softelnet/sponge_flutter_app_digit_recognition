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

class _DigitsPageState extends State<DigitsPage>
    with TickerProviderStateMixin
    implements DigitsView {
  DigitsPresenter _presenter;

  DrawingBinaryValue _drawingBinary;
  PainterController _controller;

  Animation<double> _animation;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _presenter = DigitsPresenter(DigitsViewModel(), this);

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 3),
        lowerBound: 0.8,
        upperBound: 1.0);
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.linear);
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var service = ApplicationProvider.of(context).service;

    _presenter
      ..setService(service)
      ..initBloc();

    service.bindMainBuildContext(context);

    _controller ??= PainterController();

    return FutureBuilder<ActionData>(
      future: _presenter.getActionData(),
      builder: (BuildContext context, AsyncSnapshot<ActionData> snapshot) =>
          snapshot.hasData
              ? _buildRecognitionScaffold(context, snapshot.data.actionMeta)
              : _buildFailureScaffold(context, snapshot),
    );
  }

  Widget _buildRecognitionScaffold(
      BuildContext context, ActionMeta actionMeta) {
    return StreamBuilder<ActionCallState>(
        stream: _presenter.bloc.state,
        initialData: ActionCallStateInitialize(),
        builder:
            (BuildContext context, AsyncSnapshot<ActionCallState> snapshot) {
          _presenter.state = snapshot.data;

          if (actionMeta != null) {
            _drawingBinary ??= DrawingBinaryValue(actionMeta.args[0]);
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: _buildAppBarActions(),
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
            ),
            body: SafeArea(
              child: _buildMainWidget(context),
            ),
            drawer: DigitsDrawer(),
          );
        });
  }

  Widget _buildFailureScaffold(
      BuildContext context, AsyncSnapshot<ActionData> snapshot) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: _buildAppBarActions(),
      ),
      body: Center(
        child: snapshot.hasError
            ? ErrorPanelWidget(error: snapshot.error)
            : (_presenter.connected
                ? CircularProgressIndicator()
                : ConnectionNotInitializedWidget(
                    hasConnections: _presenter.hasConnections)),
      ),
      drawer: DigitsDrawer(),
    );
  }

  Widget _buildMainWidget(BuildContext context) {
    if (_presenter.connected) {
      if (_presenter.state is ActionCallStateNoAction) {
        return ErrorPanelWidget(
            error:
                'The Sponge service you are connected to has no support for digit recognition');
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
    final TextStyle resultTextStyle = themeData.textTheme.display3
        .apply(fontWeightDelta: 2)
        .apply(color: Colors.white);

    var elements = <Widget>[
      AspectRatio(
        aspectRatio: _drawingBinary.aspectRatio,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: minSize, height: minSize),
          child: Card(
            elevation: 10.0,
            margin: EdgeInsets.all(10.0),
            child: PainterPanel(
              controller: _controller,
              drawingBinary: _drawingBinary,
              onStrokeEnd: _recognizeDigit,
            ),
          ),
        ),
      ),
      Expanded(
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: GestureDetector(
              child: CircleAvatar(
                radius: 50.0,
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
      child: GestureDetector(
        onTap: onTap,
        child: LinearProgressIndicator(
          value: 0.0,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  Future<void> _recognizeDigit() async {
    if (_drawingBinary == null) {
      return;
    }

    // TODO Refactor _drawingBinary.
    _presenter.recognizeDigit(DrawingBinaryValue.copyWith(
      _drawingBinary,
      displaySize: convertToSize(_controller.size),
      strokes: convertToStrokes(_controller.strokes),
    ));
  }

  void _clear() {
    _controller.clear();
    _drawingBinary.clear();
    _presenter.clearDigit();
  }

  _showInfo() async {
    final ThemeData themeData = Theme.of(context);
    final TextStyle accentedTextStyle = themeData.textTheme.body2.apply(
        fontSizeFactor: 1.2,
        fontWeightDelta: 2,
        color: getSecondaryColor(context));

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
                style: accentedTextStyle,
                text:
                    'Draw one large digit in the centre of the black rectangle.'
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
