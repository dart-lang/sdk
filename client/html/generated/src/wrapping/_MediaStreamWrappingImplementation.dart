// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaStreamWrappingImplementation extends DOMWrapperBase implements MediaStream {
  MediaStreamWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get label() { return _ptr.label; }

  EventListener get onended() { return LevelDom.wrapEventListener(_ptr.onended); }

  void set onended(EventListener value) { _ptr.onended = LevelDom.unwrap(value); }

  int get readyState() { return _ptr.readyState; }

  MediaStreamTrackList get tracks() { return LevelDom.wrapMediaStreamTrackList(_ptr.tracks); }

  void addEventListener(String type, EventListener listener, bool useCapture) {
    _ptr.addEventListener(type, LevelDom.unwrap(listener), useCapture);
    return;
  }

  bool dispatchEvent(Event event) {
    return _ptr.dispatchEvent(LevelDom.unwrap(event));
  }

  void removeEventListener(String type, EventListener listener, bool useCapture) {
    _ptr.removeEventListener(type, LevelDom.unwrap(listener), useCapture);
    return;
  }

  String get typeName() { return "MediaStream"; }
}
