// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

enum MessageType { Request, Notification, Response }

class Message {
  final _completer = Completer<Response>.sync();
  bool get completed => _completer.isCompleted;

  /// Future of response.
  Future<Response> get response => _completer.future;
  Client? client;

  // Is a notification message (no serial)
  final MessageType type;

  // Client-side identifier for this message.
  final serial;

  final String? method;

  final params = <String, dynamic>{};
  final result = {};
  final error = {};

  factory Message.fromJsonRpc(Client? client, Map map) {
    if (map.containsKey('id')) {
      final id = map['id'];
      if (id != null && id is! num && id is! String) {
        throw Exception("'id' must be a number, string, or null.");
      }
      if (map.containsKey('method')) {
        return Message._fromJsonRpcRequest(client, map);
      }
      if (map.containsKey('result')) {
        return Message._fromJsonRpcResult(client, map);
      }
      if (map.containsKey('error')) {
        return Message._fromJsonRpcError(client, map);
      }
    } else if (map.containsKey('method')) {
      return Message._fromJsonRpcNotification(client, map);
    }
    throw Exception('Invalid message format');
  }

  // http://www.jsonrpc.org/specification#request_object
  Message._fromJsonRpcRequest(Client? client, Map map)
      : client = client,
        type = MessageType.Request,
        serial = map['id'],
        method = map['method'] {
    if (map['params'] != null) {
      params.addAll(map['params']);
    }
  }

  // http://www.jsonrpc.org/specification#notification
  Message._fromJsonRpcNotification(Client? client, Map map)
      : client = client,
        type = MessageType.Notification,
        method = map['method'],
        serial = null {
    if (map['params'] != null) {
      params.addAll(map['params']);
    }
  }

  // http://www.jsonrpc.org/specification#response_object
  Message._fromJsonRpcResult(Client? client, Map map)
      : client = client,
        type = MessageType.Response,
        serial = map['id'],
        method = null {
    result.addAll(map['result']);
  }

  // http://www.jsonrpc.org/specification#response_object
  Message._fromJsonRpcError(Client? client, Map map)
      : client = client,
        type = MessageType.Response,
        serial = map['id'],
        method = null {
    error.addAll(map['error']);
  }

  static String _methodNameFromUri(Uri uri) {
    if (uri == null || uri.pathSegments.length == 0) {
      return '';
    }
    return uri.pathSegments[0];
  }

  Message.forMethod(String method)
      : client = null,
        method = method,
        type = MessageType.Request,
        serial = '';

  Message.fromUri(this.client, Uri uri)
      : type = MessageType.Request,
        serial = '',
        method = _methodNameFromUri(uri) {
    params.addAll(uri.queryParameters);
  }

  Message.forIsolate(this.client, Uri uri, RunningIsolate isolate)
      : type = MessageType.Request,
        serial = '',
        method = _methodNameFromUri(uri) {
    params.addAll(uri.queryParameters);
    params['isolateId'] = isolate.serviceId;
  }

  Uri toUri() => Uri(path: method!, queryParameters: params);

  dynamic toJson() => throw 'unsupported';

  Map<String, dynamic> forwardToJson([Map<String, dynamic>? overloads]) {
    final json = <String, dynamic>{'jsonrpc': '2.0', 'id': serial};
    switch (type) {
      case MessageType.Request:
      case MessageType.Notification:
        json['method'] = method;
        if (params.isNotEmpty) {
          json['params'] = params;
        }
        break;
      case MessageType.Response:
        if (result.isNotEmpty) {
          json['result'] = result;
        }
        if (error.isNotEmpty) {
          json['error'] = error;
        }
    }
    if (overloads != null) {
      json.addAll(overloads);
    }
    return json;
  }

  // Calls toString on all non-String elements of [list]. We do this so all
  // elements in the list are strings, making consumption by C++ simpler.
  // This has a side effect that boolean literal values like true become 'true'
  // and thus indistinguishable from the string literal 'true'.
  List<String> _makeAllString(List list) {
    var new_list = List<String>.filled(list.length, "");
    for (var i = 0; i < list.length; i++) {
      new_list[i] = list[i].toString();
    }
    return new_list;
  }

  Future<Response> sendToIsolate(SendPort sendPort) {
    final receivePort = RawReceivePort();
    receivePort.handler = (value) {
      receivePort.close();
      _setResponseFromPort(value);
    };
    final keys = _makeAllString(params.keys.toList(growable: false));
    final values = _makeAllString(params.values.toList(growable: false));
    final request = List<dynamic>.filled(6, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = receivePort.sendPort
      ..[2] = serial
      ..[3] = method
      ..[4] = keys
      ..[5] = values;
    if (!sendIsolateServiceMessage(sendPort, request)) {
      receivePort.close();
      _completer.complete(Response.internalError(
          'could not send message [${serial}] to isolate'));
    }
    return _completer.future;
  }

  // We currently support two ways of passing parameters from Dart code to C
  // code. The original way always converts the parameters to strings before
  // passing them over. Our goal is to convert all C handlers to take the
  // parameters as Dart objects but until the conversion is complete, we
  // maintain the list of supported methods below.
  bool _methodNeedsObjectParameters(String method) {
    switch (method) {
      case '_listDevFS':
      case '_listDevFSFiles':
      case '_createDevFS':
      case '_deleteDevFS':
      case '_writeDevFSFile':
      case '_writeDevFSFiles':
      case '_readDevFSFile':
      case '_spawnUri':
        return true;
      default:
        return false;
    }
  }

  Future<Response> sendToVM() {
    final receivePort = RawReceivePort();
    receivePort.handler = (value) {
      receivePort.close();
      _setResponseFromPort(value);
    };
    var keys = params.keys.toList(growable: false);
    var values = params.values.toList(growable: false);
    if (!_methodNeedsObjectParameters(method!)) {
      keys = _makeAllString(keys);
      values = _makeAllString(values);
    }
    final request = List<dynamic>.filled(6, null)
      ..[0] = 0 // Make room for OOB message type.
      ..[1] = receivePort.sendPort
      ..[2] = serial
      ..[3] = method
      ..[4] = keys
      ..[5] = values;

    if (_methodNeedsObjectParameters(method!)) {
      // We use a different method invocation path here.
      sendObjectRootServiceMessage(request);
    } else {
      sendRootServiceMessage(request);
    }

    return _completer.future;
  }

  void _setResponseFromPort(dynamic response) {
    if (response == null) {
      // We should only have a null response for Notifications.
      assert(type == MessageType.Notification);
      return null;
    }
    _completer.complete(Response.from(response));
  }

  void setResponse(String response) =>
      _completer.complete(Response(ResponsePayloadKind.String, response));

  void setErrorResponse(int code, String details) =>
      setResponse(encodeRpcError(this, code, details: '$method: $details'));
}

bool sendIsolateServiceMessage(SendPort sp, List m)
    native 'VMService_SendIsolateServiceMessage';

void sendRootServiceMessage(List m) native 'VMService_SendRootServiceMessage';

void sendObjectRootServiceMessage(List m)
    native 'VMService_SendObjectRootServiceMessage';
