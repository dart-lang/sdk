// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/operation/operation_analysis.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' as resource;
import 'package:analyzer/file_system/memory_file_system.dart' as resource;
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:typed_mock/typed_mock.dart';

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
 * Returns a [Future] that completes after pumping the event queue [times]
 * times. By default, this should pump the event queue enough times to allow
 * any code to run, as long as it's not waiting on some external event.
 */
Future pumpEventQueue([int times = 5000]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

typedef void MockServerOperationPerformFunction(AnalysisServer server);

class MockAnalysisContext extends StringTypedMock implements AnalysisContext {
  MockAnalysisContext(String name) : super(name);
}

class MockClassElement extends TypedMock implements ClassElement {
  final ElementKind kind = ElementKind.CLASS;
}

class MockCompilationUnitElement extends TypedMock
    implements CompilationUnitElement {
  final ElementKind kind = ElementKind.COMPILATION_UNIT;
}

class MockConstructorElement extends TypedMock implements ConstructorElement {
  final kind = ElementKind.CONSTRUCTOR;
}

class MockElement extends StringTypedMock implements Element {
  MockElement([String name = '<element>']) : super(name);

  @override
  String get displayName => _toString;

  @override
  String get name => _toString;
}

class MockFieldElement extends TypedMock implements FieldElement {
  final ElementKind kind = ElementKind.FIELD;
}

class MockFunctionElement extends TypedMock implements FunctionElement {
  final ElementKind kind = ElementKind.FUNCTION;
}

class MockFunctionTypeAliasElement extends TypedMock
    implements FunctionTypeAliasElement {
  final ElementKind kind = ElementKind.FUNCTION_TYPE_ALIAS;
}

class MockImportElement extends TypedMock implements ImportElement {
  final ElementKind kind = ElementKind.IMPORT;
}

class MockLibraryElement extends TypedMock implements LibraryElement {
  final ElementKind kind = ElementKind.LIBRARY;
}

class MockLocalVariableElement extends TypedMock
    implements LocalVariableElement {
  final ElementKind kind = ElementKind.LOCAL_VARIABLE;
}

class MockLogger extends TypedMock implements Logger {}

class MockMethodElement extends StringTypedMock implements MethodElement {
  final kind = ElementKind.METHOD;
  MockMethodElement([String name = 'method']) : super(name);
}

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

class MockParameterElement extends TypedMock implements ParameterElement {
  final ElementKind kind = ElementKind.PARAMETER;
}

class MockPropertyAccessorElement extends TypedMock
    implements PropertyAccessorElement {
  final ElementKind kind;
  MockPropertyAccessorElement(this.kind);
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
    return new Future<Response>(() => responseController.stream
        .firstWhere((response) => response.id == id) as Future<Response>);
  }
}

/**
 * A mock [ServerOperation] for testing [AnalysisServer].
 */
class MockServerOperation implements PerformAnalysisOperation {
  final ServerOperationPriority priority;
  final MockServerOperationPerformFunction _perform;

  MockServerOperation(this.priority, this._perform);

  @override
  AnalysisContext get context => null;

  @override
  bool get isContinue => false;

  @override
  void perform(AnalysisServer server) => this._perform(server);
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
  MockSource([String name = 'mocked.dart']) : super(name);
}

class MockTopLevelVariableElement extends TypedMock
    implements TopLevelVariableElement {
  final ElementKind kind = ElementKind.TOP_LEVEL_VARIABLE;
}

class MockTypeParameterElement extends TypedMock
    implements TypeParameterElement {
  final ElementKind kind = ElementKind.TYPE_PARAMETER;
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

class StringTypedMock extends TypedMock {
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
