// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
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
  void registerRpcs(json_rpc.Peer clientPeer) {}

  @override
  void registerFallbacks(json_rpc.Peer clientPeer) {}
}
