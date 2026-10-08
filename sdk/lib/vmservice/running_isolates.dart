// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:_vmservice";

final class _CompileExpressionErrorDetails {
  final String details;

  _CompileExpressionErrorDetails(this.details);
}

class RunningIsolates implements MessageRouter {
  static const _isolateIdString = 'isolateId';

  final isolates = <int, RunningIsolate>{};
  int? _rootPortId;

  RunningIsolates();

  void isolateStartup(int portId, SendPort sp, String name) {
    if (_rootPortId == null) {
      _rootPortId = portId;
    }
    var ri = RunningIsolate(portId, sp, name);
    isolates[portId] = ri;
  }

  void isolateShutdown(int portId, SendPort sp) {
    if (_rootPortId == portId) {
      _rootPortId = null;
    }
    (isolates.remove(portId))?.onIsolateExit();
  }

  Future<Response> _handleReloadSourcesRequest(
    VMService service,
    Message message,
    RunningIsolate isolate,
  ) async {
    return isolate.routeRequest(service, message);
  }

  @override
  Future<Response> routeRequest(VMService service, Message message) {
    String isolateParam = message.params['isolateId']! as String;
    int isolateId;
    if (!isolateParam.startsWith('isolates/')) {
      message.setErrorResponse(
        kInvalidParams,
        "invalid 'isolateId' parameter: $isolateParam",
      );
      return message.response;
    }
    isolateParam = isolateParam.substring('isolates/'.length);
    if (isolateParam == 'root') {
      isolateId = _rootPortId!;
    } else {
      try {
        isolateId = int.parse(isolateParam);
      } catch (e) {
        message.setErrorResponse(
          kInvalidParams,
          "invalid 'isolateId' parameter: $isolateParam",
        );
        return message.response;
      }
    }
    final isolate = isolates[isolateId];
    if (isolate == null) {
      // There is some chance that this isolate may have lived before,
      // so return a sentinel rather than an error.
      final result = <String, String>{
        'type': 'Sentinel',
        'kind': 'Collected',
        'valueAsString': '<collected>',
      };
      message.setResponse(encodeResult(message, result));
      return message.response;
    }

    if (message.method == 'evaluateInFrame' || message.method == 'evaluate') {
      return _Evaluator(message, isolate, service).run();
    } else if (message.method == 'reloadSources') {
      return _handleReloadSourcesRequest(service, message, isolate);
    } else {
      return isolate.routeRequest(service, message);
    }
  }

  @override
  void routeResponse(Message message) {}
}

/// Class that knows how to orchestrate expression evaluation in dart2 world.
class _Evaluator {
  static const _kernelBytesString = 'kernelBytes';
  static const _compileExpressionString = 'compileExpression';
  static const _expressionString = 'expression';
  static const _definitionsString = 'definitions';
  static const _definitionTypesString = 'definitionTypes';
  static const _typeDefinitionsString = 'typeDefinitions';
  static const _typeBoundsString = 'typeBounds';
  static const _typeDefaultsString = 'typeDefaults';
  static const _libraryUriString = 'libraryUri';
  static const _tokenPosString = 'tokenPos';
  static const _isStaticString = 'isStatic';
  static const _scriptUriString = 'scriptUri';
  static const _methodString = 'method';
  static const _rootLibraryUriString = 'rootLibraryUri';

  _Evaluator(this._message, this._isolate, this._service);

  Future<Response> run() async {
    final buildScopeResponse = await _buildScope();
    final responseJson =
        buildScopeResponse.decodeJson() as Map<String, dynamic>;

    if (responseJson.containsKey('error')) {
      final error = responseJson['error'] as Map<String, dynamic>;
      final data = error['data'] as Map<String, dynamic>;
      return Response.from(
        encodeCompilationError(_message, data['details'] as String),
      );
    }

    String kernelBase64;
    try {
      kernelBase64 = await _compileExpression(
        responseJson['result'] as Map<String, dynamic>,
      );
    } on _CompileExpressionErrorDetails catch (e) {
      return Response.from(
        encodeRpcError(
          _message,
          kExpressionCompilationError,
          details: e.details,
        ),
      );
    }
    return await _evaluateCompiledExpression(kernelBase64);
  }

  Message _message;
  RunningIsolate _isolate;
  VMService _service;

  Future<Response> _buildScope() {
    final params = _setupParams();
    params['isolateId'] = _message.params['isolateId'];
    final buildScopeParams = <String, dynamic>{
      'method': '_buildExpressionEvaluationScope',
      'id': _message.serial,
      'params': params,
    };
    if (_message.params['scope'] != null) {
      (buildScopeParams['params'] as Map<String, dynamic>)['scope'] =
          _message.params['scope'];
    }
    final buildScope = Message._fromJsonRpcRequest(
      _message.client!,
      buildScopeParams,
    );

    // Decode the JSON and insert it into the map. The map key
    // is the request Uri.
    return _isolate.routeRequest(_service, buildScope);
  }

  /// If [response] represents a valid JSON-RPC result, then this function
  /// returns the 'kernelBytes' property of that result. Otherwise, this
  /// function throws a [_CompileExpressionErrorDetails] object wrapping the
  /// 'details' property of the JSON-RPC error.
  static String _getKernelBytesOrThrowErrorDetails(
    Map<String, dynamic> response,
  ) {
    if (response['result'] != null) {
      return (response['result'] as Map<String, dynamic>)[_kernelBytesString]
          as String;
    }
    final error = response['error'] as Map<String, dynamic>;
    final data = error['data'] as Map<String, dynamic>;
    throw _CompileExpressionErrorDetails(data['details']);
  }

  /// If compilation fails, this method will throw a
  /// [_CompileExpressionErrorDetails] object that will be used to populate the
  /// 'details' field of the response to the evaluation RPC that requested this
  /// compilation to happen.
  Future<String> _compileExpression(
    Map<String, dynamic> buildScopeResponseResult,
  ) async {
    Client? externalClient = _service._findFirstClientThatHandlesService(
      _compileExpressionString,
    );

    final compileParams = <String, dynamic>{
      RunningIsolates._isolateIdString:
          _message.params[RunningIsolates._isolateIdString]!,
      _expressionString: _message.params[_expressionString]!,
      _definitionsString: buildScopeResponseResult['param_names']!,
      _definitionTypesString: buildScopeResponseResult['param_types']!,
      _typeDefinitionsString: buildScopeResponseResult['type_params_names']!,
      _typeBoundsString: buildScopeResponseResult['type_params_bounds']!,
      _typeDefaultsString: buildScopeResponseResult['type_params_defaults']!,
      _libraryUriString: buildScopeResponseResult[_libraryUriString]!,
      _tokenPosString: buildScopeResponseResult[_tokenPosString]!,
      _isStaticString: buildScopeResponseResult[_isStaticString]!,
    };
    final klass = buildScopeResponseResult['klass'];
    if (klass != null) {
      compileParams['klass'] = klass;
    }
    final scriptUri = buildScopeResponseResult[_scriptUriString];
    if (scriptUri != null) {
      compileParams[_scriptUriString] = scriptUri;
    }
    final method = buildScopeResponseResult[_methodString];
    if (method != null) {
      compileParams[_methodString] = method;
    }
    if (externalClient != null) {
      // Let the external client handle expression compilation.
      final compileExpression = Message.forMethod(_compileExpressionString);
      compileExpression.client = externalClient;
      compileExpression.params.addAll(compileParams);

      final id = _service._serviceRequests.newId();
      final oldId = _message.serial;
      final completer = Completer<String>();
      externalClient.serviceHandles[id] = (Message? m) {
        if (m != null) {
          completer.complete(json.encode(m.forwardToJson({'id': oldId})));
        } else {
          completer.complete(encodeRpcError(_message, kServiceDisappeared));
        }
      };
      externalClient.post(
        Response.json(
          compileExpression.forwardToJson({
            'id': id,
            _methodString: _compileExpressionString,
          }),
        ),
      );
      return completer.future
          .then((s) => jsonDecode(s))
          .then(
            (json) => _getKernelBytesOrThrowErrorDetails(
              json as Map<String, dynamic>,
            ),
          );
    } else {
      // fallback to compile using kernel service
      final compileExpressionParams = <String, dynamic>{
        'method': '_compileExpression',
        'id': _message.serial,
        'params': compileParams,
      };
      final compileExpression = Message._fromJsonRpcRequest(
        _message.client!,
        compileExpressionParams,
      );

      return _isolate
          .routeRequest(_service, compileExpression)
          .then((response) => response.decodeJson())
          .then(
            (json) => _getKernelBytesOrThrowErrorDetails(
              json as Map<String, dynamic>,
            ),
          );
    }
  }

  Future<Response> _evaluateCompiledExpression(String kernelBase64) {
    if (kernelBase64.isNotEmpty) {
      final params = _setupParams();
      params['isolateId'] = _message.params['isolateId'];
      params['kernelBytes'] = kernelBase64;
      params['disableBreakpoints'] = _message.params['disableBreakpoints'];
      final runParams = <String, dynamic>{
        'method': '_evaluateCompiledExpression',
        'id': _message.serial,
        'params': params,
      };
      if (_message.params['scope'] != null) {
        (runParams['params'] as Map<String, dynamic>)['scope'] =
            _message.params['scope'];
      }
      if (_message.params['idZoneId'] != null) {
        (runParams['params'] as Map<String, dynamic>)['idZoneId'] =
            _message.params['idZoneId'];
      }
      final runExpression = Message._fromJsonRpcRequest(
        _message.client!,
        runParams,
      );
      return _isolate.routeRequest(_service, runExpression); // _message
    } else {
      // empty kernel indicates dart1 mode
      return _isolate.routeRequest(_service, _message);
    }
  }

  Map<String, dynamic> _setupParams() {
    if (_message.method == 'evaluateInFrame') {
      return <String, dynamic>{'frameIndex': _message.params['frameIndex']};
    } else {
      assert(_message.method == 'evaluate');
      return <String, dynamic>{'targetId': _message.params['targetId']};
    }
  }
}
