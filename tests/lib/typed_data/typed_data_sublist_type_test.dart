// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

// Test that the sublist of a typed_data list is of the same type.

var inscrutable;

class Is<T> {
  final name;
  Is(this.name);
  check(x) => x is T;
  expect(x, part) {
    Expect.isTrue(check(x), '($part: ${x.runtimeType}) is $name');
  }

  expectNot(x, part) {
    Expect.isFalse(check(x), '($part: ${x.runtimeType}) is! $name');
  }
}

void testSublistType(input, positive, all) {
  var negative = all.where((check) => !positive.contains(check));

  input = inscrutable(input);

  for (var check in positive) check.expect(input, 'input');
  for (var check in negative) check.expectNot(input, 'input');

  var sub = inscrutable(input.sublist(1));

  for (var check in positive) check.expect(sub, 'sublist');
  for (var check in negative) check.expectNot(sub, 'sublist');

  var sub2 = inscrutable(input.sublist(10));

  Expect.equals(0, sub2.length);
  for (var check in positive) check.expect(sub2, 'empty sublist');
  for (var check in negative) check.expectNot(sub2, 'empty sublist');
}

void testTypes() {
  var isFloat32list = new Is<Float32List>('Float32List');
  var isFloat64list = new Is<Float64List>('Float64List');

  var isInt8List = new Is<Int8List>('Int8List');
  var isInt16List = new Is<Int16List>('Int16List');
  var isInt32List = new Is<Int32List>('Int32List');

  var isUint8List = new Is<Uint8List>('Uint8List');
  var isUint16List = new Is<Uint16List>('Uint16List');
  var isUint32List = new Is<Uint32List>('Uint32List');

  var isUint8ClampedList = new Is<Uint8ClampedList>('Uint8ClampedList');

  var isIntList = new Is<List<int>>('List<int>');
  var isDoubleList = new Is<List<double>>('List<double>');
  var isNumList = new Is<List<num>>('List<num>');

  var allChecks = <Is<List>>[
    isFloat32list,
    isFloat64list,
    isInt8List,
    isInt16List,
    isInt32List,
    isUint8List,
    isUint16List,
    isUint32List,
    isUint8ClampedList
  ];

  testInt(list, check) {
    testSublistType(list, <Is<List>>[check, isIntList, isNumList], allChecks);
  }

  testDouble(list, check) {
    testSublistType(
        list, <Is<List>>[check, isDoubleList, isNumList], allChecks);
  }

  testDouble(new Float32List(10), isFloat32list);
  testDouble(new Float64List(10), isFloat64list);

  testInt(new Int8List(10), isInt8List);
  testInt(new Int16List(10), isInt16List);
  testInt(new Int32List(10), isInt32List);

  testInt(new Uint8List(10), isUint8List);
  testInt(new Uint16List(10), isUint16List);
  testInt(new Uint32List(10), isUint32List);

  testInt(new Uint8ClampedList(10), isUint8ClampedList);
}

main() {
  inscrutable = (x) => x;
  testTypes();
}
