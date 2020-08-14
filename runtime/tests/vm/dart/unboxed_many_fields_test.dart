// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show VMInternalsForTesting;

import 'package:expect/expect.dart';

import 'unboxed_parameter_helper.dart';

// The VM class finalizer ensures that we only unbox fields which can be
// represented in the unboxed field bitmap in the target architecture (even when
// cross-compiling from 64-bit to 32-bit), see `Class::CalculateFieldOffsets()`.

int i = 0;
final Object objectFieldValue = Foo('i${i++}');

void main() {
  final object = buildTargetLayout64Bit();

  // Ensure all fields of the class are used.
  print(object);

  Expect.identical(object.field1, objectFieldValue);
  Expect.identical(object.field2, constIntegerFieldValue);
  Expect.identical(object.field64, objectFieldValue);
  Expect.identical(object.field65, constIntegerFieldValue);
  Expect.identical(object.field66, objectFieldValue);
  Expect.equals('i0', object.field66.value);

  // Forcefully cause a GC.
  VMInternalsForTesting.collectAllGarbage();

  Expect.identical(object.field1, objectFieldValue);
  Expect.identical(object.field2, constIntegerFieldValue);
  Expect.identical(object.field64, objectFieldValue);
  Expect.identical(object.field65, constIntegerFieldValue);
  Expect.identical(object.field66, objectFieldValue);
  Expect.equals('i0', object.field66.value);

  print(object);
}

class Foo {
  final String value;
  Foo(this.value);
}

class TargetLayout64Bit {
  // field0 is header word.
  final Object field1;
  final int field2;
  final int field3;
  final int field4;
  final int field5;
  final int field6;
  final int field7;
  final int field8;
  final int field9;
  final int field10;
  final int field11;
  final int field12;
  final int field13;
  final int field14;
  final int field15;
  final int field16;
  final int field17;
  final int field18;
  final int field19;
  final int field20;
  final int field21;
  final int field22;
  final int field23;
  final int field24;
  final int field25;
  final int field26;
  final int field27;
  final int field28;
  final int field29;
  final int field30;
  final int field31;
  final int field32;
  final int field33;
  final int field34;
  final int field35;
  final int field36;
  final int field37;
  final int field38;
  final int field39;
  final int field40;
  final int field41;
  final int field42;
  final int field43;
  final int field44;
  final int field45;
  final int field46;
  final int field47;
  final int field48;
  final int field49;
  final int field50;
  final int field51;
  final int field52;
  final int field53;
  final int field54;
  final int field55;
  final int field56;
  final int field57;
  final int field58;
  final int field59;
  final int field60;
  final int field61;
  final int field62;
  final int field63;

  // For 64-bit targets there are no more bits available so we need to start
  // boxing all fields from here (this is performed in the class finalizer).

  final Object field64;

  // If GC incorrectly uses (bitmap & (1 << 65)) then will access bit of
  // [field1] and incorrectly think it is an object pointer.
  final int field65;

  // If GC incorrectly uses (bitmap & (1 << 66)) then will access bit of
  // [field2] and incorrectly think it is a unboxed value.
  final Object field66;

  const TargetLayout64Bit(
      this.field1,
      this.field2,
      this.field3,
      this.field4,
      this.field5,
      this.field6,
      this.field7,
      this.field8,
      this.field9,
      this.field10,
      this.field11,
      this.field12,
      this.field13,
      this.field14,
      this.field15,
      this.field16,
      this.field17,
      this.field18,
      this.field19,
      this.field20,
      this.field21,
      this.field22,
      this.field23,
      this.field24,
      this.field25,
      this.field26,
      this.field27,
      this.field28,
      this.field29,
      this.field30,
      this.field31,
      this.field32,
      this.field33,
      this.field34,
      this.field35,
      this.field36,
      this.field37,
      this.field38,
      this.field39,
      this.field40,
      this.field41,
      this.field42,
      this.field43,
      this.field44,
      this.field45,
      this.field46,
      this.field47,
      this.field48,
      this.field49,
      this.field50,
      this.field51,
      this.field52,
      this.field53,
      this.field54,
      this.field55,
      this.field56,
      this.field57,
      this.field58,
      this.field59,
      this.field60,
      this.field61,
      this.field62,
      this.field63,
      this.field64,
      this.field65,
      this.field66);

  // Ensure all fields are used.
  String toString() => '''
      <header>, $field1, $field2, $field3, $field4, $field5, $field6, $field7,
      $field8, $field9, $field10, $field11, $field12, $field13, $field14, $field15,
      $field16, $field17, $field18, $field19, $field20, $field21, $field22, $field23,
      $field24, $field25, $field26, $field27, $field28, $field29, $field30, $field31,
      $field32, $field33, $field34, $field35, $field36, $field37, $field38, $field39,
      $field40, $field41, $field42, $field43, $field44, $field45, $field46, $field47,
      $field48, $field49, $field50, $field51, $field52, $field53, $field54, $field55,
      $field56, $field57, $field58, $field59, $field60, $field61, $field62, $field63,
      $field64, $field65, $field66''';
}

@pragma('vm:never-inline')
buildTargetLayout64Bit() => TargetLayout64Bit(
    objectFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    integerFieldValue,
    objectFieldValue,
    integerFieldValue,
    objectFieldValue);
