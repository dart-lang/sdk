// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr) add custom Events class.
class NotificationWrappingImplementation extends EventTargetWrappingImplementation implements Notification {
  NotificationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get dir() { return _ptr.dir; }

  void set dir(String value) { _ptr.dir = value; }

  EventListener get onclick() { return LevelDom.wrapEventListener(_ptr.onclick); }

  void set onclick(EventListener value) { _ptr.onclick = LevelDom.unwrap(value); }

  EventListener get onclose() { return LevelDom.wrapEventListener(_ptr.onclose); }

  void set onclose(EventListener value) { _ptr.onclose = LevelDom.unwrap(value); }

  EventListener get ondisplay() { return LevelDom.wrapEventListener(_ptr.ondisplay); }

  void set ondisplay(EventListener value) { _ptr.ondisplay = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  String get replaceId() { return _ptr.replaceId; }

  void set replaceId(String value) { _ptr.replaceId = value; }

  void cancel() {
    _ptr.cancel();
    return;
  }

  void show() {
    _ptr.show();
    return;
  }

  String get typeName() { return "Notification"; }
}
