// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart' as vm;

import 'dds_backend.dart';

/// Handles DDS-specific RPCs that are not managed by a specific manager.
class DdsRpcHandlers {
  DdsRpcHandlers(this.backend);

  final DartRuntimeServiceDdsBackend backend;

  static const _kDdsProtocolName = 'DDS';
  static const _kDdsVersionMajor = 2;
  static const _kDdsVersionMinor = 1;

  static const _kGetDartDevelopmentServiceVersion =
      'getDartDevelopmentServiceVersion';
  static const _kGetSupportedProtocols = 'getSupportedProtocols';

  /// Returns the list of RPC handlers provided by DDS.
  UnmodifiableListView<ServiceRpcHandler> get rpcs => UnmodifiableListView([
    (_kGetDartDevelopmentServiceVersion, getDartDevelopmentServiceVersion),
    (_kGetSupportedProtocols, getSupportedProtocols),
  ]);

  /// RPC handler for `getDartDevelopmentServiceVersion`.
  Future<RpcResponse> getDartDevelopmentServiceVersion(
    json_rpc.Parameters parameters,
  ) async {
    return vm.Version(
      major: _kDdsVersionMajor,
      minor: _kDdsVersionMinor,
    ).toJson();
  }

  /// RPC handler for `getSupportedProtocols`.
  Future<RpcResponse> getSupportedProtocols(
    json_rpc.Parameters parameters,
  ) async {
    final protocolList = await backend.vmServiceClient.getSupportedProtocols();
    final protocols = protocolList.protocols ??= <vm.Protocol>[];
    protocols.add(
      vm.Protocol(
        protocolName: _kDdsProtocolName,
        major: _kDdsVersionMajor,
        minor: _kDdsVersionMinor,
      ),
    );
    return protocolList.toJson();
  }
}
