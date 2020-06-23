// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_html;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:observatory/service_common.dart';

// Export the service library.
export 'package:observatory/service_common.dart';

class _HtmlWebSocket implements CommonWebSocket {
  WebSocket _webSocket;

  void connect(String address, void onOpen(), void onMessage(dynamic data),
      void onError(), void onClose()) {
    _webSocket = new WebSocket(address);
    _webSocket.onClose.listen((CloseEvent) => onClose());
    _webSocket.onError.listen((Event) => onError());
    _webSocket.onOpen.listen((Event) => onOpen());
    _webSocket.onMessage.listen((MessageEvent event) => onMessage(event.data));
  }

  bool get isOpen => _webSocket.readyState == WebSocket.OPEN;

  void send(dynamic data) {
    _webSocket.send(data);
  }

  void close() {
    _webSocket.close();
  }

  Future<ByteData> nonStringToByteData(dynamic data) {
    assert(data is Blob);
    FileReader fileReader = new FileReader();
    fileReader.readAsArrayBuffer(data);
    return fileReader.onLoadEnd.first.then((e) {
      Uint8List result = fileReader.result as Uint8List;
      return new ByteData.view(
          result.buffer, result.offsetInBytes, result.length);
    });
  }
}

/// The [WebSocketVM] communicates with a Dart VM over WebSocket. The Dart VM
/// can be embedded in Chromium or standalone. In the case of Chromium, we
/// make the service requests via the Chrome Remote Debugging Protocol.
class WebSocketVM extends CommonWebSocketVM {
  WebSocketVM(WebSocketVMTarget target) : super(target, new _HtmlWebSocket());
}
