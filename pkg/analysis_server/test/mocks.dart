// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/timestamped_data.dart';
import 'package:test/test.dart';

const _jsonEncoder = const JsonEncoder.withIndent('    ');

/**
 * A [Matcher] that check that the given [Response] has an expected identifier
 * and has an error.  The error code may optionally be checked.
 */
Matcher isResponseFailure(String id, [RequestErrorCode code]) =>
    new _IsResponseFailure(id, code);

/**
 * A [Matcher] that check that the given [Response] has an expected identifier
 * and no error.
 */
Matcher isResponseSuccess(String id) => new _IsResponseSuccess(id);

/**
 * A mock [LspServerCommunicationChannel] for testing [LspAnalysisServer].
 */
class MockLspServerChannel implements LspServerCommunicationChannel {
  final StreamController<lsp.Message> _clientToServer =
      new StreamController<lsp.Message>.broadcast();
  final StreamController<lsp.Message> _serverToClient =
      new StreamController<lsp.Message>.broadcast();

  String name;

  /**
   * Completer that will be signalled when the input stream is closed.
   */
  final Completer _closed = new Completer();

  MockLspServerChannel(bool _printMessages) {
    if (_printMessages) {
      _serverToClient.stream
          .listen((message) => print('<== ' + jsonEncode(message)));
      _clientToServer.stream
          .listen((message) => print('==> ' + jsonEncode(message)));
    }
  }

  /**
   * Future that will be completed when the input stream is closed.
   */
  Future get closed {
    return _closed.future;
  }

  Stream<lsp.Message> get serverToClient => _serverToClient.stream;

  @override
  void close() {
    if (!_closed.isCompleted) {
      _closed.complete();
    }
  }

  /// Run the object through JSON serialisation to catch any
  /// issues like fields that are unserialisable types. This is used for
  /// messages going server-to-client.
  void ensureMessageCanBeJsonSerialized(ToJsonable message) {
    jsonEncode(message.toJson());
  }

  @override
  void listen(void Function(lsp.Message message) onMessage,
      {Function onError, void Function() onDone}) {
    _clientToServer.stream.listen(onMessage, onError: onError, onDone: onDone);
  }

  @override
  void sendNotification(lsp.NotificationMessage notification) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    ensureMessageCanBeJsonSerialized(notification);

    _serverToClient.add(notification);
  }

  void sendNotificationToServer(lsp.NotificationMessage notification) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    notification = _convertJson(notification, lsp.NotificationMessage.fromJson);

    // Wrap send request in future to simulate WebSocket.
    new Future(() => _clientToServer.add(notification));
  }

  @override
  void sendRequest(lsp.RequestMessage request) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    ensureMessageCanBeJsonSerialized(request);

    _serverToClient.add(request);
  }

  /**
   * Send the given [request] to the server and return a future that will
   * complete when a response associated with the [request] has been received.
   * The value of the future will be the received response.
   */
  Future<lsp.ResponseMessage> sendRequestToServer(lsp.RequestMessage request) {
    // No further requests should be sent after the connection is closed.
    if (_closed.isCompleted) {
      throw new Exception('sendLspRequest after connection closed');
    }

    request = _convertJson(request, lsp.RequestMessage.fromJson);

    // Wrap send request in future to simulate WebSocket.
    new Future(() => _clientToServer.add(request));
    return waitForResponse(request);
  }

  @override
  void sendResponse(lsp.ResponseMessage response) {
    // Don't deliver responses after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    ensureMessageCanBeJsonSerialized(response);

    // Wrap send response in future to simulate WebSocket.
    new Future(() => _serverToClient.add(response));
  }

  void sendResponseToServer(lsp.ResponseMessage response) {
    // Don't deliver notifications after the connection is closed.
    if (_closed.isCompleted) {
      return;
    }

    response = _convertJson(response, lsp.ResponseMessage.fromJson);

    _clientToServer.add(response);
  }

  /**
   * Return a future that will complete when a response associated with the
   * given [request] has been received. The value of the future will be the
   * received response. The returned future will throw an exception if a server
   * error is reported before the response has been received.
   *
   * Unlike [sendLspRequest], this method assumes that the [request] has already
   * been sent to the server.
   */
  Future<lsp.ResponseMessage> waitForResponse(
    lsp.RequestMessage request, {
    bool throwOnError = true,
  }) async {
    final response = await _serverToClient.stream.firstWhere((message) =>
        (message is lsp.ResponseMessage && message.id == request.id) ||
        (throwOnError &&
            message is lsp.NotificationMessage &&
            message.method == Method.window_showMessage));

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
    return constructor(jsonDecode(jsonEncode(message.toJson())));
  }
}

/**
 * A mock [ServerCommunicationChannel] for testing [AnalysisServer].
 */
class MockServerChannel implements ServerCommunicationChannel {
  StreamController<Request> requestController = new StreamController<Request>();
  StreamController<Response> responseController =
      new StreamController<Response>.broadcast();
  StreamController<Notification> notificationController =
      new StreamController<Notification>(sync: true);
  Completer<Response> errorCompleter;

  List<Response> responsesReceived = [];
  List<Notification> notificationsReceived = [];

  bool _closed = false;

  String name;

  MockServerChannel();

  @override
  void close() {
    _closed = true;
  }

  void expectMsgCount({responseCount = 0, notificationCount = 0}) {
    expect(responsesReceived, hasLength(responseCount));
    expect(notificationsReceived, hasLength(notificationCount));
  }

  @override
  void listen(void onRequest(Request request),
      {Function onError, void onDone()}) {
    requestController.stream
        .listen(onRequest, onError: onError, onDone: onDone);
  }

  @override
  void sendNotification(Notification notification) {
    // Don't deliver notifications after the connection is closed.
    if (_closed) {
      return;
    }
    notificationsReceived.add(notification);
    if (errorCompleter != null && notification.event == 'server.error') {
      print(
          '[server.error] test: $name message: ${notification.params['message']}');
      errorCompleter.completeError(
          new ServerError(notification.params['message']),
          new StackTrace.fromString(notification.params['stackTrace']));
    }
    // Wrap send notification in future to simulate websocket
    // TODO(scheglov) ask Dan why and decide what to do
//    new Future(() => notificationController.add(notification));
    notificationController.add(notification);
  }

  /**
   * Send the given [request] to the server and return a future that will
   * complete when a response associated with the [request] has been received.
   * The value of the future will be the received response. If [throwOnError] is
   * `true` (the default) then the returned future will throw an exception if a
   * server error is reported before the response has been received.
   */
  Future<Response> sendRequest(Request request, {bool throwOnError = true}) {
    // TODO(brianwilkerson) Attempt to remove the `throwOnError` parameter and
    // have the default behavior be the only behavior.
    // No further requests should be sent after the connection is closed.
    if (_closed) {
      throw new Exception('sendRequest after connection closed');
    }
    // Wrap send request in future to simulate WebSocket.
    new Future(() => requestController.add(request));
    return waitForResponse(request, throwOnError: throwOnError);
  }

  @override
  void sendResponse(Response response) {
    // Don't deliver responses after the connection is closed.
    if (_closed) {
      return;
    }
    responsesReceived.add(response);
    // Wrap send response in future to simulate WebSocket.
    new Future(() => responseController.add(response));
  }

  /**
   * Return a future that will complete when a response associated with the
   * given [request] has been received. The value of the future will be the
   * received response. If [throwOnError] is `true` (the default) then the
   * returned future will throw an exception if a server error is reported
   * before the response has been received.
   *
   * Unlike [sendRequest], this method assumes that the [request] has already
   * been sent to the server.
   */
  Future<Response> waitForResponse(Request request,
      {bool throwOnError = true}) {
    // TODO(brianwilkerson) Attempt to remove the `throwOnError` parameter and
    // have the default behavior be the only behavior.
    String id = request.id;
    Future<Response> response =
        responseController.stream.firstWhere((response) => response.id == id);
    if (throwOnError) {
      errorCompleter = new Completer<Response>();
      try {
        return Future.any([response, errorCompleter.future]);
      } finally {
        errorCompleter = null;
      }
    }
    return response;
  }
}

class MockSource extends StringTypedMock implements Source {
  @override
  TimestampedData<String> contents = null;

  @override
  String encoding = null;

  @override
  String fullName = null;

  @override
  bool isInSystemLibrary = null;

  @override
  Source librarySource = null;

  @override
  int modificationStamp = null;

  @override
  String shortName = null;

  @override
  Source source = null;

  @override
  Uri uri = null;

  @override
  UriKind uriKind = null;

  MockSource([String name = 'mocked.dart']) : super(name);

  @override
  bool exists() => null;
}

class ServerError implements Exception {
  final message;

  ServerError(this.message);

  String toString() {
    return "Server Error: $message";
  }
}

class StringTypedMock {
  String _toString;

  StringTypedMock(this._toString);

  @override
  String toString() {
    if (_toString != null) {
      return _toString;
    }
    return super.toString();
  }
}

/**
 * A [Matcher] that check that there are no `error` in a given [Response].
 */
class _IsResponseFailure extends Matcher {
  final String _id;
  final RequestErrorCode _code;

  _IsResponseFailure(this._id, this._code);

  @override
  Description describe(Description description) {
    description =
        description.add('response with identifier "$_id" and an error');
    if (_code != null) {
      description = description.add(' with code ${this._code.name}');
    }
    return description;
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    Response response = item;
    var id = response.id;
    RequestError error = response.error;
    mismatchDescription.add('has identifier "$id"');
    if (error == null) {
      mismatchDescription.add(' and has no error');
    } else {
      mismatchDescription
          .add(' and has error code ${response.error.code.name}');
    }
    return mismatchDescription;
  }

  @override
  bool matches(item, Map matchState) {
    Response response = item;
    if (response.id != _id || response.error == null) {
      return false;
    }
    if (_code != null && response.error.code != _code) {
      return false;
    }
    return true;
  }
}

/**
 * A [Matcher] that check that there are no `error` in a given [Response].
 */
class _IsResponseSuccess extends Matcher {
  final String _id;

  _IsResponseSuccess(this._id);

  @override
  Description describe(Description description) {
    return description
        .addDescriptionOf('response with identifier "$_id" and without error');
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    Response response = item;
    if (response == null) {
      mismatchDescription.add('is null response');
    } else {
      var id = response.id;
      RequestError error = response.error;
      mismatchDescription.add('has identifier "$id"');
      if (error != null) {
        mismatchDescription.add(' and has error $error');
      }
    }
    return mismatchDescription;
  }

  @override
  bool matches(item, Map matchState) {
    Response response = item;
    return response != null && response.id == _id && response.error == null;
  }
}
