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

import 'package:logging/logging.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:sponge_flutter_api/sponge_flutter_api.dart';

class DigitsViewModel extends BaseViewModel {
  ActionMeta actionMeta;

  DrawingBinaryValue value;

  /// Not `null` only if the action call hasn't thrown an error.
  ActionCallResultInfo resultInfo;
}

abstract class DigitsView extends BaseView {}

class DigitsPresenter extends BasePresenter<DigitsViewModel, DigitsView> {
  DigitsPresenter(
      ApplicationService service, DigitsViewModel viewModel, DigitsView view)
      : super(service, viewModel, view);

  static final Logger _logger = Logger('DigitsPresenter');

  static const ACTION_NAME = 'DigitsPredict';

  ActionCallBloc _actionCallBloc;
  ActionCallBloc get actionCallBloc => _actionCallBloc;

  ActionCallState _state;
  ActionCallState get state => _state;

  set state(ActionCallState value) {
    _state = value;

    if (_state is ActionCallStateEnded) {
      resultInfo = (_state as ActionCallStateEnded).resultInfo;
    } else if (_state is ActionCallStateError) {
      // Clear the result info on error.
      resultInfo = null;

      _logger.warning(
          'Digit recognition error', (_state as ActionCallStateError).error);
    } else if (_state is ActionCallStateClear) {
      resultInfo = null;
    }
  }

  DrawingBinaryValue get value => viewModel.value;

  void initValue() =>
      viewModel.value ??= DrawingBinaryValue(viewModel.actionMeta.args[0]);

  Stream<SpongeConnectionState> get connectionBlocStream =>
      service.connectionBloc.map((state) {
        if (state is SpongeConnectionStateConnecting) {
          reset();
        } else if (state is SpongeConnectionStateConnected) {
          _initActionCallBloc();
        }

        return state;
      });

  SpongeConnectionState get connectionState => service.connectionBloc.state;

  Future<ActionData> getActionData() async =>
      service.spongeService?.getAction(ACTION_NAME);

  void _initActionCallBloc() {
    _actionCallBloc ??= ActionCallBloc(
      spongeService: service.spongeService,
      actionName: ACTION_NAME,
      saveState: false,
    );
  }

  void dispose() => _actionCallBloc?.close();

  bool get connected => service.connected;

  bool get hasConnections => service.connectionsConfiguration.hasConnections;

  void recognizeDigit(DrawingBinaryValue value) => _actionCallBloc.add([value]);

  ActionCallResultInfo get resultInfo => viewModel.resultInfo;
  set resultInfo(ActionCallResultInfo value) => viewModel.resultInfo = value;

  void clearDigit() {
    viewModel.value.clear();
    _actionCallBloc.clear();
  }

  String get digitText => resultInfo != null
      ? (resultInfo.result != null ? resultInfo.result.toString() : '😕')
      : ' ';

  bool get recognizing => state is ActionCallStateCalling;

  void reset() {
    viewModel.actionMeta = null;
    viewModel.value = null;
    viewModel.resultInfo = null;

    _actionCallBloc = null;
  }
}
