// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'drop_dylib_recording_bindings.dart' as bindings;

@RecordUse()
void getMathMethod(String symbol) {
  if (symbol == 'add') {
    print('Hello world: ${_MyMath.add(3, 4)}!');
  } else if (symbol == 'multiply') {
    print('Hello world: ${_MyMath.multiply(3, 4)}!');
  } else {
    throw ArgumentError('Must pass either "add" or "multiply"');
  }
}

class _MyMath {
  static int add(int a, int b) => bindings.add(a, b);

  static int multiply(int a, int b) => bindings.multiply(a, b);
}
