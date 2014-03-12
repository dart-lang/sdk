// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mocks;

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/matcher.dart';

/**
 * Answer the path the the SDK relative to the currently running script
 * or throw an exception if it cannot be found.
 */
String get sdkPath {
  Uri sdkUri = Uri.base.resolveUri(Platform.script).resolve('../../../sdk/');
  // Verify that the internal library file exists
  Uri libFileUri = sdkUri.resolve('lib/_internal/libraries.dart');
  if (!new File.fromUri(libFileUri).existsSync()) {
    throw 'Expected Dart SDK at ${sdkUri.path}';
  }
  return sdkUri.path;
}

/**
 * A mock [WebSocket] for testing.
 */
class MockSocket<T> implements WebSocket {
  StreamController controller = new StreamController();
  MockSocket twin;
  Stream stream;

  factory MockSocket.pair() {
    MockSocket socket1 = new MockSocket();
    MockSocket socket2 = new MockSocket();
    socket1.twin = socket2;
    socket2.twin = socket1;
    socket1.stream = socket2.controller.stream;
    socket2.stream = socket1.controller.stream;
    return socket1;
  }

  MockSocket();

  void add(T text) => controller.add(text);

  void allowMultipleListeners() {
    stream = stream.asBroadcastStream();
  }

  Future close([int code, String reason]) => controller.close()
      .then((_) => twin.controller.close());

  StreamSubscription<T> listen(void onData(T event),
                     { Function onError, void onDone(), bool cancelOnError}) =>
    stream.listen(onData, onError: onError, onDone: onDone,
        cancelOnError: cancelOnError);

  Stream<T> where(bool test(T)) => stream.where(test);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * A mock [ServerCommunicationChannel] for testing [AnalysisServer].
 */
class MockServerChannel implements ServerCommunicationChannel {
  StreamController<Request> requestController = new StreamController<Request>();
  StreamController<Response> responseController = new StreamController<Response>();
  StreamController<Notification> notificationController = new StreamController<Notification>();

  List<Response> responsesReceived = [];
  List<Notification> notificationsReceived = [];

  MockServerChannel() {
  }

  @override
  void listen(void onRequest(Request request), {void onError(), void onDone()}) {
    requestController.stream.listen(onRequest, onError: onError, onDone: onDone);
  }

  @override
  void sendNotification(Notification notification) {
    notificationsReceived.add(notification);
    // Wrap send notification in future to simulate websocket
    new Future(() => notificationController.add(notification));
  }

  /// Simulate request/response pair
  Future<Response> sendRequest(Request request) {
    var id = request.id;
    // Wrap send request in future to simulate websocket
    new Future(() => requestController.add(request));
    return responseController.stream.firstWhere((response) => response.id == id);
  }

  @override
  void sendResponse(Response response) {
    responsesReceived.add(response);
    // Wrap send response in future to simulate websocket
    new Future(() => responseController.add(response));
  }

  void expectMsgCount({responseCount: 0, notificationCount: 0}) {
    expect(responsesReceived, hasLength(responseCount));
    expect(notificationsReceived, hasLength(notificationCount));
  }
}
