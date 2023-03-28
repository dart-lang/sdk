// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

// Test consistency of the names of built-in types in
// Type.toString and type check messages.
//
// The names of the built-in types are not guaranteed and
// can be adjusted as needed.

import 'dart:typed_data';
import "package:expect/expect.dart";

class A {}

testTypeName(Object? obj, String expectedName) {
  Expect.equals(expectedName, obj.runtimeType.toString());

  try {
    obj as A;
  } catch (e) {
    String msg = e.toString();
    Expect.contains(expectedName, msg);
  }

  if (obj is! Record) {
    testTypeName((42, obj), '(int, $expectedName)');
  }
}

main() {
  testTypeName(1, 'int');
  testTypeName(0x7766554433221100, 'int');

  testTypeName('abc', 'String');
  testTypeName(String.fromCharCodes([0xAABB, 0xEEDD]), 'String');

  testTypeName(null, 'Null');

  testTypeName(true, 'bool');
  testTypeName(false, 'bool');

  testTypeName(1.0, 'double');
  testTypeName(-1e200, 'double');

  testTypeName(<int>[2, 3], 'List<int>');
  testTypeName(List<int>.filled(1, 2, growable: false), 'List<int>');
  testTypeName(List<int>.filled(1, 2, growable: true), 'List<int>');
  testTypeName(const <int>[2, 3], 'List<int>');

  testTypeName(Float64x2(2.0, 3.0), 'Float64x2');
  testTypeName(Float32x4(1.0, 2.0, 3.0, 4.0), 'Float32x4');
  testTypeName(Uint8List(3), 'Uint8List');

  // VM doesn't currently hide internal names of map and set classes.
  testTypeName(Map<int, String>(), '_Map<int, String>');
  testTypeName(<int, String>{1: 'foo'}, '_Map<int, String>');
  testTypeName(const <int, String>{1: 'foo'}, '_ConstMap<int, String>');

  testTypeName(Set<String>(), '_Set<String>');
  testTypeName(<String>{'foo'}, '_Set<String>');
  testTypeName(const <String>{'foo'}, '_ConstSet<String>');
}
