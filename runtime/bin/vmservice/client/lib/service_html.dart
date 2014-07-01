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

/// Description of a VM target.
class WebSocketVMTarget {
  // Last time this VM has been connected to.
  int lastConnectionTime = 0;
  bool get hasEverConnected => lastConnectionTime > 0;

  // Chrome VM or standalone;
  bool chrome = false;
  bool get standalone => !chrome;

  // User defined name.
  String name;
  // Network address of VM.
  String networkAddress;

  WebSocketVMTarget(this.networkAddress) {
    name = networkAddress;
  }

  WebSocketVMTarget.fromMap(Map json) {
    lastConnectionTime = json['lastConnectionTime'];
    chrome = json['chrome'];
    name = json['name'];
    networkAddress = json['networkAddress'];
    if (name == null) {
      name = networkAddress;
    }
  }

  Map toJson() {
    return {
      'lastConnectionTime': lastConnectionTime,
      'chrome': chrome,
      'name': name,
      'networkAddress': networkAddress,
    };
  }
}

class _WebSocketRequest {
  final String id;
  final Completer<String> completer;
  _WebSocketRequest(this.id)
      : completer = new Completer<String>();
}

/// The [WebSocketVM] communicates with a Dart VM over WebSocket. The Dart VM
/// can be embedded in Chromium or standalone. In the case of Chromium, we
/// make the service requests via the Chrome Remote Debugging Protocol.
class WebSocketVM extends VM {
  final Completer _connected = new Completer();
  final Completer _disconnected = new Completer();
  final WebSocketVMTarget target;
  final Map<String, _WebSocketRequest> _delayedRequests =
        new Map<String, _WebSocketRequest>();
  final Map<String, _WebSocketRequest> _pendingRequests =
      new Map<String, _WebSocketRequest>();
  int _requestSerial = 0;
  WebSocket _webSocket;

  WebSocketVM(this.target) {
    assert(target != null);
  }

  void _notifyConnect() {
    if (!_connected.isCompleted) {
      Logger.root.info('WebSocketVM connection opened: ${target.networkAddress}');
      _connected.complete(this);
    }
  }
  Future get onConnect => _connected.future;
  void _notifyDisconnect() {
    if (!_disconnected.isCompleted) {
      Logger.root.info('WebSocketVM connection error: ${target.networkAddress}');
      _disconnected.complete(this);
    }
  }
  Future get onDisconnect => _disconnected.future;

  void disconnect() {
    if (_webSocket != null) {
      _webSocket.close();
    }
    _cancelAllRequests();
    _notifyDisconnect();
  }

  Future<String> getString(String id) {
    if (_webSocket == null) {
      // Create a WebSocket.
      _webSocket = new WebSocket(target.networkAddress);
      _webSocket.onClose.listen(_onClose);
      _webSocket.onError.listen(_onError);
      _webSocket.onOpen.listen(_onOpen);
      _webSocket.onMessage.listen(_onMessage);
    }
    return _makeRequest(id);
  }

  /// Add a request for [id] to pending requests.
  Future<String> _makeRequest(String id) {
    assert(_webSocket != null);
    // Create request.
    String serial = (_requestSerial++).toString();
    var request = new _WebSocketRequest(id);
    if (_webSocket.readyState == WebSocket.OPEN) {
      // Already connected, send request immediately.
      _sendRequest(serial, request);
    } else {
      // Not connected yet, add to delayed requests.
      _delayedRequests[serial] = request;
    }
    return request.completer.future;
  }

  void _onClose(CloseEvent event) {
    _cancelAllRequests();
    _notifyDisconnect();
  }

  // WebSocket error event handler.
  void _onError(Event) {
    _cancelAllRequests();
    _notifyDisconnect();
  }

  // WebSocket open event handler.
  void _onOpen(Event) {
    target.lastConnectionTime = new DateTime.now().millisecondsSinceEpoch;
    _sendAllDelayedRequests();
    _notifyConnect();
  }

  // WebSocket message event handler.
  void _onMessage(MessageEvent event) {
    var map = JSON.decode(event.data);
    if (map == null) {
      Logger.root.severe('WebSocketVM got empty message');
      return;
    }
    // Extract serial and response.
    var serial;
    var response;
    if (target.chrome) {
      if (map['method'] != 'Dart.observatoryData') {
        // ignore devtools protocol spam.
        return;
      }
      serial = map['params']['id'].toString();
      response = map['params']['data'];
    } else {
      serial = map['seq'];
      response = map['response'];
    }
    if (serial == null) {
      // Messages without sequence numbers are asynchronous events
      // from the vm.
      postEventMessage(response);
      return;
    }
    // Complete request.
    var request = _pendingRequests.remove(serial);
    if (request == null) {
      Logger.root.severe('Received unexpected message: ${map}');
      return;
    }
    request.completer.complete(response);
  }

  String _generateNetworkError(String userMessage) {
    return JSON.encode({
      'type': 'ServiceException',
      'id': '',
      'kind': 'NetworkException',
      'message': userMessage
    });
  }

  void _cancelRequests(Map<String, _WebSocketRequest> requests) {
    requests.forEach((String serial, _WebSocketRequest request) {
      request.completer.complete(
          _generateNetworkError('WebSocket disconnected'));
    });
    requests.clear();
  }

  /// Cancel all pending and delayed requests by completing them with an error.
  void _cancelAllRequests() {
    if (_pendingRequests.length > 0) {
      Logger.root.info('Cancelling all pending requests.');
      _cancelRequests(_pendingRequests);
    }
    if (_delayedRequests.length > 0) {
      Logger.root.info('Cancelling all delayed requests.');
      _cancelRequests(_delayedRequests);
    }
  }

  /// Send all delayed requests.
  void _sendAllDelayedRequests() {
    assert(_webSocket != null);
    if (_delayedRequests.length == 0) {
      return;
    }
    Logger.root.info('Sending all delayed requests.');
    // Send all delayed requests.
    _delayedRequests.forEach(_sendRequest);
    // Clear all delayed requests.
    _delayedRequests.clear();
  }

  /// Send the request over WebSocket.
  void _sendRequest(String serial, _WebSocketRequest request) {
    assert (_webSocket.readyState == WebSocket.OPEN);
    if (!request.id.endsWith('/profile/tag')) {
      Logger.root.info('GET ${request.id} from ${target.networkAddress}');
    }
    // Mark request as pending.
    assert(_pendingRequests.containsKey(serial) == false);
    _pendingRequests[serial] = request;
    var message;
    // Encode message.
    if (target.chrome) {
      message = JSON.encode({
        'id': int.parse(serial),
        'method': 'Dart.observatoryQuery',
        'params': {
          'id': serial,
          'query': request.id
        }
      });
    } else {
      message = JSON.encode({'seq': serial, 'request': request.id});
    }
    // Send message.
    _webSocket.send(message);
  }
}

// A VM that communicates with the service via posting messages from DevTools.
class PostMessageVM extends VM {
  final Completer _connected = new Completer();
  final Completer _disconnected = new Completer();
  void disconnect() { /* nope */ }
  Future get onConnect => _connected.future;
  Future get onDisconnect => _disconnected.future;
  final Map<String, Completer> _pendingRequests =
      new Map<String, Completer>();
  int _requestSerial = 0;

  PostMessageVM() : super() {
    window.onMessage.listen(_messageHandler);
    _connected.complete(this);
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
    message['query'] = '$path';
    _requestSerial++;
    var completer = new Completer();
    _pendingRequests[idString] = completer;
    window.parent.postMessage(JSON.encode(message), '*');
    return completer.future;
  }
}
