// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart' as lsp;
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';

const _jsonEncoder = JsonEncoder.withIndent('    ');

/// A mock [LspServerCommunicationChannel] for testing [LspAnalysisServer].
class MockLspServerChannel implements LspServerCommunicationChannel {
  final StreamController<lsp.Message> _clientToServer =
      StreamController<lsp.Message>.broadcast();
  final StreamController<lsp.Message> _serverToClient =
      StreamController<lsp.Message>.broadcast();

  /// Completer that will be signalled when the input stream is closed.
  final Completer _closed = Completer();

  /// Errors popups sent to the user.
  final shownErrors = <lsp.ShowMessageParams>[];

  /// Warning popups sent to the user.
  final shownWarnings = <lsp.ShowMessageParams>[];

  MockLspServerChannel(bool _printMessages) {
    if (_printMessages) {
      _serverToClient.stream
          .listen((message) => print('<== ' + jsonEncode(message)));
      _clientToServer.stream
          .listen((message) => print('==> ' + jsonEncode(message)));
    }

    // Keep track of any errors/warnings that are sent to the user with
    // `window/showMessage`.
    _serverToClient.stream.listen((message) {
      if (message is lsp.NotificationMessage &&
          message.method == Method.window_showMessage) {
        final params = message.params;
        if (params is lsp.ShowMessageParams) {
          if (params.type == MessageType.Error) {
            shownErrors.add(params);
          } else if (params.type == MessageType.Warning) {
            shownWarnings.add(params);
          }
        }
      }
    });
  }

  /// Future that will be completed when the input stream is closed.
  @override
  Future get closed {
    return _closed.future;
  }

  Stream<lsp.Message> get serverToClient => _serverToClient.stream;

  @override
  void close() {
    if (!_closed.isCompleted) {
      _closed.complete();
    }
    if (!_serverToClient.isClosed) {
      _serverToClient.close();
    }
    if (!_clientToServer.isClosed) {
      _clientToServer.close();
    }
  }

  @override
  void listen(void Function(lsp.Message message) onMessage,
      {Function? onError, void Function()? onDone}) {
    _clientToServer.stream.listen(onMessage, onError: onError, onDone: onDone);
  }

  @override
  void sendNotification(lsp.NotificationMessage notification) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    notification = _convertJson(notification, lsp.NotificationMessage.fromJson);

    _serverToClient.add(notification);
  }

  void sendNotificationToServer(lsp.NotificationMessage notification) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    notification = _convertJson(notification, lsp.NotificationMessage.fromJson);

    // Wrap send request in future to simulate WebSocket.
    Future(() => _clientToServer.add(notification));
  }

  @override
  void sendRequest(lsp.RequestMessage request) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    request = _convertJson(request, lsp.RequestMessage.fromJson);

    _serverToClient.add(request);
  }

  /// Send the given [request] to the server and return a future that will
  /// complete when a response associated with the [request] has been received.
  /// The value of the future will be the received response.
  Future<lsp.ResponseMessage> sendRequestToServer(lsp.RequestMessage request) {
    // No further requests should be sent after the connection is closed.
    if (_closed.isCompleted) {
      throw Exception('${request.method} request sent after connection closed');
    }

    request = _convertJson(request, lsp.RequestMessage.fromJson);

    // Wrap send request in future to simulate WebSocket.
    Future(() => _clientToServer.add(request));
    return waitForResponse(request);
  }

  @override
  void sendResponse(lsp.ResponseMessage response) {
    // Don't deliver responses after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    response = _convertJson(response, lsp.ResponseMessage.fromJson);

    // Wrap send response in future to simulate WebSocket.
    Future(() => _serverToClient.add(response));
  }

  void sendResponseToServer(lsp.ResponseMessage response) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    response = _convertJson(response, lsp.ResponseMessage.fromJson);

    _clientToServer.add(response);
  }

  /// Return a future that will complete when a response associated with the
  /// given [request] has been received. The value of the future will be the
  /// received response. The returned future will throw an exception if a server
  /// error is reported before the response has been received.
  ///
  /// Unlike [sendLspRequest], this method assumes that the [request] has
  /// already been sent to the server.
  Future<lsp.ResponseMessage> waitForResponse(
    lsp.RequestMessage request, {
    bool throwOnError = true,
  }) async {
    final response = await _serverToClient.stream.firstWhere((message) =>
        (message is lsp.ResponseMessage && message.id == request.id) ||
        (throwOnError &&
            message is lsp.NotificationMessage &&
            message.method == Method.window_showMessage &&
            lsp.ShowMessageParams.fromJson(
                        message.params as Map<String, Object?>)
                    .type ==
                MessageType.Error));

    if (response is lsp.ResponseMessage) {
      return response;
    } else {
      throw 'An error occurred while waiting for a response to ${request.method}: '
          '${_jsonEncoder.convert(response.toJson())}';
    }
  }

  /// Round trips the object to JSON and back to ensure it behaves the same as
  /// when running over the real STDIO server. Without this, the object passed
  /// to the handlers will have concrete types as constructed in tests rather
  /// than the maps as they would be (the server expects to do the conversion).
  T _convertJson<T>(
      lsp.ToJsonable message, T Function(Map<String, dynamic>) constructor) {
    return constructor(
        jsonDecode(jsonEncode(message.toJson())) as Map<String, Object?>);
  }
}
