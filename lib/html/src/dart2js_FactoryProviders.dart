// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {

  static AudioContext createAudioContext() {
    return JS('AudioContext',
              'new (window.AudioContext || window.webkitAudioContext)()');
  }
}

class _PointFactoryProvider {
  static Point createPoint(num x, num y) =>
      JS('Point', 'new WebKitPoint(#, #)', x, y);
}

class _WebSocketFactoryProvider {
  static WebSocket createWebSocket(String url) =>
      JS('WebSocket', 'new WebSocket(#)', url);
}

class _TextFactoryProvider {
  static Text createText(String data) =>
      JS('Text', 'document.createTextNode(#)', data);
}
