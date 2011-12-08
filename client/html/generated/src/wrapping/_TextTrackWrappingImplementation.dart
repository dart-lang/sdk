// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextTrackWrappingImplementation extends DOMWrapperBase implements TextTrack {
  TextTrackWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  TextTrackCueList get activeCues() { return LevelDom.wrapTextTrackCueList(_ptr.activeCues); }

  TextTrackCueList get cues() { return LevelDom.wrapTextTrackCueList(_ptr.cues); }

  String get kind() { return _ptr.kind; }

  String get label() { return _ptr.label; }

  String get language() { return _ptr.language; }

  int get mode() { return _ptr.mode; }

  void set mode(int value) { _ptr.mode = value; }

  int get readyState() { return _ptr.readyState; }

  void addCue(TextTrackCue cue) {
    _ptr.addCue(LevelDom.unwrap(cue));
    return;
  }

  void removeCue(TextTrackCue cue) {
    _ptr.removeCue(LevelDom.unwrap(cue));
    return;
  }
}
