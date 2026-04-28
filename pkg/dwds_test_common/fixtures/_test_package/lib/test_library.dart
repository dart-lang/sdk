// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'src/test_part.dart';

int testLibraryValue = 3;

int testLibraryFunction(int formal) {
  return formal; // Breakpoint: testLibraryFunction
}

class TestLibraryClass {
  final int field;
  final int _field;
  TestLibraryClass(this.field, this._field) {
    print('Constructor'); // Breakpoint: testLibraryClassConstructor
  }

  @override
  String toString() => 'field: $field, _field: $_field';
}
