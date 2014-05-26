// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mocks;

import 'dart:async';
import 'dart:io';

@MirrorsUsed(targets: 'mocks', override: '*')
import 'dart:mirrors';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analysis_server/src/analysis_logger.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:matcher/matcher.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';

/**
 * Answer the absolute path the the SDK relative to the currently running
 * script or throw an exception if it cannot be found.
 */
String get sdkPath {
  Uri sdkUri = Platform.script.resolve('../../../sdk/');

  // Verify the directory exists
  Directory sdkDir = new Directory.fromUri(sdkUri);
  if (!sdkDir.existsSync()) {
    throw 'Specified Dart SDK does not exist: $sdkDir';
  }

  return sdkDir.path;
}

/**
 * Returns a [Future] that completes after pumping the event queue [times]
 * times. By default, this should pump the event queue enough times to allow
 * any code to run, as long as it's not waiting on some external event.
 */
Future pumpEventQueue([int times = 20]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
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

class NoResponseException implements Exception {
  /**
   * The request that was not responded to.
   */
  final Request request;

  NoResponseException(this.request);

  String toString() {
    return "NoResponseException after request ${request.toJson()}";
  }
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
  void listen(void onRequest(Request request), {Function onError, void onDone()}) {
    requestController.stream.listen(onRequest, onError: onError, onDone: onDone);
  }

  @override
  void sendNotification(Notification notification) {
    notificationsReceived.add(notification);
    // Wrap send notification in future to simulate websocket
    new Future(() => notificationController.add(notification));
  }

  /**
   * Simulate request/response pair.
   */
  Future<Response> sendRequest(Request request) {
    var id = request.id;
    // Wrap send request in future to simulate websocket
    new Future(() => requestController.add(request));
    pumpEventQueue().then((_) => responseController.addError(
        new NoResponseException(request)));
    return responseController.stream.firstWhere((response) => response.id == id
        );
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

/**
 * Exception thrown when an unexpected function call is made on a mock.
 */
class UnexpectedMockCall extends Error {
  UnexpectedMockCall(this.functionName);

  final String functionName;

  String toString() => "Unexpected call to $functionName";
}

/**
 * Shorthand function for throwing an UnexpectedMockCall exception.
 */
_unexpected(String functionName) {
  throw new UnexpectedMockCall(functionName);
}

/**
 * A mock [AnalysisLogger] that treats all errors and warnings as unexpected.
 */
@proxy
class MockAnalysisLogger extends Logger {

  void logError(String message) {
    print(message);
    _unexpected('MockAnalysisLogger.logError');
  }

  noSuchMethod(Invocation invocation) {
    var name = MirrorSystem.getName(invocation.memberName);
    return _unexpected("MockAnalysisLogger.$name");
  }
}

/**
 * A mock [AnalysisContext] for testing [AnalysisServer].
 */
class MockAnalysisContext extends Mock implements AnalysisContext {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * A mock [Source].  Particularly useful when all that is needed is the
 * encoding.
 */
class MockSource extends Mock implements Source {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
