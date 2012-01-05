// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextTrackWrappingImplementation extends DOMWrapperBase implements TextTrack {
  _TextTrackWrappingImplementation() : super() {}

  static create__TextTrackWrappingImplementation() native {
    return new _TextTrackWrappingImplementation();
  }

  TextTrackCueList get activeCues() { return _get_activeCues(this); }
  static TextTrackCueList _get_activeCues(var _this) native;

  TextTrackCueList get cues() { return _get_cues(this); }
  static TextTrackCueList _get_cues(var _this) native;

  String get kind() { return _get_kind(this); }
  static String _get_kind(var _this) native;

  String get label() { return _get_label(this); }
  static String _get_label(var _this) native;

  String get language() { return _get_language(this); }
  static String _get_language(var _this) native;

  int get mode() { return _get_mode(this); }
  static int _get_mode(var _this) native;

  void set mode(int value) { _set_mode(this, value); }
  static void _set_mode(var _this, int value) native;

  int get readyState() { return _get_readyState(this); }
  static int _get_readyState(var _this) native;

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
