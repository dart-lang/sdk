// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'dart_runtime_service.dart';

/// A backend implementation of a service used to inject non-common
/// functionality into a [DartRuntimeService].
abstract class DartRuntimeServiceBackend {
  /// Invoked by the [DartRuntimeService] when the service is initializing,
  /// before the service's HTTP server is started.
  ///
  /// The backend should not expect for this to be invoked more than once.
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

  /// Invoked by the [DartRuntimeService] to register handlers for the RPCs
  /// provided by the backend.
  void registerRpcs(json_rpc.Peer clientPeer);

  /// Invoked by the [DartRuntimeService] to register fallback handlers
  /// provided by the backend.
  ///
  /// Backend fallbacks are executed after incoming RPC requests fail to match
  /// any registered RPCs or service extensions provided by other clients.
  void registerFallbacks(json_rpc.Peer clientPeer);
}
