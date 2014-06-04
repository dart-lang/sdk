// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_html;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:observatory/service.dart';

// Export the service library.
export 'package:observatory/service.dart';

class HttpVM extends VM {
  String host;

  bool runningInJavaScript() => identical(1.0, 1);

  HttpVM() : super() {
    if (runningInJavaScript()) {
      // When we are running as JavaScript use the same hostname:port
      // that the Observatory is loaded from.
      host = 'http://${window.location.host}/';
    } else {
      // Otherwise, assume we are running from the Dart Editor and
      // want to connect on the default port.
      host = 'http://127.0.0.1:8181/';
    }
  }

  Future<String> getString(String id) {
    // Ensure we don't request host//id.
    if (host.endsWith('/') && id.startsWith('/')) {
      id = id.substring(1);
    }
    Logger.root.info('Fetching $id from $host');
    return HttpRequest.request(host + id,
                               requestHeaders: {
                                  'Observatory-Version': '1.0'
                               }).then((HttpRequest request) {
        return request.responseText;
      }).catchError((error) {
      // If we get an error here, the network request has failed.
      Logger.root.severe('HttpRequest.request failed.');
      var request = error.target;
      return JSON.encode({
          'type': 'ServiceException',
          'id': '',
          'response': request.responseText,
          'kind': 'NetworkException',
          'message': 'Could not connect to service (${request.statusText}). '
                     'Check that you started the VM with the following flags: '
                     '--observe'
        });
    });
  }
}

class WebSocketVM extends VM {
  final Map<int, Completer> _pendingRequests =
      new Map<int, Completer>();
  int _requestSerial = 0;

  String _host;
  Future<WebSocket> _socketFuture;

  bool runningInJavaScript() => identical(1.0, 1);

  WebSocketVM() : super() {
    if (runningInJavaScript()) {
      // When we are running as JavaScript use the same hostname:port
      // that the Observatory is loaded from.
      _host = 'ws://${window.location.host}/ws';
    } else {
      // Otherwise, assume we are running from the Dart Editor and
      // want to connect on the default port.
      _host = 'ws://127.0.0.1:8181/ws';
    }

    var completer = new Completer<WebSocket>();
    _socketFuture = completer.future;
    var socket = new WebSocket(_host);
    socket.onOpen.first.then((_) {
        socket.onMessage.listen(_handleMessage);
        socket.onClose.first.then((_) {
            _socketFuture = null;
          });
        completer.complete(socket);
      });
    socket.onError.first.then((_) {
        _socketFuture = null;
      });
  }

  void _handleMessage(MessageEvent event) {
    var map = JSON.decode(event.data);
    int seq = map['seq'];
    var response = map['response'];
    var completer = _pendingRequests.remove(seq);
    if (completer == null) {
      Logger.root.severe('Received unexpected message: ${map}');
    } else {
      completer.complete(response);
    }
  }

  Future<String> getString(String id) {
    if (_socketFuture == null) {
      var errorResponse = JSON.encode({
              'type': 'ServiceException',
              'id': '',
              'response': '',
              'kind': 'NetworkException',
              'message': 'Could not connect to service. Check that you started the'
              ' VM with the following flags:\n --enable-vm-service'
              ' --pause-isolates-on-exit'
          });
      return new Future.value(errorResponse);
    }
    return _socketFuture.then((socket) {
        int seq = _requestSerial++;
        if (!id.endsWith('/profile/tag')) {
          Logger.root.info('Fetching $id from $_host');
        }
        var completer = new Completer<String>();
        _pendingRequests[seq] = completer;
        var message = JSON.encode({'seq': seq, 'request': id});
        socket.send(message);
        return completer.future;
      });
  }
}

class DartiumVM extends VM {
  final Map<String, Completer> _pendingRequests =
      new Map<String, Completer>();
  int _requestSerial = 0;

  DartiumVM() : super() {
    window.onMessage.listen(_messageHandler);
    Logger.root.info('Connected to DartiumVM');
  }

  void _messageHandler(msg) {
    var id = msg.data['id'];
    var name = msg.data['name'];
    var data = msg.data['data'];
    if (name != 'observatoryData') {
      return;
    }
    var completer = _pendingRequests[id];
    assert(completer != null);
    _pendingRequests.remove(id);
    completer.complete(data);
  }

  Future<String> getString(String path) {
    var idString = '$_requestSerial';
    Map message = {};
    message['id'] = idString;
    message['method'] = 'observatoryQuery';
    message['query'] = '/$path';
    _requestSerial++;
    var completer = new Completer();
    _pendingRequests[idString] = completer;
    window.parent.postMessage(JSON.encode(message), '*');
    return completer.future;
  }
}
