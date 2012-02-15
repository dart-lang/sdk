// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaStreamEventWrappingImplementation extends _EventWrappingImplementation implements MediaStreamEvent {
  _MediaStreamEventWrappingImplementation() : super() {}

  static create__MediaStreamEventWrappingImplementation() native {
    return new _MediaStreamEventWrappingImplementation();
  }

  MediaStream get stream() { return _get_stream(this); }
  static MediaStream _get_stream(var _this) native;

  String get typeName() { return "MediaStreamEvent"; }
}
