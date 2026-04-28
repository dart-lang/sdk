// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../dart_runtime_service_vm.dart';

typedef ExpressionEvaluationScope = Map<String, Object?>;

/// A helper class which handles `evaluate` and `evaluateInFrame` calls by
/// potentially forwarding compilation requests to an external compilation
/// service like Flutter Tools.
final class VmExpressionEvaluator extends ExpressionEvaluator {
  VmExpressionEvaluator({required super.clients, required this.backend});

  // RPCs.
  static const kExternalCompileExpressionRpc = 'compileExpression';
  static const kInternalCompileExpressionRpc = '_compileExpression';
  static const kBuildScopeRpc = '_buildExpressionEvaluationScope';
  static const kEvaluateCompiledExpressionRpc = '_evaluateCompiledExpression';

  // Common parameters.
  static const kIsolateId = 'isolateId';
  static const kExpression = 'expression';
  static const kScope = 'scope';
  static const kDisableBreakpoints = 'disableBreakpoints';

  // ID zone support.
  static const kIdZoneId = 'idZoneId';

  // `evaluate` specific parameters.
  static const kTargetId = 'targetId';

  // `evaluateInFrame` specific parameters.
  static const kFrameIndex = 'frameIndex';

  // Keys for compile expression RPC.
  static const kKernelBytes = 'kernelBytes';
  static const kDefinitions = 'definitions';
  static const kDefinitionTypes = 'definitionTypes';
  static const kTypeDefinitions = 'typeDefinitions';
  static const kTypeBounds = 'typeBounds';
  static const kTypeDefaults = 'typeDefaults';
  static const kLibraryUri = 'libraryUri';
  static const kTokenPos = 'tokenPos';
  static const kIsStatic = 'isStatic';
  static const kKlass = 'klass';
  static const kMethod = 'method';
  static const kScriptUri = 'scriptUri';

  // Keys for scope response.
  static const kParamNames = 'param_names';
  static const kParamTypes = 'param_types';
  static const kTypeParamsNames = 'type_params_names';
  static const kTypeParamsBounds = 'type_params_bounds';
  static const kTypeParamsDefaults = 'type_params_defaults';

  final DartRuntimeServiceVMBackend backend;

  @override
  Future<RpcResponse> evaluate(json_rpc.Parameters parameters) {
    return _execute(
      isolateId: parameters[kIsolateId].asString,
      expression: parameters[kExpression].asString,
      targetId: parameters[kTargetId].asString,
      frameIndex: null,
      scope: parameters[kScope].exists
          ? parameters[kScope].asMap.cast<String, String>()
          : null,
      disableBreakpoints: parameters[kDisableBreakpoints].exists
          ? parameters[kDisableBreakpoints].asBool
          : null,
      idZoneId: parameters[kIdZoneId].exists
          ? parameters[kIdZoneId].asString
          : null,
    );
  }

  @override
  Future<RpcResponse> evaluateInFrame(json_rpc.Parameters parameters) {
    return _execute(
      isolateId: parameters[kIsolateId].asString,
      expression: parameters[kExpression].asString,
      targetId: null,
      frameIndex: parameters[kFrameIndex].asInt,
      scope: parameters[kScope].exists
          ? parameters[kScope].asMap.cast<String, String>()
          : null,
      disableBreakpoints: parameters[kDisableBreakpoints].exists
          ? parameters[kDisableBreakpoints].asBool
          : null,
      idZoneId: parameters[kIdZoneId].exists
          ? parameters[kIdZoneId].asString
          : null,
    );
  }

  /// The common implementation of `evaluate` and `evaluateInFrame`.
  ///
  /// Parameters for each RPC are used by the VM when building the scope to
  /// determine whether or not we're executing in the context of a frame.
  /// Otherwise, the Dart implementation of each RPC is identical.
  Future<RpcResponse> _execute({
    required String isolateId,
    required String expression,
    required int? frameIndex,
    required String? targetId,
    required Map<String, String>? scope,
    required bool? disableBreakpoints,
    required String? idZoneId,
  }) async {
    final buildScopeResponse = await _buildScope(
      isolateId: isolateId,
      frameIndex: frameIndex,
      targetId: targetId,
      scope: scope,
    );
    final kernelBase64 = await _compileExpression(
      isolateId,
      expression,
      buildScopeResponse,
    );
    return await _evaluateCompiledExpression(
      isolateId: isolateId,
      expression: expression,
      frameIndex: frameIndex,
      targetId: targetId,
      scope: scope,
      disableBreakpoints: disableBreakpoints,
      idZoneId: idZoneId,
      kernelBase64: kernelBase64,
    );
  }

  Future<ExpressionEvaluationScope> _buildScope({
    required String isolateId,
    required int? frameIndex,
    required String? targetId,
    required Map<String, String>? scope,
  }) async {
    try {
      return await backend.sendToRuntime(
        json_rpc.Parameters(kBuildScopeRpc, {
          kIsolateId: isolateId,
          kFrameIndex: ?frameIndex,
          kTargetId: ?targetId,
          kScope: ?scope,
        }),
      );
    } on json_rpc.RpcException catch (e) {
      logger.warning('Failed to build scope: $e.');
      RpcException.expressionCompilationError.throwException(data: e.data);
    }
  }

  Future<String> _compileExpression(
    String isolateId,
    String expression,
    ExpressionEvaluationScope scope,
  ) async {
    final compileParams = <String, Object?>{
      kIsolateId: isolateId,
      kExpression: expression,
      kDefinitions: scope[kParamNames],
      kDefinitionTypes: scope[kParamTypes],
      kTypeDefinitions: scope[kTypeParamsNames],
      kTypeBounds: scope[kTypeParamsBounds],
      kTypeDefaults: scope[kTypeParamsDefaults],
      kLibraryUri: scope[kLibraryUri],
      kTokenPos: scope[kTokenPos],
      kIsStatic: scope[kIsStatic],
      kKlass: ?scope[kKlass],
      kMethod: ?scope[kMethod],
      kScriptUri: ?scope[kScriptUri],
    };

    final externalClient = clients.findFirstClientThatHandlesService(
      kExternalCompileExpressionRpc,
    );
    RpcResponse result;
    try {
      if (externalClient != null) {
        logger.info(
          'Found external $kExternalCompileExpressionRpc service: '
          '$externalClient',
        );
        result = await externalClient.sendRequest(
          method: kExternalCompileExpressionRpc,
          parameters: compileParams,
        );
      } else {
        result = await backend.sendToRuntime(
          json_rpc.Parameters(kInternalCompileExpressionRpc, compileParams),
        );
      }
      if (result case {kKernelBytes: final String kernelBytes}) {
        return kernelBytes;
      }
      RpcException.internalError.throwException();
    } on json_rpc.RpcException catch (e) {
      logger.warning('Failed to compile expression: $e (${e.data})}).');
      RpcException.expressionCompilationError.throwException(data: e.data);
    }
  }

  Future<RpcResponse> _evaluateCompiledExpression({
    required String isolateId,
    required String expression,
    required Map<String, String>? scope,
    required int? frameIndex,
    required String? targetId,
    required bool? disableBreakpoints,
    required String? idZoneId,
    required String kernelBase64,
  }) {
    final params = <String, Object?>{
      kIsolateId: isolateId,
      kExpression: expression,
      kScope: ?scope,
      kFrameIndex: ?frameIndex,
      kTargetId: ?targetId,
      kDisableBreakpoints: ?disableBreakpoints,
      kIdZoneId: ?idZoneId,
      kKernelBytes: kernelBase64,
    };
    return backend.sendToRuntime(
      json_rpc.Parameters(kEvaluateCompiledExpressionRpc, params),
    );
  }
}
