// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:frontend_server/resident_frontend_server_utils.dart'
    as frontend_server;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../dart_runtime_service_vm.dart';

typedef ExpressionEvaluationScope = Map<String, Object?>;

/// A helper class which handles `evaluate` and `evaluateInFrame` calls by
/// potentially forwarding compilation requests to an external compilation
/// service like Flutter Tools.
final class VmExpressionEvaluator extends ExpressionEvaluator {
  VmExpressionEvaluator({required super.clients, required this.backend});

  // RPCs.
  static const kInternalCompileExpressionRpc = '_compileExpression';
  static const kBuildScopeRpc = '_buildExpressionEvaluationScope';
  static const kEvaluateCompiledExpressionRpc = '_evaluateCompiledExpression';

  final DartRuntimeServiceVMBackend backend;

  @override
  Future<ExpressionEvaluationScope> buildScope({
    required String isolateId,
    int? frameIndex,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    try {
      return await backend.sendToRuntime(
        json_rpc.Parameters(kBuildScopeRpc, {
          ExpressionEvaluator.kIsolateId: isolateId,
          ExpressionEvaluator.kFrameIndex: ?frameIndex,
          ExpressionEvaluator.kTargetId: ?targetId,
          ExpressionEvaluator.kScope: ?scope,
        }),
      );
    } on json_rpc.RpcException catch (e) {
      logger.warning('Failed to build scope: $e.');
      RpcException.expressionCompilationError.throwException(data: e.data);
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
  }) {
    final params = <String, Object?>{
      ExpressionEvaluator.kIsolateId: isolateId,
      ExpressionEvaluator.kExpression: expression,
      ExpressionEvaluator.kScope: ?scope,
      ExpressionEvaluator.kFrameIndex: ?frameIndex,
      ExpressionEvaluator.kTargetId: ?targetId,
      ExpressionEvaluator.kDisableBreakpoints: ?disableBreakpoints,
      ExpressionEvaluator.kIdZoneId: ?idZoneId,
      ExpressionEvaluator.kKernelBytes: kernelBase64,
    };
    return backend.sendToRuntime(
      json_rpc.Parameters(kEvaluateCompiledExpressionRpc, params),
    );
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
  }) async {
    final scopeResult = await buildScope(
      isolateId: isolateId,
      frameIndex: frameIndex,
      targetId: targetId,
      scope: scope,
    );
    final kernelBase64 = await _compileExpressionLocally(
      isolateId,
      expression,
      scopeResult,
    );
    return await evaluateCompiledExpression(
      disableBreakpoints: disableBreakpoints,
      expression: expression,
      frameIndex: frameIndex,
      idZoneId: idZoneId,
      isolateId: isolateId,
      kernelBase64: kernelBase64,
      scope: scope,
      targetId: targetId,
    );
  }

  Future<String> _compileExpressionLocally(
    String isolateId,
    String expression,
    ExpressionEvaluationScope scope,
  ) async {
    final commonParams = <String, Object?>{
      ExpressionEvaluator.kExpression: expression,
      ExpressionEvaluator.kDefinitions: scope[ExpressionEvaluator.kParamNames],
      ExpressionEvaluator.kDefinitionTypes:
          scope[ExpressionEvaluator.kParamTypes],
      ExpressionEvaluator.kTypeDefinitions:
          scope[ExpressionEvaluator.kTypeParamsNames],
      ExpressionEvaluator.kTypeBounds:
          scope[ExpressionEvaluator.kTypeParamsBounds],
      ExpressionEvaluator.kTypeDefaults:
          scope[ExpressionEvaluator.kTypeParamsDefaults],
      ExpressionEvaluator.kLibraryUri: scope[ExpressionEvaluator.kLibraryUri],
      ExpressionEvaluator.kIsStatic: scope[ExpressionEvaluator.kIsStatic],
      ExpressionEvaluator.kMethod: ?scope[ExpressionEvaluator.kMethod],
      ExpressionEvaluator.kScriptUri: ?scope[ExpressionEvaluator.kScriptUri],
    };
    final compileParams = <String, Object?>{
      ExpressionEvaluator.kIsolateId: isolateId,
      ExpressionEvaluator.kTokenPos: scope[ExpressionEvaluator.kTokenPos],
      ExpressionEvaluator.kKlass: ?scope[ExpressionEvaluator.kKlass],
      ...commonParams,
    };

    RpcResponse result;
    try {
      if (backend.residentCompilerInfoFile?.existsSync() ?? false) {
        logger.info('Using resident frontend server for compilation.');
        result = await _compileExpressionWithResidentFrontendServer(
          commonParams: commonParams,
          scope: scope,
        );
      } else {
        result = await backend.sendToRuntime(
          json_rpc.Parameters(kInternalCompileExpressionRpc, compileParams),
        );
      }
      if (result case {
        ExpressionEvaluator.kKernelBytes: final String kernelBytes,
      }) {
        return kernelBytes;
      }
      RpcException.internalError.throwException();
    } on json_rpc.RpcException catch (e) {
      logger.warning('Failed to compile expression: $e (${e.data}).');
      RpcException.expressionCompilationError.throwException(data: e.data);
    }
  }

  Future<RpcResponse> _compileExpressionWithResidentFrontendServer({
    required Map<String, Object?> commonParams,
    required Map<String, Object?> scope,
  }) async {
    final {
      ExpressionEvaluator.kExpression: expression as String,
      ExpressionEvaluator.kDefinitions: definitions as List<Object?>,
      ExpressionEvaluator.kDefinitionTypes: definitionTypes as List<Object?>,
      ExpressionEvaluator.kTypeDefinitions: typeDefinitions as List<Object?>,
      ExpressionEvaluator.kTypeBounds: typeBounds as List<Object?>,
      ExpressionEvaluator.kTypeDefaults: typeDefaults as List<Object?>,
      ExpressionEvaluator.kLibraryUri: libraryUri as String,
      ExpressionEvaluator.kIsStatic: isStatic as bool,
    } = commonParams;

    final method = commonParams[ExpressionEvaluator.kMethod] as String?;
    final scriptUri = commonParams[ExpressionEvaluator.kScriptUri] as String?;

    try {
      final result = await frontend_server.invokeCompileExpression(
        expression: expression,
        definitions: definitions.cast<String>(),
        definitionTypes: definitionTypes.cast<String>(),
        typeDefinitions: typeDefinitions.cast<String>(),
        typeBounds: typeBounds.cast<String>(),
        typeDefaults: typeDefaults.cast<String>(),
        libraryUri: libraryUri,
        klass: scope[ExpressionEvaluator.kKlass] as String?,
        method: method,
        offset: scope[ExpressionEvaluator.kTokenPos] as int,
        scriptUri: scriptUri,
        isStatic: isStatic,
        rootLibraryUri: scope[ExpressionEvaluator.kRootLibraryUri] as String?,
        serverInfoFile: backend.residentCompilerInfoFile!,
      );
      return <String, Object?>{
        ExpressionEvaluator.kKernelBytes: result.kernelBytes,
      };
    } on frontend_server.CompileException catch (e) {
      RpcException.expressionCompilationError.throwExceptionWithDetails(
        details: e.message,
      );
    }
  }
}
