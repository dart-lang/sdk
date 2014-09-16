// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_common;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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

/// Minimal common interface for 'WebSocket' in [dart:io] and [dart:html].
abstract class CommonWebSocket {
  void connect(String address,
               void onOpen(),
               void onMessage(dynamic data),
               void onError(),
               void onClose());
  bool get isOpen;
  void send(dynamic data);
  void close();
  Future<ByteData> nonStringToByteData(dynamic data);
}

/// A [CommonWebSocketVM] communicates with a Dart VM over a CommonWebSocket.
/// The Dart VM can be embedded in Chromium or standalone. In the case of
/// Chromium, we make the service requests via the Chrome Remote Debugging
/// Protocol.
abstract class CommonWebSocketVM extends VM {
  final Completer _connected = new Completer();
  final Completer _disconnected = new Completer();
  final WebSocketVMTarget target;
  final Map<String, _WebSocketRequest> _delayedRequests =
        new Map<String, _WebSocketRequest>();
  final Map<String, _WebSocketRequest> _pendingRequests =
      new Map<String, _WebSocketRequest>();
  int _requestSerial = 0;
  bool _hasInitiatedConnect = false;
  bool _hasFinishedConnect = false;
  Utf8Decoder _utf8Decoder = new Utf8Decoder();

  CommonWebSocket _webSocket;

  CommonWebSocketVM(this.target, this._webSocket) {
    assert(target != null);
  }

  void _notifyConnect() {
    _hasFinishedConnect = true;
    if (!_connected.isCompleted) {
      Logger.root.info('WebSocketVM connection opened: ${target.networkAddress}');
      _connected.complete(this);
    }
  }
  Future get onConnect => _connected.future;
  void _notifyDisconnect() {
    if (!_hasFinishedConnect) {
      return;
    }
    if (!_disconnected.isCompleted) {
      Logger.root.info('WebSocketVM connection error: ${target.networkAddress}');
      _disconnected.complete(this);
    }
  }
  Future get onDisconnect => _disconnected.future;

  void disconnect() {
    if (_hasInitiatedConnect) {
      _webSocket.close();
    }
    _cancelAllRequests();
    _notifyDisconnect();
  }

  Future<String> getString(String id) {
    if (!_hasInitiatedConnect) {
      _hasInitiatedConnect = true;
      _webSocket.connect(
          target.networkAddress, _onOpen, _onMessage, _onError, _onClose);
    }
    return _makeRequest(id);
  }

  /// Add a request for [id] to pending requests.
  Future<String> _makeRequest(String id) {
    assert(_hasInitiatedConnect);
    // Create request.
    String serial = (_requestSerial++).toString();
    var request = new _WebSocketRequest(id);
    if (_webSocket.isOpen) {
      // Already connected, send request immediately.
      _sendRequest(serial, request);
    } else {
      // Not connected yet, add to delayed requests.
      _delayedRequests[serial] = request;
    }
    return request.completer.future;
  }

  void _onClose() {
    _cancelAllRequests();
    _notifyDisconnect();
  }

  // WebSocket error event handler.
  void _onError() {
    _cancelAllRequests();
    _notifyDisconnect();
  }

  // WebSocket open event handler.
  void _onOpen() {
    target.lastConnectionTime = new DateTime.now().millisecondsSinceEpoch;
    _sendAllDelayedRequests();
    _notifyConnect();
  }

  // WebSocket message event handler.
  void _onMessage(dynamic data) {
    if (data is! String) {
      _webSocket.nonStringToByteData(data).then((ByteData bytes) {
        // See format spec. in VMs Service::SendEvent.
        int offset = 0;
        int metaSize = bytes.getUint64(offset, Endianness.BIG_ENDIAN);
        offset += 8;
        var meta = _utf8Decoder.convert(new Uint8List.view(
            bytes.buffer, bytes.offsetInBytes + offset, metaSize));
        offset += metaSize;
        var data = new ByteData.view(
            bytes.buffer,
            bytes.offsetInBytes + offset,
            bytes.lengthInBytes - offset);
        postEventMessage(meta, data);
      });
      return;
    }
    var map = JSON.decode(data);
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
    assert(_webSocket.isOpen);
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
    assert (_webSocket.isOpen);
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
