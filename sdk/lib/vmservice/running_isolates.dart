// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

final class _CompileExpressionErrorDetails {
  final String details;

  _CompileExpressionErrorDetails(this.details);
}

class RunningIsolates implements MessageRouter {
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
    } else {
      return isolate.routeRequest(service, message);
    }
  }

  @override
  void routeResponse(Message message) {}
}

// NOTE: The following class is a duplicate of one in
// 'package:frontend_server/resident_frontend_server_utils.dart'. We are forced
// to duplicate it because `dart:_vmservice` is not allowed to import
// `package:frontend_server`.

final class _ResidentCompilerInfo {
  final String? _sdkHash;
  final InternetAddress _address;
  final int _port;

  /// The SDK hash that kernel files compiled using the Resident Frontend
  /// Compiler associated with this object will be stamped with.
  String? get sdkHash => _sdkHash;

  /// The address that the Resident Frontend Compiler associated with this
  /// object is listening from.
  InternetAddress get address => _address;

  /// The port number that the Resident Frontend Compiler associated with this
  /// object is listening on.
  int get port => _port;

  /// Extracts the value associated with a key from [entries], where [entries]
  /// is a [String] with the format '$key1:$value1 $key2:$value2 $key3:$value3 ...'.
  static String _extractValueAssociatedWithKey(String entries, String key) =>
      RegExp(
        '$key:'
        r'(\S+)(\s|$)',
      ).allMatches(entries).first[1]!;

  static _ResidentCompilerInfo fromFile(File file) {
    final fileContents = file.readAsStringSync();

    return _ResidentCompilerInfo._(
      sdkHash:
          fileContents.contains('sdkHash:')
              ? _extractValueAssociatedWithKey(fileContents, 'sdkHash')
              : null,
      address: InternetAddress(
        _extractValueAssociatedWithKey(fileContents, 'address'),
      ),
      port: int.parse(_extractValueAssociatedWithKey(fileContents, 'port')),
    );
  }

  _ResidentCompilerInfo._({
    required String? sdkHash,
    required int port,
    required InternetAddress address,
  }) : _sdkHash = sdkHash,
       _port = port,
       _address = address;
}

/// Class that knows how to orchestrate expression evaluation in dart2 world.
class _Evaluator {
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
      return (response['result'] as Map<String, dynamic>)['kernelBytes']
          as String;
    }
    final error = response['error'] as Map<String, dynamic>;
    final data = error['data'] as Map<String, dynamic>;
    throw _CompileExpressionErrorDetails(data['details']);
  }

  // NOTE: The following function is a duplicate of one in
  // 'package:frontend_server/resident_frontend_server_utils.dart'. We are
  // forced to duplicate it because `dart:_vmservice` is not allowed to import
  // `package:frontend_server`.

  /// Sends a compilation [request] to the resident frontend compiler associated
  /// with [serverInfoFile], and returns the compiler's JSON response.
  ///
  /// Throws a [FileSystemException] if [serverInfoFile] cannot be accessed.
  static Future<Map<String, dynamic>>
  _sendRequestToResidentFrontendCompilerAndRecieveResponse(
    String request,
    File serverInfoFile,
  ) async {
    Socket? client;
    Map<String, dynamic> jsonResponse;
    final residentCompilerInfo = _ResidentCompilerInfo.fromFile(serverInfoFile);

    try {
      client = await Socket.connect(
        residentCompilerInfo.address,
        residentCompilerInfo.port,
      );
      client.write(request);
      final data = String.fromCharCodes(await client.first);
      jsonResponse = jsonDecode(data);
    } catch (e) {
      jsonResponse = <String, dynamic>{
        'success': false,
        'errorMessage': e.toString(),
      };
    }
    client?.destroy();
    return jsonResponse;
  }

  /// If compilation fails, this method will throw a
  /// [_CompileExpressionErrorDetails] object that will be used to populate the
  /// 'details' field of the response to the evaluation RPC that requested this
  /// compilation to happen.
  Future<String> _compileExpression(
    Map<String, dynamic> buildScopeResponseResult,
  ) async {
    Client? externalClient = _service._findFirstClientThatHandlesService(
      'compileExpression',
    );

    final compileParams = <String, dynamic>{
      'isolateId': _message.params['isolateId']!,
      'expression': _message.params['expression']!,
      'definitions': buildScopeResponseResult['param_names']!,
      'definitionTypes': buildScopeResponseResult['param_types']!,
      'typeDefinitions': buildScopeResponseResult['type_params_names']!,
      'typeBounds': buildScopeResponseResult['type_params_bounds']!,
      'typeDefaults': buildScopeResponseResult['type_params_defaults']!,
      'libraryUri': buildScopeResponseResult['libraryUri']!,
      'tokenPos': buildScopeResponseResult['tokenPos']!,
      'isStatic': buildScopeResponseResult['isStatic']!,
    };
    final klass = buildScopeResponseResult['klass'];
    if (klass != null) {
      compileParams['klass'] = klass;
    }
    final scriptUri = buildScopeResponseResult['scriptUri'];
    if (scriptUri != null) {
      compileParams['scriptUri'] = scriptUri;
    }
    final method = buildScopeResponseResult['method'];
    if (method != null) {
      compileParams['method'] = method;
    }
    if (externalClient != null) {
      // Let the external client handle expression compilation.
      final compileExpression = Message.forMethod('compileExpression');
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
            'method': 'compileExpression',
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
    } else if (VMServiceEmbedderHooks.getResidentCompilerInfoFile!() != null) {
      // Compile the expression using the resident compiler.
      final response =
          await _sendRequestToResidentFrontendCompilerAndRecieveResponse(
            jsonEncode({
              'command': 'compileExpression',
              'expression': compileParams['expression'],
              'definitions': compileParams['definitions'],
              'definitionTypes': compileParams['definitionTypes'],
              'typeDefinitions': compileParams['typeDefinitions'],
              'typeBounds': compileParams['typeBounds'],
              'typeDefaults': compileParams['typeDefaults'],
              'libraryUri': compileParams['libraryUri'],
              'offset': compileParams['tokenPos'],
              'isStatic': compileParams['isStatic'],
              'class': compileParams['klass'],
              'scriptUri': compileParams['scriptUri'],
              'method': compileParams['method'],
              'rootLibraryUri': buildScopeResponseResult['rootLibraryUri'],
            }),
            VMServiceEmbedderHooks.getResidentCompilerInfoFile!()!,
          );

      if (response['success'] == true) {
        return response['kernelBytes'];
      } else if (response['errorMessage'] != null) {
        throw _CompileExpressionErrorDetails(response['errorMessage']);
      } else {
        final compilerOutputLines =
            (response['compilerOutputLines'] as List<dynamic>).cast<String>();
        throw _CompileExpressionErrorDetails(compilerOutputLines.join('\n'));
      }
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
