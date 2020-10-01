// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

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
    isolates.remove(portId);
  }

  @override
  Future<Response> routeRequest(VMService service, Message message) {
    String isolateParam = message.params['isolateId']!;
    int isolateId;
    if (!isolateParam.startsWith('isolates/')) {
      message.setErrorResponse(
          kInvalidParams, "invalid 'isolateId' parameter: $isolateParam");
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
            kInvalidParams, "invalid 'isolateId' parameter: $isolateParam");
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

/// Class that knows how to orchestrate expression evaluation in dart2 world.
class _Evaluator {
  _Evaluator(this._message, this._isolate, this._service);

  Future<Response> run() async {
    final buildScopeResponse = await _buildScope();
    final responseJson = buildScopeResponse.decodeJson();

    if (responseJson.containsKey('error')) {
      return Response.from(encodeCompilationError(
          _message, responseJson['error']['data']['details']));
    }

    String kernelBase64;
    try {
      kernelBase64 = await _compileExpression(responseJson['result']);
    } catch (e) {
      return Response.from(encodeCompilationError(_message, e.toString()));
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
      buildScopeParams['params']['scope'] = _message.params['scope'];
    }
    final buildScope =
        Message._fromJsonRpcRequest(_message.client!, buildScopeParams);

    // Decode the JSON and and insert it into the map. The map key
    // is the request Uri.
    return _isolate.routeRequest(_service, buildScope);
  }

  Future<String> _compileExpression(
      Map<String, dynamic> buildScopeResponseResult) {
    Client? externalClient =
        _service._findFirstClientThatHandlesService('compileExpression');

    final compileParams = <String, dynamic>{
      'isolateId': _message.params['isolateId']!,
      'expression': _message.params['expression']!,
      'definitions': buildScopeResponseResult['param_names']!,
      'typeDefinitions': buildScopeResponseResult['type_params_names']!,
      'libraryUri': buildScopeResponseResult['libraryUri']!,
      'isStatic': buildScopeResponseResult['isStatic']!,
    };
    final klass = buildScopeResponseResult['klass'];
    if (klass != null) {
      compileParams['klass'] = klass;
    }
    if (externalClient != null) {
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
      externalClient.post(Response.json(compileExpression
          .forwardToJson({'id': id, 'method': 'compileExpression'})));
      return completer.future.then((s) => jsonDecode(s)).then((json) {
        final Map<String, dynamic> jsonMap = json;
        if (jsonMap.containsKey('error')) {
          throw jsonMap['error'];
        }
        return jsonMap['result']['kernelBytes'];
      });
    } else {
      // fallback to compile using kernel service
      final compileExpressionParams = <String, dynamic>{
        'method': '_compileExpression',
        'id': _message.serial,
        'params': compileParams,
      };
      final compileExpression = Message._fromJsonRpcRequest(
          _message.client!, compileExpressionParams);

      return _isolate
          .routeRequest(_service, compileExpression)
          .then((response) => response.decodeJson())
          .then((json) {
        if (json['result'] != null) {
          return json['result']['kernelBytes'];
        }
        throw json['error']['data']['details'];
      });
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
        runParams['params']['scope'] = _message.params['scope'];
      }
      final runExpression =
          Message._fromJsonRpcRequest(_message.client!, runParams);
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
