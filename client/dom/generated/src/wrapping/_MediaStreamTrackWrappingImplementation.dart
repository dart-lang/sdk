// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaStreamTrackWrappingImplementation extends DOMWrapperBase implements MediaStreamTrack {
  _MediaStreamTrackWrappingImplementation() : super() {}

  static create__MediaStreamTrackWrappingImplementation() native {
    return new _MediaStreamTrackWrappingImplementation();
  }

  bool get enabled() { return _get_enabled(this); }
  static bool _get_enabled(var _this) native;

  void set enabled(bool value) { _set_enabled(this, value); }
  static void _set_enabled(var _this, bool value) native;

  String get kind() { return _get_kind(this); }
  static String _get_kind(var _this) native;

  String get label() { return _get_label(this); }
  static String _get_label(var _this) native;

  String get typeName() { return "MediaStreamTrack"; }
}
