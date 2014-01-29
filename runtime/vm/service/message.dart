// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

class Message {
  final Completer _completer = new Completer.sync();
  bool get completed => _completer.isCompleted;
  /// Future of response.
  Future<String> get response => _completer.future;
  /// Path.
  final List path = new List();
  /// Options.
  final Map options = new Map();

  void _setPath(List<String> pathSegments) {
    if (pathSegments == null) {
      return;
    }
    pathSegments.forEach((String segment) {
      if (segment == null || segment == '') {
        return;
      }
      path.add(segment);
    });
  }

  Message.fromUri(Uri uri) {
    var split = uri.path.split('/');
    if (split.length == 0) {
      setErrorResponse('Invalid uri: $uri.');
      return;
    }
    _setPath(split);
    options.addAll(uri.queryParameters);
  }

  Message.fromMap(Map map) {
    _setPath(map['path']);
    if (map['options'] != null) {
      options.addAll(map['options']);
    }
  }

  dynamic toJson() {
    return {
      'path': path,
      'options': options
    };
  }

  Future<String> send(SendPort sendPort) {
    final receivePort = new RawReceivePort();
    receivePort.handler = (value) {
      receivePort.close();
      if (value is Exception) {
        _completer.completeError(value);
      } else {
        _completer.complete(value);
      }
    };
    var keys = options.keys.toList();
    var values = options.values.toList();
    var request = [receivePort.sendPort, path, keys, values];
    sendIsolateServiceMessage(sendPort, request);
    return _completer.future;
  }

  Future<String> sendToVM() {
    final receivePort = new RawReceivePort();
    receivePort.handler = (value) {
      receivePort.close();
      if (value is Exception) {
        _completer.completeError(value);
      } else {
        _completer.complete(value);
      }
    };
    var keys = options.keys.toList();
    var values = options.values.toList();
    var request = [receivePort.sendPort, path, keys, values];
    sendRootServiceMessage(request);
    return _completer.future;
  }

  void setResponse(String response) {
    _completer.complete(response);
  }

  void setErrorResponse(String error) {
    _completer.complete(JSON.encode({
        'type': 'Error',
        'msg': error,
        'path': path,
        'options': options
    }));
  }
}

void sendIsolateServiceMessage(SendPort sp, List m)
    native "VMService_SendIsolateServiceMessage";

void sendRootServiceMessage(List m)
    native "VMService_SendRootServiceMessage";
