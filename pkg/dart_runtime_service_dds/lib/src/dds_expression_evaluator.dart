// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart' as vm;

import 'dds_backend.dart';
import 'rpc_extensions.dart';

/// A helper class which handles `evaluate` and `evaluateInFrame` calls by
/// potentially forwarding compilation requests to an external compilation
/// service like Flutter Tools.
final class DdsExpressionEvaluator extends ExpressionEvaluator {
  DdsExpressionEvaluator({required this.backend, required super.clients});

  /// The DDS backend providing VM service client access and DDS manager
  /// instances.
  final DartRuntimeServiceDdsBackend backend;

  @override
  Future<Map<String, Object?>> buildScope({
    required String isolateId,
    int? frameIndex,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    try {
      return await backend.vmServiceClient.buildExpressionEvaluationScope(
        frameIndex: frameIndex,
        isolateId: isolateId,
        scope: scope,
        targetId: targetId,
      );
    } on vm.RPCError catch (e) {
      logger.warning('Failed to build scope: $e.');
      throw json_rpc.RpcException(e.code, e.message, data: e.data);
    }
  }

  @override
  Future<RpcResponse> evaluateCompiledExpression({
    required String expression,
    required String isolateId,
    required String kernelBase64,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    try {
      return await backend.vmServiceClient.evaluateCompiledExpression(
        disableBreakpoints: disableBreakpoints,
        frameIndex: frameIndex,
        idZoneId: idZoneId,
        isolateId: isolateId,
        kernelBytes: kernelBase64,
        scope: scope,
        targetId: targetId,
      );
    } on vm.RPCError catch (e) {
      throw json_rpc.RpcException(e.code, e.message, data: e.data);
    }
  }

  @override
  Future<RpcResponse> fallbackCompileAndEvaluate({
    required String expression,
    required String isolateId,
    required String method,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  }) {
    return backend.callVmService(
      method,
      args: <String, Object?>{
        'disableBreakpoints': ?disableBreakpoints,
        'expression': expression,
        'frameIndex': ?frameIndex,
        'idZoneId': ?idZoneId,
        'isolateId': isolateId,
        'scope': ?scope,
        'targetId': ?targetId,
      },
    );
  }
}
