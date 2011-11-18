// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CompositionEventWrappingImplementation extends _UIEventWrappingImplementation implements CompositionEvent {
  _CompositionEventWrappingImplementation() : super() {}

  static create__CompositionEventWrappingImplementation() native {
    return new _CompositionEventWrappingImplementation();
  }

  String get data() { return _get_data(this); }
  static String _get_data(var _this) native;

  void initCompositionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, DOMWindow viewArg, String dataArg) {
    _initCompositionEvent(this, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg);
    return;
  }
  static void _initCompositionEvent(receiver, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native;

  String get typeName() { return "CompositionEvent"; }
}
