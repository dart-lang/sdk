// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaStreamTrackWrappingImplementation extends DOMWrapperBase implements MediaStreamTrack {
  _MediaStreamTrackWrappingImplementation() : super() {}

  static create__MediaStreamTrackWrappingImplementation() native {
    return new _MediaStreamTrackWrappingImplementation();
  }

  bool get enabled() { return _get__MediaStreamTrack_enabled(this); }
  static bool _get__MediaStreamTrack_enabled(var _this) native;

  void set enabled(bool value) { _set__MediaStreamTrack_enabled(this, value); }
  static void _set__MediaStreamTrack_enabled(var _this, bool value) native;

  String get kind() { return _get__MediaStreamTrack_kind(this); }
  static String _get__MediaStreamTrack_kind(var _this) native;

  String get label() { return _get__MediaStreamTrack_label(this); }
  static String _get__MediaStreamTrack_label(var _this) native;

  String get typeName() { return "MediaStreamTrack"; }
}
