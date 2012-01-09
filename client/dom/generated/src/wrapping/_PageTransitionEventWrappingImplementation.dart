// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PageTransitionEventWrappingImplementation extends _EventWrappingImplementation implements PageTransitionEvent {
  _PageTransitionEventWrappingImplementation() : super() {}

  static create__PageTransitionEventWrappingImplementation() native {
    return new _PageTransitionEventWrappingImplementation();
  }

  bool get persisted() { return _get_persisted(this); }
  static bool _get_persisted(var _this) native;

  String get typeName() { return "PageTransitionEvent"; }
}
