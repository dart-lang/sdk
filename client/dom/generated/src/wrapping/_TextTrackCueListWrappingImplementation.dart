// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextTrackCueListWrappingImplementation extends DOMWrapperBase implements TextTrackCueList {
  _TextTrackCueListWrappingImplementation() : super() {}

  static create__TextTrackCueListWrappingImplementation() native {
    return new _TextTrackCueListWrappingImplementation();
  }

  int get length() { return _get__TextTrackCueList_length(this); }
  static int _get__TextTrackCueList_length(var _this) native;

  TextTrackCue getCueById(String id) {
    return _getCueById(this, id);
  }
  static TextTrackCue _getCueById(receiver, id) native;

  TextTrackCue item(int index) {
    return _item(this, index);
  }
  static TextTrackCue _item(receiver, index) native;

  String get typeName() { return "TextTrackCueList"; }
}
