// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import 'clients.dart';
import 'dart_runtime_service.dart';
import 'dart_runtime_service_rpcs.dart';
import 'event_streams.dart';
import 'expression_evaluator.dart';
import 'isolate_manager.dart';

typedef OptionalHandler = FutureOr<Response?> Function(Request);

/// A backend implementation of a service used to inject non-common
/// functionality into a [DartRuntimeService].
abstract class DartRuntimeServiceBackend<IM extends IsolateManager> {
  DartRuntimeServiceBackend({required this.frontend});

  /// The active service frontend hosting this [DartRuntimeServiceBackend].
  final DartRuntimeService frontend;

  /// Manages and tracks the lifecycle of isolates for the backend.
  IM get isolateManager;

  /// Adds support for expression evaluation if non-null.
  ExpressionEvaluator? get expressionEvaluator => null;

  /// Used by [DartRuntimeService] to create a [ClientManager].
  ///
  /// Backend implementations should override this method and return their own
  /// [ClientManager] implementation if they require tracking additional state
  /// for each [Client].
  ClientManager<DartRuntimeServiceBackend<IM>> clientManagerBuilder() {
    return ClientManager(
      backend: this,
      eventStreamMethods: frontend.eventStreams,
    );
  }

  /// Invoked by the [DartRuntimeService] when the service is initializing,
  /// before the service's HTTP server is started.
  ///
  /// The backend should not expect for this to be invoked more than once.
  @mustCallSuper
  Future<void> initialize();

  /// Invoked by the [DartRuntimeService] once it has completely finished
  /// initializing.
  ///
  /// The backend should not expect for this to be invoked more than once.
  Future<void> onServiceReady(DartRuntimeService service);

  /// Invoked by the [DartRuntimeService] when the service is shutting down,
  /// allowing for the backend to clean up its state.
  ///
  /// The backend should not expect to be reinitialized after shutting down.
  Future<void> shutdown();

  /// Invoked by the [DartRuntimeService] when the service is no longer
  /// available, either due to the HTTP server being disabled or the service
  /// shutting down.
  ///
  /// This is always invoked immediately before [shutdown].
  Future<void> clearState();

  /// Invoked by the [DartRuntimeService] when the service's HTTP server has
  /// started.
  Future<void> onServerStarted({required Uri httpUri, required Uri wsUri});

  /// Invoked by the [DartRuntimeService] when the service's HTTP server has
  /// shutdown.
  Future<void> onServerShutdown();

  /// Invoked when [EventStreamManager.streamListen] is called and the first
  /// client has subscribed to [streamId].
  ///
  /// [params] contains all of the parameters sent as part of the
  /// `streamListen` request.
  ///
  /// Returns true when the stream was successfully listened to.
  bool onStreamListen({
    required String streamId,
    required Map<String, Object?> params,
  }) {
    return true;
  }

  /// Invoked when [EventStreamManager.streamCancel] is called and there are no
  /// more clients listening to [streamId].
  void onStreamCancel({required String streamId}) {}

  /// RPCs to be registered with the [DartRuntimeService].
  UnmodifiableListView<ServiceRpcHandler> get rpcs =>
      UnmodifiableListView(const []);

  /// Fallbacks to be registered with the [DartRuntimeService].
  ///
  /// Backend fallbacks are executed after incoming RPC requests fail to match
  /// any registered RPCs or service extensions provided by other clients.
  UnmodifiableListView<RpcHandlerWithParameters> get fallbacks =>
      UnmodifiableListView(const []);

  /// A custom handler for handling HTTP requests.
  ///
  /// This handler is invoked before attempting to execute the HTTP request as
  /// an RPC invocation or performing a redirection to a developer tool (e.g.,
  /// DevTools). Returning null from the handler indicates that the request was
  /// not handled by the custom handler.
  OptionalHandler get httpHandler =>
      (_) => null;
}
