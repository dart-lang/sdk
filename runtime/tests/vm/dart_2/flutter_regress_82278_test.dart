// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

class Foo {
  static int _next = 0;

  var field0 = ++_next;
  var field1 = ++_next;
  var field2 = ++_next;
  var field3 = ++_next;
  var field4 = ++_next;
  var field5 = ++_next;
  var field6 = ++_next;
  var field7 = ++_next;
  var field8 = ++_next;
  var field9 = ++_next;
  var field10 = ++_next;
  var field11 = ++_next;
  var field12 = ++_next;
  var field13 = ++_next;
  var field14 = ++_next;
  var field15 = ++_next;
  var field16 = ++_next;
  var field17 = ++_next;
  var field18 = ++_next;
  var field19 = ++_next;
  var field20 = ++_next;
  var field21 = ++_next;
  var field22 = ++_next;
  var field23 = ++_next;
  var field24 = ++_next;
  var field25 = ++_next;
  var field26 = ++_next;
  var field27 = ++_next;
  var field28 = ++_next;
  var field29 = ++_next;
  var field30 = ++_next;
  var field31 = ++_next;

  @pragma('vm:never-inline')
  String toString() => '$field0 $field1 $field2 $field3 $field4 $field5'
      '$field6 $field7 $field8 $field9 $field10 $field11'
      '$field12 $field13 $field14 $field15 $field16 $field17'
      '$field18 $field19 $field20 $field21 $field22 $field23'
      '$field24 $field25 $field26 $field27 $field28 $field29'
      '$field30 $field3';
}

// The TypeArgumentVector will be at an offset that cannot be loaded from via
// normal addresing mode on ARM64.
class GenericFoo<T> extends Foo {}

final l = <dynamic>[GenericFoo<int>(), null, 1, 1.0];

main() {
  final dynamic genericFoo = l[0];
  Expect.isTrue(genericFoo.toString().length > 0); // Keep the fields alive.
  Expect.isTrue(identical(genericFoo as GenericFoo<int>, genericFoo));
}
