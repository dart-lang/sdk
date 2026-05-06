// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../test_library.dart';

int testPartLibraryValue = 4;

int testLibraryPartFunction(int formal) {
  return formal; // Breakpoint: testLibraryPartFunction
}

class TestLibraryPartClass {
  final int field;
  final int _field;

  TestLibraryPartClass(this.field, this._field) {
    print('Constructor'); // Breakpoint: testLibraryPartClassConstructor
  }

  @override
  String toString() => 'field: $field, _field: $_field';
}
