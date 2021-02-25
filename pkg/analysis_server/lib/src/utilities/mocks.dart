// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/context_root.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

/// A mock [ServerCommunicationChannel] for testing [AnalysisServer].
class MockServerChannel implements ServerCommunicationChannel {
  StreamController<Request> requestController = StreamController<Request>();
  StreamController<Response> responseController =
      StreamController<Response>.broadcast();
  StreamController<Notification> notificationController =
      StreamController<Notification>(sync: true);
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
  void listen(void Function(Request request) onRequest,
      {Function onError, void Function() onDone}) {
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
      errorCompleter.completeError(ServerError(notification.params['message']),
          StackTrace.fromString(notification.params['stackTrace']));
    }
    // Wrap send notification in future to simulate websocket
    // TODO(scheglov) ask Dan why and decide what to do
//    new Future(() => notificationController.add(notification));
    notificationController.add(notification);
  }

  /// Send the given [request] to the server and return a future that will
  /// complete when a response associated with the [request] has been received.
  /// The value of the future will be the received response. If [throwOnError] is
  /// `true` (the default) then the returned future will throw an exception if a
  /// server error is reported before the response has been received.
  Future<Response> sendRequest(Request request, {bool throwOnError = true}) {
    // TODO(brianwilkerson) Attempt to remove the `throwOnError` parameter and
    // have the default behavior be the only behavior.
    // No further requests should be sent after the connection is closed.
    if (_closed) {
      throw Exception('sendRequest after connection closed');
    }
    // Wrap send request in future to simulate WebSocket.
    Future(() => requestController.add(request));
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
    Future(() => responseController.add(response));
  }

  /// Return a future that will complete when a response associated with the
  /// given [request] has been received. The value of the future will be the
  /// received response. If [throwOnError] is `true` (the default) then the
  /// returned future will throw an exception if a server error is reported
  /// before the response has been received.
  ///
  /// Unlike [sendRequest], this method assumes that the [request] has already
  /// been sent to the server.
  Future<Response> waitForResponse(Request request,
      {bool throwOnError = true}) {
    // TODO(brianwilkerson) Attempt to remove the `throwOnError` parameter and
    // have the default behavior be the only behavior.
    var id = request.id;
    var response =
        responseController.stream.firstWhere((response) => response.id == id);
    if (throwOnError) {
      errorCompleter = Completer<Response>();
      try {
        return Future.any([response, errorCompleter.future]);
      } finally {
        errorCompleter = null;
      }
    }
    return response;
  }
}

class ServerError implements Exception {
  final String message;

  ServerError(this.message);

  @override
  String toString() {
    return 'Server Error: $message';
  }
}

/// A plugin manager that simulates broadcasting requests to plugins by
/// hard-coding the responses.
class TestPluginManager implements PluginManager {
  plugin.AnalysisSetPriorityFilesParams analysisSetPriorityFilesParams;
  plugin.AnalysisSetSubscriptionsParams analysisSetSubscriptionsParams;
  plugin.AnalysisUpdateContentParams analysisUpdateContentParams;
  plugin.RequestParams broadcastedRequest;
  Map<PluginInfo, Future<plugin.Response>> broadcastResults;

  @override
  List<PluginInfo> plugins = [];

  StreamController<void> pluginsChangedController =
      StreamController.broadcast();

  @override
  String get byteStorePath {
    fail('Unexpected invocation of byteStorePath');
  }

  @override
  InstrumentationService get instrumentationService {
    fail('Unexpected invocation of instrumentationService');
  }

  @override
  AbstractNotificationManager get notificationManager {
    fail('Unexpected invocation of notificationManager');
  }

  @override
  Stream<void> get pluginsChanged => pluginsChangedController.stream;

  @override
  ResourceProvider get resourceProvider {
    fail('Unexpected invocation of resourceProvider');
  }

  @override
  String get sdkPath {
    fail('Unexpected invocation of sdkPath');
  }

  @override
  Future<void> addPluginToContextRoot(
      analyzer.ContextRoot contextRoot, String path) async {
    fail('Unexpected invocation of addPluginToContextRoot');
  }

  @override
  Map<PluginInfo, Future<plugin.Response>> broadcastRequest(
      plugin.RequestParams params,
      {analyzer.ContextRoot contextRoot}) {
    broadcastedRequest = params;
    return broadcastResults ?? <PluginInfo, Future<plugin.Response>>{};
  }

  @override
  Future<List<Future<plugin.Response>>> broadcastWatchEvent(
      WatchEvent watchEvent) async {
    return <Future<plugin.Response>>[];
  }

  @override
  List<String> pathsFor(String pluginPath) {
    fail('Unexpected invocation of pathsFor');
  }

  @override
  List<PluginInfo> pluginsForContextRoot(analyzer.ContextRoot contextRoot) {
    fail('Unexpected invocation of pluginsForContextRoot');
  }

  @override
  void recordPluginFailure(String hostPackageName, String message) {
    fail('Unexpected invocation of recordPluginFailure');
  }

  @override
  void removedContextRoot(analyzer.ContextRoot contextRoot) {
    fail('Unexpected invocation of removedContextRoot');
  }

  @override
  Future<void> restartPlugins() async {
    // Nothing to restart.
    return null;
  }

  @override
  void setAnalysisSetPriorityFilesParams(
      plugin.AnalysisSetPriorityFilesParams params) {
    analysisSetPriorityFilesParams = params;
  }

  @override
  void setAnalysisSetSubscriptionsParams(
      plugin.AnalysisSetSubscriptionsParams params) {
    analysisSetSubscriptionsParams = params;
  }

  @override
  void setAnalysisUpdateContentParams(
      plugin.AnalysisUpdateContentParams params) {
    analysisUpdateContentParams = params;
  }

  @override
  Future<List<void>> stopAll() async {
    fail('Unexpected invocation of stopAll');
  }
}
