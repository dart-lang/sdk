// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

/// A helper class which handles `evaluate` and `evaluateInFrame` calls by
/// potentially forwarding compilation requests to an external compilation
/// service like Flutter Tools.
class _ExpressionEvaluator {
  _ExpressionEvaluator(this.dds);

  Future<Map<String, dynamic>> execute(json_rpc.Parameters parameters) async {
    _DartDevelopmentServiceClient externalClient =
        dds.clientManager.findFirstClientThatHandlesService(
      'compileExpression',
    );
    // If no compilation service is registered, just forward to the VM service.
    if (externalClient == null) {
      return await dds._vmServiceClient.sendRequest(
        parameters.method,
        parameters.value,
      );
    }

    final isolateId = parameters['isolateId'].asString;
    final expression = parameters['expression'].asString;
    Map<String, dynamic> buildScopeResponse;

    try {
      buildScopeResponse = await _buildScope(parameters);
    } on json_rpc.RpcException catch (e) {
      throw _RpcErrorCodes.buildRpcException(
        _RpcErrorCodes.kExpressionCompilationError,
        data: e.data,
      );
    }
    String kernelBase64;
    try {
      kernelBase64 =
          await _compileExpression(isolateId, expression, buildScopeResponse);
    } on json_rpc.RpcException catch (e) {
      throw _RpcErrorCodes.buildRpcException(
        _RpcErrorCodes.kExpressionCompilationError,
        data: e.data,
      );
    }
    return await _evaluateCompiledExpression(
        parameters, isolateId, kernelBase64);
  }

  Future<Map<String, dynamic>> _buildScope(
      json_rpc.Parameters parameters) async {
    final params = _setupParams(parameters);
    params['isolateId'] = parameters['isolateId'].asString;
    if (parameters['scope'].asMapOr(null) != null) {
      params['scope'] = parameters['scope'].asMap;
    }
    return await dds._vmServiceClient.sendRequest(
      '_buildExpressionEvaluationScope',
      params,
    );
  }

  Future<String> _compileExpression(String isolateId, String expression,
      Map<String, dynamic> buildScopeResponseResult) async {
    _DartDevelopmentServiceClient externalClient =
        dds.clientManager.findFirstClientThatHandlesService(
      'compileExpression',
    );
    if (externalClient == null) {
      throw _RpcErrorCodes.buildRpcException(
          _RpcErrorCodes.kExpressionCompilationError,
          data: 'compileExpression service disappeared.');
    }

    final compileParams = <String, dynamic>{
      'isolateId': isolateId,
      'expression': expression,
      'definitions': buildScopeResponseResult['param_names'],
      'typeDefinitions': buildScopeResponseResult['type_params_names'],
      'libraryUri': buildScopeResponseResult['libraryUri'],
      'isStatic': buildScopeResponseResult['isStatic'],
    };

    final klass = buildScopeResponseResult['klass'];
    if (klass != null) {
      compileParams['klass'] = klass;
    }
    try {
      return (await externalClient.sendRequest(
        'compileExpression',
        compileParams,
      ))['kernelBytes'];
    } on json_rpc.RpcException catch (e) {
      throw _RpcErrorCodes.buildRpcException(
        _RpcErrorCodes.kExpressionCompilationError,
        data: e.data,
      );
    }
  }

  Future<Map<String, dynamic>> _evaluateCompiledExpression(
    json_rpc.Parameters parameters,
    String isolateId,
    String kernelBase64,
  ) async {
    final params = _setupParams(parameters);
    params['isolateId'] = isolateId;
    params['kernelBytes'] = kernelBase64;
    params['disableBreakpoints'] =
        parameters['disableBreakpoints'].asBoolOr(false);
    if (parameters['scope'].asMapOr(null) != null) {
      params['scope'] = parameters['scope'].asMap;
    }
    return await dds._vmServiceClient.sendRequest(
      '_evaluateCompiledExpression',
      params,
    );
  }

  Map<String, dynamic> _setupParams(json_rpc.Parameters parameters) {
    if (parameters.method == 'evaluateInFrame') {
      return <String, dynamic>{
        'frameIndex': parameters['frameIndex'].asInt,
      };
    } else {
      assert(parameters.method == 'evaluate');
      return <String, dynamic>{
        'targetId': parameters['targetId'].asString,
      };
    }
  }

  final _DartDevelopmentService dds;
}
