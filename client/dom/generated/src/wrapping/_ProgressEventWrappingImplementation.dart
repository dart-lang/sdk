// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ProgressEventWrappingImplementation extends _EventWrappingImplementation implements ProgressEvent {
  _ProgressEventWrappingImplementation() : super() {}

  static create__ProgressEventWrappingImplementation() native {
    return new _ProgressEventWrappingImplementation();
  }

  bool get lengthComputable() { return _get_lengthComputable(this); }
  static bool _get_lengthComputable(var _this) native;

  int get loaded() { return _get_loaded(this); }
  static int _get_loaded(var _this) native;

  int get total() { return _get_total(this); }
  static int _get_total(var _this) native;

  void initProgressEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool lengthComputableArg, int loadedArg, int totalArg) {
    _initProgressEvent(this, typeArg, canBubbleArg, cancelableArg, lengthComputableArg, loadedArg, totalArg);
    return;
  }
  static void _initProgressEvent(receiver, typeArg, canBubbleArg, cancelableArg, lengthComputableArg, loadedArg, totalArg) native;

  String get typeName() { return "ProgressEvent"; }
}
