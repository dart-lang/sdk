// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analysis_server/src/analysis_server.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/plugin/plugin_isolate.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/dart/analysis/context_root.dart' as analyzer;
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:watcher/watcher.dart';

/// A mock [ServerCommunicationChannel] for testing [AnalysisServer].
class MockServerChannel implements ServerCommunicationChannel {
  /// A controller for the stream of requests and responses from the client to
  /// the server.
  ///
  /// Messages added to this stream should be converted to/from JSON to ensure
  /// they are fully serialized/deserialized as they would be in a real server
  /// otherwise tests may receive real instances where in reality they would be
  /// maps.
  StreamController<RequestOrResponse> requestController =
      StreamController<RequestOrResponse>();

  /// A controller for the stream of requests and responses from the server to
  /// the client.
  ///
  /// Messages added to this stream should be converted to/from JSON to ensure
  /// they are fully serialized/deserialized as they would be in a real server
  /// otherwise tests may receive real instances where in reality they would be
  /// maps.
  StreamController<RequestOrResponse> responseController =
      StreamController<RequestOrResponse>.broadcast();

  /// A controller for the stream of notifications from the server to the
  /// client.
  ///
  /// Unlike [requestController] and [responseController], notifications added
  /// here are not round-tripped through JSON but instead have real class
  /// instances as their `params`. This is because they are only used by tests
  /// which will cast and/or switch on the types for convenience.
  StreamController<Notification> notificationController =
      StreamController<Notification>.broadcast(sync: true);

  Completer<Response>? errorCompleter;

  List<Response> responsesReceived = [];
  List<Notification> notificationsReceived = [];
  List<Request> serverRequestsSent = [];

  bool _closed = false;

  String? name;

  /// True if we are printing out messages exchanged with the server.
  final bool printMessages;

  MockServerChannel({bool? printMessages})
    : printMessages = printMessages ?? false;

  /// Return the broadcast stream of notifications.
  Stream<Notification> get notifications {
    return notificationController.stream;
  }

  @override
  Stream<RequestOrResponse> get requests => requestController.stream;

  /// Return the broadcast stream of server-to-client requests.
  Stream<Request> get serverToClientRequests {
    return responseController.stream.where((r) => r is Request).cast<Request>();
  }

  @override
  void close() {
    _closed = true;
  }

  @override
  void sendNotification(Notification notification) {
    // Don't deliver notifications after the connection is closed.
    if (_closed) {
      return;
    }

    notificationsReceived.add(notification);
    notificationController.add(notification);

    var errorCompleter = this.errorCompleter;
    if (errorCompleter != null && notification.event == 'server.error') {
      var params = notification.params!;
      print('[server.error] test: $name message: ${params['message']}');
      errorCompleter.completeError(
        ServerError(params['message'] as String),
        StackTrace.fromString(params['stackTrace'] as String),
      );
    }
  }

  @override
  void sendRequest(Request request) {
    var jsonString = jsonEncode(request.toJson());
    if (printMessages) {
      print('<== $jsonString');
    }

    // Round-trip via JSON to ensure all types are fully serialized as they
    // would be in a real setup.
    request = Request.fromJson(jsonDecode(jsonString) as Map<String, Object?>)!;

    serverRequestsSent.add(request);
    responseController.add(request);
  }

  @override
  void sendResponse(Response response) {
    // Don't deliver responses after the connection is closed.
    if (_closed) {
      return;
    }

    var jsonString = jsonEncode(response.toJson());
    if (printMessages) {
      print('<== $jsonString');
    }

    // Round-trip via JSON to ensure all types are fully serialized as they
    // would be in a real setup.
    response = Response.fromJson(
      jsonDecode(jsonString) as Map<String, Object?>,
    )!;

    responsesReceived.add(response);
    responseController.add(response);
  }

  /// Send the given [request] to the server as if it had been sent from the
  /// client, and return a future that will complete when a response associated
  /// with the [request] has been received.
  ///
  /// The value of the future will be the received response.
  Future<Response> simulateRequestFromClient(Request request) async {
    if (_closed) {
      throw Exception('simulateRequestFromClient after connection closed');
    }

    var jsonString = jsonEncode(request.toJson());
    if (printMessages) {
      print('==> $jsonString');
    }

    // Round-trip via JSON to ensure all types are fully serialized as they
    // would be in a real setup.
    request = Request.fromJson(jsonDecode(jsonString) as Map<String, Object?>)!;

    requestController.add(request);
    var response = await waitForResponse(request);

    // Round-trip via JSON to ensure all types are fully serialized as they
    // would be in a real setup.
    response = Response.fromJson(
      jsonDecode(jsonEncode(response)) as Map<String, Object?>,
    )!;

    return response;
  }

  /// Send the given [response] to the server as if it had been sent from the
  /// client.
  void simulateResponseFromClient(Response response) {
    // No further requests should be sent after the connection is closed.
    if (_closed) {
      throw Exception('simulateRequestFromClient after connection closed');
    }

    var jsonString = jsonEncode(response.toJson());
    if (printMessages) {
      print('==> $jsonString');
    }

    // Round-trip via JSON to ensure all types are fully serialized as they
    // would be in a real setup.
    response = Response.fromJson(
      jsonDecode(jsonString) as Map<String, Object?>,
    )!;

    requestController.add(response);
  }

  /// Return a future that will complete when a response associated with the
  /// given [request] has been received. The value of the future will be the
  /// received response.
  ///
  /// Unlike [simulateRequestFromClient], this method assumes that the [request]
  /// has already been sent to the server.
  Future<Response> waitForResponse(Request request) {
    var id = request.id;
    return responseController.stream
        .where((r) => r is Response)
        .cast<Response>()
        .firstWhere((response) => response.id == id);
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
  Map<PluginIsolate, Future<plugin.Response>>? broadcastResults;
  Map<PluginIsolate, Future<plugin.Response>>? Function(plugin.RequestParams)?
  handleRequest;
  Map<analyzer.ContextRoot, List<String>> contextRootPlugins = {};

  @override
  List<PluginIsolate> pluginIsolates = [];

  @override
  Completer<void> initializedCompleter = Completer();

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
  Map<PluginIsolate, Future<plugin.Response>> broadcastRequest(
    plugin.RequestParams params, {
    analyzer.ContextRoot? contextRoot,
  }) {
    broadcastedRequest = params;
    return handleRequest?.call(params) ?? broadcastResults ?? {};
  }

  @override
  List<Future<plugin.Response>> broadcastWatchEvent(WatchEvent watchEvent) {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw Exception('Unexpected invocation of ${invocation.memberName}');

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
