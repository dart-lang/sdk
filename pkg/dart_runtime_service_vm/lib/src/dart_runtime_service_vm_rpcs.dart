// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc_2;
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

import '../dart_runtime_service_vm.dart';
import 'native_bindings.dart';
import 'vm_clients.dart';

/// Implementations of RPCs specific to the VM service that are not handled
/// in runtime/vm/service.cc.
final class DartRuntimeServiceVmRpcs {
  DartRuntimeServiceVmRpcs({required this.backend});

  final _logger = Logger('$DartRuntimeServiceVmRpcs');
  final _nativeBindings = NativeBindings();
  final DartRuntimeServiceVMBackend backend;

  static const _kGetSupportedProtocols = 'getSupportedProtocols';
  static const _kCreateIdZone = 'createIdZone';
  static const _kDeleteIdZone = 'deleteIdZone';
  static const _kStreamCpuSamplesWithUserTag = 'streamCpuSamplesWithUserTag';

  static const _kIsolateId = 'isolateId';
  static const _kIdZoneId = 'idZoneId';
  static const _kUserTags = 'userTags';

  late final rpcs = UnmodifiableListView<ServiceRpcHandler>([
    (_kGetSupportedProtocols, getSupportedProtocols),
    (_kCreateIdZone, createIdZone),
    (_kDeleteIdZone, deleteIdZone),
    (_kStreamCpuSamplesWithUserTag, streamCpuSamplesWithUserTag),
  ]);

  /// Returns the list of protocols implemented by the service.
  ///
  /// VM service middleware like DDS should intercept this RPC and add their
  /// own information to the response.
  Future<RpcResponse> getSupportedProtocols() async {
    final version = Version.parse(
      await _nativeBindings.sendToVM(method: 'getVersion', params: const {}),
    );
    if (version == null) {
      _logger.warning('Unable to retrieve version for getSupportedProtocols.');
      RpcException.internalError.throwException();
    }

    return ProtocolList(
      protocols: [
        Protocol(
          protocolName: 'VM Service',
          major: version.major,
          minor: version.minor,
        ),
      ],
    ).toJson();
  }

  /// Creates a new [IdZone] where temporary IDs for instances in the specified
  /// isolate may be allocated for [client].
  Future<RpcResponse> createIdZone(
    json_rpc_2.Parameters parameters,
    Client client,
  ) async {
    // The implementation of this RPC is in the VM, but we track which zones
    // have been created by individual clients so we can clean them up when the
    // clients disconnect.
    final result = await backend.sendToRuntime(parameters);
    final idZone = IdZone.parse(result);
    if (idZone != null) {
      final isolateId = parameters[_kIsolateId].asString;
      final vmClient = client as VmClient;
      vmClient.registerIdZone(isolateId: isolateId, idZone: idZone);
    }
    return result;
  }

  /// Destroys an [IdZone] owned by [client].
  Future<RpcResponse> deleteIdZone(
    json_rpc_2.Parameters parameters,
    Client client,
  ) async {
    // The implementation of this RPC is in the VM, but we track which zones
    // have been created by individual clients so we can clean them up when the
    // clients disconnect.
    final result = await backend.sendToRuntime(parameters);
    final vmClient = client as VmClient;
    vmClient.unregisterIdZone(
      isolateId: parameters[_kIsolateId].asString,
      idZoneId: parameters[_kIdZoneId].asString,
    );
    return result;
  }

  /// The `streamCpuSamplesWithUserTag` RPC is deprecated and calling it will
  /// cause no effect.
  // TODO(https://github.com/dart-lang/sdk/issues/63094): remove for protocol
  // version 5.0.
  Future<RpcResponse> streamCpuSamplesWithUserTag(
    json_rpc_2.Parameters parameters,
  ) async {
    parameters[_kUserTags].asList;
    return Success().toJson();
  }
}
