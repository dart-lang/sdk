// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests equalities used when scrutinee is `dynamic` and cases have the same
// type and different types, with and without nulls.

import 'dart:convert';
import 'package:expect/expect.dart';

void main() {
  var s = utf8.decoder.convert([
    80,
    104,
    111,
    116,
    111,
    103,
    114,
    97,
    112,
    104,
    105,
    99,
    66,
    111,
    120,
  ]);

  Expect.isTrue(test1(s));
  Expect.isTrue(test2(s));
  Expect.isTrue(test3(s));
  Expect.isTrue(test4(s));

  // Test the same thing, but with another special cased type in dart2wasm
  // (int).
  var i = int.parse('123');

  Expect.isTrue(test5(i));
  Expect.isTrue(test6(i));
  Expect.isTrue(test7(i));
  Expect.isTrue(test8(i));
}

const kTypeString = 'PhotographicBox';

// Dynamic scrutinee with mixed type cases.
Object? test1(dynamic v) {
  switch (v) {
    case 1:
      throw 'int case in switch without null';
    case kTypeString:
      return true;
    default:
      throw 'default case in switch without null';
  }
}

// Dynamic scrutinee with mixed type cases and null.
Object? test2(dynamic v) {
  switch (v) {
    case 1:
      throw 'int case in switch with null';
    case null:
      throw 'null case';
    case kTypeString:
      return true;
    default:
      throw 'default case in switch with null';
  }
}

// Dynamic scrutinee with just string cases.
Object? test3(dynamic v) {
  switch (v) {
    case 'blah':
      throw 'string case';
    case kTypeString:
      return true;
    default:
      throw 'default case in string switch';
  }
}

// Dynamic scrutinee with just string and null cases.
Object? test4(dynamic v) {
  switch (v) {
    case 'blah':
      throw 'string case';
    case null:
      throw 'null case';
    case kTypeString:
      return true;
    default:
      throw 'default case in string switch';
  }
}

// Dynamic scrutinee with mixed type cases.
Object? test5(dynamic v) {
  switch (v) {
    case kTypeString:
      throw 'string case';
    case 123:
      return true;
    default:
      throw 'default case in switch without null';
  }
}

// Dynamic scrutinee with mixed type cases and null.
Object? test6(dynamic v) {
  switch (v) {
    case kTypeString:
      throw 'string case';
    case null:
      throw 'null case';
    case 123:
      return true;
    default:
      throw 'default case in switch with null';
  }
}

// Dynamic scrutinee with just int cases.
Object? test7(dynamic v) {
  switch (v) {
    case 0:
      throw 'wrong int';
    case 123:
      return true;
    default:
      throw 'default case in string switch';
  }
}

// Dynamic scrutinee with just int and null cases.
Object? test8(dynamic v) {
  switch (v) {
    case 0:
      throw 'wrong int';
    case null:
      throw 'null case';
    case 123:
      return true;
    default:
      throw 'default case in string switch';
  }
}
