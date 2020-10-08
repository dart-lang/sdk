// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_io;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:observatory_2/service_common.dart';

// Export the service library.
export 'package:observatory_2/service_common.dart';

class _IOWebSocket implements CommonWebSocket {
  WebSocket _webSocket;

  Future<void> connect(WebSocketVMTarget target, void onOpen(),
      void onMessage(dynamic data), void onError(), void onClose()) async {
    try {
      _webSocket = await WebSocket.connect(target.networkAddress);
      _webSocket.listen(onMessage,
          onError: (dynamic) => onError(),
          onDone: onClose,
          cancelOnError: true);
      onOpen();
    } catch (_) {
      onError();
    }
  }

  bool get isOpen =>
      (_webSocket != null) && (_webSocket.readyState == WebSocket.open);

  void send(dynamic data) {
    _webSocket.add(data);
  }

  void close() {
    if (_webSocket != null) {
      _webSocket.close();
    }
  }

  Future<ByteData> nonStringToByteData(dynamic data) {
    assert(data is Uint8List);
    Logger.root.info('Binary data size in bytes: ${data.lengthInBytes}');
    return new Future.sync(() =>
        new ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes));
  }
}

/// The [WebSocketVM] communicates with a Dart VM over WebSocket.
class WebSocketVM extends CommonWebSocketVM {
  WebSocketVM(WebSocketVMTarget target) : super(target, new _IOWebSocket());
}
