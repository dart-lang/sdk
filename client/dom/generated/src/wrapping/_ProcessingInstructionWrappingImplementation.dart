// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ProcessingInstructionWrappingImplementation extends _NodeWrappingImplementation implements ProcessingInstruction {
  _ProcessingInstructionWrappingImplementation() : super() {}

  static create__ProcessingInstructionWrappingImplementation() native {
    return new _ProcessingInstructionWrappingImplementation();
  }

  String get data() { return _get_data(this); }
  static String _get_data(var _this) native;

  void set data(String value) { _set_data(this, value); }
  static void _set_data(var _this, String value) native;

  StyleSheet get sheet() { return _get_sheet(this); }
  static StyleSheet _get_sheet(var _this) native;

  String get target() { return _get_target(this); }
  static String _get_target(var _this) native;

  String get typeName() { return "ProcessingInstruction"; }
}
