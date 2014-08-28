// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_io;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:observatory/service_common.dart';

// Export the service library.
export 'package:observatory/service_common.dart';

class _IOWebSocket implements CommonWebSocket {
  WebSocket _webSocket;
  
  void connect(String address,
               void onOpen(),
               void onMessage(dynamic data),
               void onError(),
               void onClose()) {
    WebSocket.connect(address).then((WebSocket socket) {
      _webSocket = socket;
      _webSocket.listen(
          onMessage,
          onError: (dynamic) => onError(),
          onDone: onClose,
          cancelOnError: true);
      onOpen();
    });
  }
  
  bool get isOpen =>
      (_webSocket != null) && (_webSocket.readyState == WebSocket.OPEN);
  
  void send(dynamic data) {
    _webSocket.add(data);
  }
  
  void close() {
    _webSocket.close();
  }
  
  Future<ByteData> nonStringToByteData(dynamic data) {
    assert(data is Uint8List);
    print('nonString: ${data.lengthInBytes}, $data');
    return new Future.sync(() =>
        new ByteData.view(data.buffer,
                          data.offsetInBytes,
                          data.lengthInBytes));
  }
}

/// The [WebSocketVM] communicates with a Dart VM over WebSocket. The Dart VM
/// can be embedded in Chromium or standalone. In the case of Chromium, we
/// make the service requests via the Chrome Remote Debugging Protocol.
class WebSocketVM extends CommonWebSocketVM {
  WebSocketVM(WebSocketVMTarget target) : super(target, new _IOWebSocket());
}
