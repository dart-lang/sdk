// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mocks;

import 'dart:async';
import 'dart:io';

@MirrorsUsed(targets: 'mocks', override: '*')
import 'dart:mirrors';

import 'package:analysis_services/index/index.dart';
import 'package:analyzer/file_system/file_system.dart' as resource;
import 'package:analyzer/file_system/memory_file_system.dart' as resource;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/package_map_provider.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
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
 * Returns a [Future] that completes when the given [AnalysisServer] finished
 * all its scheduled tasks.
 */
Future waitForServerOperationsPerformed(AnalysisServer server) {
  if (server.test_areOperationsFinished()) {
    return new Future.value();
  }
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO,
      () => waitForServerOperationsPerformed(server));
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
  StreamController<Notification> notificationController = new StreamController<Notification>(sync: true);

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
    // TODO(scheglov) ask Dan why and decide what to do
//    new Future(() => notificationController.add(notification));
    notificationController.add(notification);
  }

  /**
   * Simulate request/response pair.
   */
  Future<Response> sendRequest(Request request) {
    // Wrap send request in future to simulate websocket
    new Future(() => requestController.add(request));
    return waitForResponse(request);
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

  Future<Response> waitForResponse(Request request) {
    String id = request.id;
    pumpEventQueue().then((_) {
      responseController.addError(new NoResponseException(request));
    });
    return responseController.stream.firstWhere((response) {
      return response.id == id;
    });
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

typedef void MockServerOperationPerformFunction(AnalysisServer server);

/**
 * A mock [ServerOperation] for testing [AnalysisServer].
 */
class MockServerOperation implements PerformAnalysisOperation {
  final ServerOperationPriority priority;
  final MockServerOperationPerformFunction _perform;

  MockServerOperation(this.priority, this._perform);

  @override
  void perform(AnalysisServer server) => this._perform(server);

  @override
  AnalysisContext get context => null;

  @override
  bool get isContinue => false;

  @override
  void sendNotices(AnalysisServer server, List<ChangeNotice> notices) {
  }

  @override
  void updateIndex(Index index, List<ChangeNotice> notices) {
  }
}


/**
 * A [Matcher] that check that the given [Response] has an expected identifier
 * and no error.
 */
Matcher isResponseSuccess(String id) => new _IsResponseSuccess(id);

/**
 * A [Matcher] that check that there are no `error` in a given [Response].
 */
class _IsResponseSuccess extends Matcher {
  final String _id;

  _IsResponseSuccess(this._id);

  @override
  Description describe(Description description) {
    return description.addDescriptionOf(
        'response with identifier "$_id" and without error');
  }

  @override
  bool matches(item, Map matchState) {
    Response response = item;
    return response != null && response.id == _id && response.error == null;
  }

  @override
  Description describeMismatch(item, Description mismatchDescription,
                               Map matchState, bool verbose) {
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
}


/**
 * A [Matcher] that check that the given [Response] has an expected identifier
 * and has an error.
 */
Matcher isResponseFailure(String id) => new _IsResponseFailure(id);

/**
 * A [Matcher] that check that there are no `error` in a given [Response].
 */
class _IsResponseFailure extends Matcher {
  final String _id;

  _IsResponseFailure(this._id);

  @override
  Description describe(Description description) {
    return description.addDescriptionOf(
        'response with identifier "$_id" and an error');
  }

  @override
  bool matches(item, Map matchState) {
    Response response = item;
    return response.id == _id && response.error != null;
  }

  @override
  Description describeMismatch(item, Description mismatchDescription,
                               Map matchState, bool verbose) {
    Response response = item;
    var id = response.id;
    RequestError error = response.error;
    mismatchDescription.add('has identifier "$id"');
    if (error == null) {
      mismatchDescription.add(' and has no error');
    }
    return mismatchDescription;
  }
}


/**
 * A mock [PackageMapProvider].
 */
class MockPackageMapProvider implements PackageMapProvider {
  /**
   * Package map that will be returned by the next call to [computePackageMap].
   */
  Map<String, List<resource.Folder>> packageMap = <String, List<resource.Folder>>{};

  /**
   * Dependency list that will be returned by the next call to [computePackageMap].
   */
  Set<String> dependencies = new Set<String>();

  @override
  PackageMapInfo computePackageMap(resource.Folder folder) {
    return new PackageMapInfo(packageMap, dependencies);
  }
}
