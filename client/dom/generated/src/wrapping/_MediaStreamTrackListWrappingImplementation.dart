// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaStreamTrackListWrappingImplementation extends DOMWrapperBase implements MediaStreamTrackList {
  _MediaStreamTrackListWrappingImplementation() : super() {}

  static create__MediaStreamTrackListWrappingImplementation() native {
    return new _MediaStreamTrackListWrappingImplementation();
  }

  int get length() { return _get__MediaStreamTrackList_length(this); }
  static int _get__MediaStreamTrackList_length(var _this) native;

  MediaStreamTrack item(int index) {
    return _item(this, index);
  }
  static MediaStreamTrack _item(receiver, index) native;

  String get typeName() { return "MediaStreamTrackList"; }
}
