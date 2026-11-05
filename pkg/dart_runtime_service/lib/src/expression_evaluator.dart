// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import 'clients.dart';
import 'dart_runtime_service.dart';
import 'rpc_exceptions.dart';
import 'utils.dart';

/// A helper class which handles `evaluate` and `evaluateInFrame` calls by
/// potentially forwarding compilation requests to an external compilation
/// service like Flutter Tools.
abstract base class ExpressionEvaluator {
  ExpressionEvaluator({required this.clients});

  @protected
  final logger = Logger('$ExpressionEvaluator');

  /// The set of [Client]s connected to the service.
  final UnmodifiableClientNamedLookup clients;

  // External RPC name for compilation service.
  static const kExternalCompileExpressionRpc = 'compileExpression';

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
  static const kRootLibraryUri = 'rootLibraryUri';

  // Keys for scope response.
  static const kParamNames = 'param_names';
  static const kParamTypes = 'param_types';
  static const kTypeParamsNames = 'type_params_names';
  static const kTypeParamsBounds = 'type_params_bounds';
  static const kTypeParamsDefaults = 'type_params_defaults';

  /// The [evaluate] RPC is used to evaluate an expression in the context of
  /// some target.
  ///
  /// `targetId` may refer to a [Library], [Class], or [Instance].
  ///
  /// If `targetId` is a temporary ID which has expired, then an expired
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to an object which has been collected, then a
  /// collected [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then a collected
  /// [Sentinel] is returned.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object
  /// IDs. These bindings will be added to the scope in which the expression
  /// is evaluated, which is a child scope of the class or library for
  /// instance/class or library targets respectively. This means bindings
  /// provided in scope may shadow instance members, class members and top-level
  /// members.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If `idZoneId` is provided, temporary IDs for [InstanceRef]s and
  /// [Instance]s in the RPC response will be allocated in the specified ID
  /// zone. If `idZoneId` is omitted, ID allocations will be performed in the
  /// default ID zone for the isolate.
  ///
  /// If the expression fails to parse and compile, then
  /// [RpcException.expressionCompilationError] will be thrown.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef] will be
  /// returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] will be
  /// returned.
  Future<RpcResponse> evaluate(json_rpc.Parameters parameters) {
    return _execute(
      disableBreakpoints: parameters[kDisableBreakpoints].exists
          ? parameters[kDisableBreakpoints].asBool
          : null,
      expression: parameters[kExpression].asString,
      idZoneId: parameters[kIdZoneId].exists
          ? parameters[kIdZoneId].asString
          : null,
      isolateId: parameters[kIsolateId].asString,
      method: 'evaluate',
      scope: parameters[kScope].exists
          ? parameters[kScope].asMap.cast<String, String>()
          : null,
      targetId: parameters[kTargetId].asString,
    );
  }

  /// The [evaluateInFrame] RPC is used to evaluate an expression in the context
  /// of a particular stack frame.
  ///
  /// `frameIndex` is the index of the desired [Frame], with an index of 0
  /// indicating the top (most recent) frame.
  ///
  /// If `isolateId` refers to an isolate which has exited, then a collected
  /// [Sentinel] is returned.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object
  /// IDs. These bindings will be added to the scope in which the expression
  /// is evaluated, which is a child scope of the class or library for
  /// instance/class or library targets respectively. This means bindings
  /// provided in scope may shadow instance members, class members and top-level
  /// members.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If `idZoneId` is provided, temporary IDs for [InstanceRef]s and
  /// [Instance]s in the RPC response will be allocated in the specified ID
  /// zone. If `idZoneId` is omitted, ID allocations will be performed in the
  /// default ID zone for the isolate.
  ///
  /// If the expression fails to parse and compile, then
  /// [RpcException.expressionCompilationError] will be thrown.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef] will be
  /// returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] will be
  /// returned.
  Future<RpcResponse> evaluateInFrame(json_rpc.Parameters parameters) {
    return _execute(
      disableBreakpoints: parameters[kDisableBreakpoints].exists
          ? parameters[kDisableBreakpoints].asBool
          : null,
      expression: parameters[kExpression].asString,
      frameIndex: parameters[kFrameIndex].asInt,
      idZoneId: parameters[kIdZoneId].exists
          ? parameters[kIdZoneId].asString
          : null,
      isolateId: parameters[kIsolateId].asString,
      method: 'evaluateInFrame',
      scope: parameters[kScope].exists
          ? parameters[kScope].asMap.cast<String, String>()
          : null,
    );
  }

  /// The common implementation of `evaluate` and `evaluateInFrame`.
  ///
  /// Parameters for each RPC are used by the VM or target when building the
  /// scope to determine whether or not we're executing in the context of a
  /// frame. Otherwise, the compilation and evaluation pipeline is identical.
  Future<RpcResponse> _execute({
    required String expression,
    required String isolateId,
    required String method,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    final compileClient = clients.findFirstClientThatHandlesService(
      kExternalCompileExpressionRpc,
    );

    if (compileClient != null) {
      logger.info(
        'Found external $kExternalCompileExpressionRpc service: '
        '$compileClient',
      );
      final scopeResult = await buildScope(
        frameIndex: frameIndex,
        isolateId: isolateId,
        scope: scope,
        targetId: targetId,
      );

      final compileParams = buildCompileParams(
        expression: expression,
        isolateId: isolateId,
        scope: scopeResult,
      );

      RpcResponse compileResponse;
      try {
        compileResponse = await compileClient.sendRequest(
          method: kExternalCompileExpressionRpc,
          parameters: compileParams,
        );
      } on json_rpc.RpcException catch (e) {
        logger.warning('Failed to compile expression: $e (${e.data}).');
        RpcException.expressionCompilationError.throwException(data: e.data);
      }

      final kernelBase64 = switch (compileResponse) {
        {kKernelBytes: final String k} => k,
        {'result': final String k} => k,
        _ => null,
      };

      if (kernelBase64 == null) {
        RpcException.expressionCompilationError.throwException(
          data: compileResponse['error'],
        );
      }

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

    return await fallbackCompileAndEvaluate(
      disableBreakpoints: disableBreakpoints,
      expression: expression,
      frameIndex: frameIndex,
      idZoneId: idZoneId,
      isolateId: isolateId,
      method: method,
      scope: scope,
      targetId: targetId,
    );
  }

  /// Builds the scope information for the evaluation context.
  @protected
  Future<Map<String, Object?>> buildScope({
    required String isolateId,
    int? frameIndex,
    Map<String, String>? scope,
    String? targetId,
  });

  /// Evaluates a compiled expression given its [kernelBase64] kernel bytecode.
  @protected
  Future<RpcResponse> evaluateCompiledExpression({
    required String expression,
    required String isolateId,
    required String kernelBase64,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  });

  /// Fallback compilation and evaluation when no external compiler is
  /// registered.
  @protected
  Future<RpcResponse> fallbackCompileAndEvaluate({
    required String expression,
    required String isolateId,
    required String method,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  });

  /// Builds the compilation parameters map from the scope response.
  @protected
  Map<String, Object?> buildCompileParams({
    required String expression,
    required String isolateId,
    required Map<String, Object?> scope,
  }) {
    final compileParams = <String, Object?>{
      kDefinitions: scope[kParamNames],
      kDefinitionTypes: scope[kParamTypes],
      kExpression: expression,
      kIsolateId: isolateId,
      kIsStatic: scope[kIsStatic],
      kLibraryUri: scope[kLibraryUri],
      kMethod: scope[kMethod],
      kTokenPos: scope[kTokenPos],
      kTypeBounds: scope[kTypeParamsBounds],
      kTypeDefaults: scope[kTypeParamsDefaults],
      kTypeDefinitions: scope[kTypeParamsNames],
    };

    final klass = scope[kKlass];
    if (klass != null) {
      compileParams[kKlass] = klass;
    }
    final scriptUri = scope[kScriptUri];
    if (scriptUri != null) {
      compileParams[kScriptUri] = scriptUri;
    }
    return compileParams;
  }
}
