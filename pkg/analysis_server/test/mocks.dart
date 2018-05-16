// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analyzer/file_system/file_system.dart' as resource;
import 'package:analyzer/file_system/memory_file_system.dart' as resource;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_provider.dart';
import 'package:analyzer/src/source/pub_package_map_provider.dart';
import 'package:front_end/src/base/timestamped_data.dart';
import 'package:test/test.dart';

/**
 * Answer the absolute path the SDK relative to the currently running
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
 * A mock [PackageMapProvider].
 */
class MockPackageMapProvider implements PubPackageMapProvider {
  /**
   * Package map that will be returned by the next call to [computePackageMap].
   */
  Map<String, List<resource.Folder>> packageMap =
      <String, List<resource.Folder>>{};

  /**
   * Package maps that will be returned by the next call to [computePackageMap].
   */
  Map<String, Map<String, List<resource.Folder>>> packageMaps = null;

  /**
   * Dependency list that will be returned by the next call to [computePackageMap].
   */
  Set<String> dependencies = new Set<String>();

  /**
   * Number of times [computePackageMap] has been called.
   */
  int computeCount = 0;

  @override
  PackageMapInfo computePackageMap(resource.Folder folder) {
    ++computeCount;
    if (packageMaps != null) {
      return new PackageMapInfo(packageMaps[folder.path], dependencies);
    }
    return new PackageMapInfo(packageMap, dependencies);
  }

  noSuchMethod(Invocation invocation) {
    // No other methods should be called.
    return super.noSuchMethod(invocation);
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

  List<Response> responsesReceived = [];
  List<Notification> notificationsReceived = [];
  bool _closed = false;

  MockServerChannel();
  @override
  void close() {
    _closed = true;
  }

  void expectMsgCount({responseCount: 0, notificationCount: 0}) {
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
    // Wrap send notification in future to simulate websocket
    // TODO(scheglov) ask Dan why and decide what to do
//    new Future(() => notificationController.add(notification));
    notificationController.add(notification);
  }

  /**
   * Simulate request/response pair.
   */
  Future<Response> sendRequest(Request request) {
    // No further requests should be sent after the connection is closed.
    if (_closed) {
      throw new Exception('sendRequest after connection closed');
    }
    // Wrap send request in future to simulate WebSocket.
    new Future(() => requestController.add(request));
    return waitForResponse(request);
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

  Future<Response> waitForResponse(Request request) {
    String id = request.id;
    return responseController.stream
        .firstWhere((response) => response.id == id);
  }
}

/**
 * A mock [WebSocket] for testing.
 */
class MockSocket<T> implements WebSocket {
  StreamController<T> controller = new StreamController<T>();
  MockSocket<T> twin;
  Stream<T> stream;

  MockSocket();

  factory MockSocket.pair() {
    MockSocket<T> socket1 = new MockSocket<T>();
    MockSocket<T> socket2 = new MockSocket<T>();
    socket1.twin = socket2;
    socket2.twin = socket1;
    socket1.stream = socket2.controller.stream;
    socket2.stream = socket1.controller.stream;
    return socket1;
  }

  void add(dynamic text) => controller.add(text as T);

  void allowMultipleListeners() {
    stream = stream.asBroadcastStream();
  }

  Future close([int code, String reason]) =>
      controller.close().then((_) => twin.controller.close());

  StreamSubscription<T> listen(void onData(dynamic event),
          {Function onError, void onDone(), bool cancelOnError}) =>
      stream.listen((T data) => onData(data),
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Stream<T> where(bool test(dynamic t)) => stream.where((T data) => test(data));
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
