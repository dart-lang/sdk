// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ProcessingInstructionWrappingImplementation extends NodeWrappingImplementation implements ProcessingInstruction {
  ProcessingInstructionWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  StyleSheet get sheet() { return LevelDom.wrapStyleSheet(_ptr.sheet); }

  String get target() { return _ptr.target; }

  String get typeName() { return "ProcessingInstruction"; }
}
