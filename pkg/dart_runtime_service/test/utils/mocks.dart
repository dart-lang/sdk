// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service_io.dart';

/// Minimal [DartRuntimeServiceBackend] implementation with no-op lifecycle
/// hooks and `dart:io` HTTP server support.
///
/// Use when testing functionality of [DartRuntimeService] that does not require
/// a full backend implementation.
base class FakeDartRuntimeServiceBackend extends DartRuntimeServiceBackend
    with DartRuntimeServiceIoBackend {
  FakeDartRuntimeServiceBackend({required super.frontend});

  @override
  Future<void> initialize() async {}

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {}

  @override
  Future<void> shutdown() async {}

  @override
  Future<void> clearState() async {}

  @override
  Future<void> onServerStarted() async {}

  @override
  Future<void> onServerShutdown() async {}

  @override
  UnmodifiableListView<ServiceRpcHandler> get rpcs =>
      UnmodifiableListView(const []);

  @override
  UnmodifiableListView<RpcHandlerWithParameters> get fallbacks =>
      UnmodifiableListView(const []);

  @override
  IsolateManager get isolateManager => throw UnimplementedError();

  @override
  ExpressionEvaluator? get expressionEvaluator => null;

  @override
  ClientManager<DartRuntimeServiceBackend> clientManagerBuilder() {
    return ClientManager(
      backend: this,
      eventStreamMethods: frontend.eventStreams,
    );
  }

  @override
  Future<void> onStreamCancel({required String streamId}) async {}

  @override
  Future<void> onClientSubscribe(
    Client client,
    String streamId, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {}

  @override
  void onClientUnsubscribe(Client client, String streamId) {}

  @override
  Future<bool> onStreamListen({
    required String streamId,
    required Map<String, Object?> params,
  }) async => true;
}
