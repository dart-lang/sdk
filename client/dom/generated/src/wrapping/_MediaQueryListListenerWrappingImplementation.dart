// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaQueryListListenerWrappingImplementation extends DOMWrapperBase implements MediaQueryListListener {
  _MediaQueryListListenerWrappingImplementation() : super() {}

  static create__MediaQueryListListenerWrappingImplementation() native {
    return new _MediaQueryListListenerWrappingImplementation();
  }

  void queryChanged([MediaQueryList list = null]) {
    if (list === null) {
      _queryChanged(this);
      return;
    } else {
      _queryChanged_2(this, list);
      return;
    }
  }
  static void _queryChanged(receiver) native;
  static void _queryChanged_2(receiver, list) native;

  String get typeName() { return "MediaQueryListListener"; }
}
