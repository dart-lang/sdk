// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr) add events.
class WebSocketWrappingImplementation extends EventTargetWrappingImplementation implements WebSocket {
  WebSocketWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get URL() { return _ptr.URL; }

  String get binaryType() { return _ptr.binaryType; }

  void set binaryType(String value) { _ptr.binaryType = value; }

  int get bufferedAmount() { return _ptr.bufferedAmount; }

  EventListener get onclose() { return LevelDom.wrapEventListener(_ptr.onclose); }

  void set onclose(EventListener value) { _ptr.onclose = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onmessage() { return LevelDom.wrapEventListener(_ptr.onmessage); }

  void set onmessage(EventListener value) { _ptr.onmessage = LevelDom.unwrap(value); }

  EventListener get onopen() { return LevelDom.wrapEventListener(_ptr.onopen); }

  void set onopen(EventListener value) { _ptr.onopen = LevelDom.unwrap(value); }

  String get protocol() { return _ptr.protocol; }

  int get readyState() { return _ptr.readyState; }

  void close() {
    _ptr.close();
    return;
  }

  bool send(String data) {
    return _ptr.send(data);
  }

  String get typeName() { return "WebSocket"; }
}
