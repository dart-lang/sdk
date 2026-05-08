// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/fake.dart';

/// Fake implementation of [DartRuntimeServiceBackend] that throws when
/// accessed.
///
/// Use when testing functionality of [DartRuntimeService] that does not require
/// a backend implementation.
base class FakeDartRuntimeServiceBackend extends Fake
    implements DartRuntimeServiceBackend {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {}

  @override
  Future<void> shutdown() async {}

  @override
  Future<void> clearState() async {}

  @override
  Future<void> onServerStarted({
    required Uri httpUri,
    required Uri wsUri,
  }) async {}

  @override
  UnmodifiableListView<ServiceRpcHandler> get rpcs =>
      UnmodifiableListView(const []);

  @override
  UnmodifiableListView<RpcHandlerWithParameters> get fallbacks =>
      UnmodifiableListView(const []);

  @override
  DartRuntimeService get frontend => throw UnimplementedError();

  @override
  IsolateManager get isolateManager => throw UnimplementedError();

  @override
  ExpressionEvaluator? get expressionEvaluator => null;

  @override
  void onStreamCancel({required String streamId}) {}

  @override
  bool onStreamListen({
    required String streamId,
    required Map<String, Object?> params,
  }) {
    return true;
  }
}
