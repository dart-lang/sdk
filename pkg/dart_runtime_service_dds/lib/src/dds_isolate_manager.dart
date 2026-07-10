// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'dds_backend.dart';

/// An [IsolateManager] implementation for DDS.
final class DdsIsolateManager extends IsolateManager {
  /// Creates a new [DdsIsolateManager] for [backend] using [vmServiceClient].
  DdsIsolateManager({required this.backend, required this.vmServiceClient});

  /// The [DartRuntimeServiceDdsBackend] associated with this isolate manager.
  final DartRuntimeServiceDdsBackend backend;

  /// The [vm.VmService] client connection to the target VM Service.
  final vm.VmService vmServiceClient;

  /// Initializes isolate tracking for the target VM Service.
  Future<void> initializeIsolates() async {
    // No-op for now.
  }

  @override
  Future<RpcResponse> sendToIsolate({
    required String method,
    required Map<String, Object?> params,
  }) {
    throw UnimplementedError(
      'sendToIsolate is not implemented in DdsIsolateManager.',
    );
  }
}
