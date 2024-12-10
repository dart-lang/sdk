// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/dart/analysis/context_root.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:matcher/expect.dart';
import 'package:watcher/watcher.dart';

/// A mock [ServerCommunicationChannel] for testing [AnalysisServer].
class MockServerChannel implements ServerCommunicationChannel {
  StreamController<RequestOrResponse> requestController =
      StreamController<RequestOrResponse>();
  StreamController<Response> responseController =
      StreamController<Response>.broadcast();
  StreamController<Notification> notificationController =
      StreamController<Notification>.broadcast(sync: true);
  Completer<Response>? errorCompleter;

  List<Response> responsesReceived = [];
  List<Notification> notificationsReceived = [];
  List<Request> serverRequestsSent = [];

  bool _closed = false;

  String? name;

  MockServerChannel();

  /// Return the broadcast stream of notifications.
  Stream<Notification> get notifications {
    return notificationController.stream;
  }

  @override
  Stream<RequestOrResponse> get requests => requestController.stream;

  @override
  void close() {
    _closed = true;
  }

  void expectMsgCount({responseCount = 0, notificationCount = 0}) {
    expect(responsesReceived, hasLength(responseCount));
    expect(notificationsReceived, hasLength(notificationCount));
  }

  @override
  void sendNotification(Notification notification) {
    // Don't deliver notifications after the connection is closed.
    if (_closed) {
      return;
    }
    notificationsReceived.add(notification);
    var errorCompleter = this.errorCompleter;
    if (errorCompleter != null && notification.event == 'server.error') {
      var params = notification.params!;
      print('[server.error] test: $name message: ${params['message']}');
      errorCompleter.completeError(
        ServerError(params['message'] as String),
        StackTrace.fromString(params['stackTrace'] as String),
      );
    }
    // Wrap send notification in future to simulate websocket
    // TODO(scheglov): ask Dan why and decide what to do
    //    new Future(() => notificationController.add(notification));
    notificationController.add(notification);
  }

  @override
  void sendRequest(Request request) {
    serverRequestsSent.add(request);
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

  /// Send the given [request] to the server as if it had been sent from the
  /// client, and return a future that will complete when a response associated
  /// with the [request] has been received.
  ///
  /// The value of the future will be the received response.
  Future<Response> simulateRequestFromClient(Request request) {
    if (_closed) {
      throw Exception('simulateRequestFromClient after connection closed');
    }
    // Wrap send request in future to simulate WebSocket.
    Future(() => requestController.add(request));
    return waitForResponse(request);
  }

  /// Send the given [response] to the server as if it had been sent from the
  /// client.
  Future<void> simulateResponseFromClient(Response response) {
    // No further requests should be sent after the connection is closed.
    if (_closed) {
      throw Exception('simulateRequestFromClient after connection closed');
    }
    // Wrap send request in future to simulate WebSocket.
    return Future(() => requestController.add(response));
  }

  /// Return a future that will complete when a response associated with the
  /// given [request] has been received. The value of the future will be the
  /// received response.
  ///
  /// Unlike [simulateRequestFromClient], this method assumes that the [request]
  /// has already been sent to the server.
  Future<Response> waitForResponse(Request request) {
    var id = request.id;
    return responseController.stream.firstWhere(
      (response) => response.id == id,
    );
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
  plugin.AnalysisSetPriorityFilesParams? analysisSetPriorityFilesParams;
  plugin.AnalysisSetSubscriptionsParams? analysisSetSubscriptionsParams;
  plugin.AnalysisUpdateContentParams? analysisUpdateContentParams;
  plugin.RequestParams? broadcastedRequest;
  Map<PluginInfo, Future<plugin.Response>>? broadcastResults;
  Map<PluginInfo, Future<plugin.Response>>? Function(plugin.RequestParams)?
  handleRequest;
  Map<analyzer.ContextRoot, List<String>> contextRootPlugins = {};

  @override
  List<PluginInfo> plugins = [];

  StreamController<void> pluginsChangedController =
      StreamController.broadcast();

  @override
  Stream<void> get pluginsChanged => pluginsChangedController.stream;

  @override
  Future<void> addPluginToContextRoot(
    analyzer.ContextRoot contextRoot,
    String path, {
    required bool isLegacyPlugin,
  }) async {
    contextRootPlugins.putIfAbsent(contextRoot, () => []).add(path);
  }

  @override
  Map<PluginInfo, Future<plugin.Response>> broadcastRequest(
    plugin.RequestParams params, {
    analyzer.ContextRoot? contextRoot,
  }) {
    broadcastedRequest = params;
    return handleRequest?.call(params) ?? broadcastResults ?? {};
  }

  @override
  Future<List<Future<plugin.Response>>> broadcastWatchEvent(
    WatchEvent watchEvent,
  ) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      fail('Unexpected invocation of ${invocation.memberName}');

  @override
  void removedContextRoot(analyzer.ContextRoot contextRoot) {
    contextRootPlugins.remove(contextRoot);
  }

  @override
  Future<void> restartPlugins() async {
    // Nothing to restart.
  }

  @override
  void setAnalysisSetPriorityFilesParams(
    plugin.AnalysisSetPriorityFilesParams params,
  ) {
    analysisSetPriorityFilesParams = params;
  }

  @override
  void setAnalysisSetSubscriptionsParams(
    plugin.AnalysisSetSubscriptionsParams params,
  ) {
    analysisSetSubscriptionsParams = params;
  }

  @override
  void setAnalysisUpdateContentParams(
    plugin.AnalysisUpdateContentParams params,
  ) {
    analysisUpdateContentParams = params;
  }
}
