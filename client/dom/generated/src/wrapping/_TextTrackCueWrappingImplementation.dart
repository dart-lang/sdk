// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextTrackCueWrappingImplementation extends DOMWrapperBase implements TextTrackCue {
  _TextTrackCueWrappingImplementation() : super() {}

  static create__TextTrackCueWrappingImplementation() native {
    return new _TextTrackCueWrappingImplementation();
  }

  String get alignment() { return _get__TextTrackCue_alignment(this); }
  static String _get__TextTrackCue_alignment(var _this) native;

  String get direction() { return _get__TextTrackCue_direction(this); }
  static String _get__TextTrackCue_direction(var _this) native;

  num get endTime() { return _get__TextTrackCue_endTime(this); }
  static num _get__TextTrackCue_endTime(var _this) native;

  String get id() { return _get__TextTrackCue_id(this); }
  static String _get__TextTrackCue_id(var _this) native;

  int get linePosition() { return _get__TextTrackCue_linePosition(this); }
  static int _get__TextTrackCue_linePosition(var _this) native;

  bool get pauseOnExit() { return _get__TextTrackCue_pauseOnExit(this); }
  static bool _get__TextTrackCue_pauseOnExit(var _this) native;

  int get size() { return _get__TextTrackCue_size(this); }
  static int _get__TextTrackCue_size(var _this) native;

  bool get snapToLines() { return _get__TextTrackCue_snapToLines(this); }
  static bool _get__TextTrackCue_snapToLines(var _this) native;

  num get startTime() { return _get__TextTrackCue_startTime(this); }
  static num _get__TextTrackCue_startTime(var _this) native;

  int get textPosition() { return _get__TextTrackCue_textPosition(this); }
  static int _get__TextTrackCue_textPosition(var _this) native;

  TextTrack get track() { return _get__TextTrackCue_track(this); }
  static TextTrack _get__TextTrackCue_track(var _this) native;

  DocumentFragment getCueAsHTML() {
    return _getCueAsHTML(this);
  }
  static DocumentFragment _getCueAsHTML(receiver) native;

  String getCueAsSource() {
    return _getCueAsSource(this);
  }
  static String _getCueAsSource(receiver) native;

  String get typeName() { return "TextTrackCue"; }
}
