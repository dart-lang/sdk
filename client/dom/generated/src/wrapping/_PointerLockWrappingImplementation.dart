// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PointerLockWrappingImplementation extends DOMWrapperBase implements PointerLock {
  _PointerLockWrappingImplementation() : super() {}

  static create__PointerLockWrappingImplementation() native {
    return new _PointerLockWrappingImplementation();
  }

  bool get isLocked() { return _get_isLocked(this); }
  static bool _get_isLocked(var _this) native;

  void lock(Element target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) {
    if (successCallback === null) {
      if (failureCallback === null) {
        _lock(this, target);
        return;
      }
    } else {
      if (failureCallback === null) {
        _lock_2(this, target, successCallback);
        return;
      } else {
        _lock_3(this, target, successCallback, failureCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _lock(receiver, target) native;
  static void _lock_2(receiver, target, successCallback) native;
  static void _lock_3(receiver, target, successCallback, failureCallback) native;

  void unlock() {
    _unlock(this);
    return;
  }
  static void _unlock(receiver) native;

  String get typeName() { return "PointerLock"; }
}
