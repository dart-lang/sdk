// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextTrackCueWrappingImplementation extends DOMWrapperBase implements TextTrackCue {
  TextTrackCueWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get alignment() { return _ptr.alignment; }

  String get direction() { return _ptr.direction; }

  num get endTime() { return _ptr.endTime; }

  String get id() { return _ptr.id; }

  int get linePosition() { return _ptr.linePosition; }

  bool get pauseOnExit() { return _ptr.pauseOnExit; }

  int get size() { return _ptr.size; }

  bool get snapToLines() { return _ptr.snapToLines; }

  num get startTime() { return _ptr.startTime; }

  int get textPosition() { return _ptr.textPosition; }

  TextTrack get track() { return LevelDom.wrapTextTrack(_ptr.track); }

  DocumentFragment getCueAsHTML() {
    return LevelDom.wrapDocumentFragment(_ptr.getCueAsHTML());
  }

  String getCueAsSource() {
    return _ptr.getCueAsSource();
  }
}
