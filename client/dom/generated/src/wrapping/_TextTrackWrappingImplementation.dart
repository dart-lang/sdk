// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextTrackWrappingImplementation extends DOMWrapperBase implements TextTrack {
  _TextTrackWrappingImplementation() : super() {}

  static create__TextTrackWrappingImplementation() native {
    return new _TextTrackWrappingImplementation();
  }

  TextTrackCueList get activeCues() { return _get__TextTrack_activeCues(this); }
  static TextTrackCueList _get__TextTrack_activeCues(var _this) native;

  TextTrackCueList get cues() { return _get__TextTrack_cues(this); }
  static TextTrackCueList _get__TextTrack_cues(var _this) native;

  String get kind() { return _get__TextTrack_kind(this); }
  static String _get__TextTrack_kind(var _this) native;

  String get label() { return _get__TextTrack_label(this); }
  static String _get__TextTrack_label(var _this) native;

  String get language() { return _get__TextTrack_language(this); }
  static String _get__TextTrack_language(var _this) native;

  int get mode() { return _get__TextTrack_mode(this); }
  static int _get__TextTrack_mode(var _this) native;

  void set mode(int value) { _set__TextTrack_mode(this, value); }
  static void _set__TextTrack_mode(var _this, int value) native;

  int get readyState() { return _get__TextTrack_readyState(this); }
  static int _get__TextTrack_readyState(var _this) native;

  void addCue(TextTrackCue cue) {
    _addCue(this, cue);
    return;
  }
  static void _addCue(receiver, cue) native;

  void removeCue(TextTrackCue cue) {
    _removeCue(this, cue);
    return;
  }
  static void _removeCue(receiver, cue) native;

  String get typeName() { return "TextTrack"; }
}
