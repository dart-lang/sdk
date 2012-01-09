// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TrackEventWrappingImplementation extends _EventWrappingImplementation implements TrackEvent {
  _TrackEventWrappingImplementation() : super() {}

  static create__TrackEventWrappingImplementation() native {
    return new _TrackEventWrappingImplementation();
  }

  Object get track() { return _get_track(this); }
  static Object _get_track(var _this) native;

  String get typeName() { return "TrackEvent"; }
}
