// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final bool kTrue = int.parse('1') == 1;

main() {
  // Ensure fields are not inferred to be constants and ensure we use all fields
  // (to avoid them being tree shaken).
  final useAllFields = (kTrue ? foo : foo2).toString();
  for (int i = 0; i <= 64; ++i) {
    Expect.isTrue(useAllFields.contains('$i'));
  }

  // Ensure calling dyn:get:field64 returns the right value.
  Expect.equals(64, ((kTrue ? foo : Baz(10)) as dynamic).field64);

  // Ensure calling get:field64 returns the right value.
  Expect.equals(64, (kTrue ? foo : Bar(10)).field64);

  // Ensure potentially inlined, direct field load yield right value.
  Expect.equals(64, (kTrue ? foo : foo2).field64);
}

final foo = Foo(
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    47,
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64);

final foo2 = Foo(
    2 * 0,
    2 * 1,
    2 * 2,
    2 * 3,
    2 * 4,
    2 * 5,
    2 * 6,
    2 * 7,
    2 * 8,
    2 * 9,
    2 * 10,
    2 * 11,
    2 * 12,
    2 * 13,
    2 * 14,
    2 * 15,
    2 * 16,
    2 * 17,
    2 * 18,
    2 * 19,
    2 * 20,
    2 * 21,
    2 * 22,
    2 * 23,
    2 * 24,
    2 * 25,
    2 * 26,
    2 * 27,
    2 * 28,
    2 * 29,
    2 * 30,
    2 * 31,
    2 * 32,
    2 * 33,
    2 * 34,
    2 * 35,
    2 * 36,
    2 * 37,
    2 * 38,
    2 * 39,
    2 * 40,
    2 * 41,
    2 * 42,
    2 * 43,
    2 * 44,
    2 * 45,
    2 * 46,
    2 * 47,
    2 * 48,
    2 * 49,
    2 * 50,
    2 * 51,
    2 * 52,
    2 * 53,
    2 * 54,
    2 * 55,
    2 * 56,
    2 * 57,
    2 * 58,
    2 * 59,
    2 * 60,
    2 * 61,
    2 * 62,
    2 * 63,
    2 * 64);

class Bar {
  final int field64;
  Bar(this.field64);
}

class Baz {
  final int field64;
  Baz(this.field64);
}

class Foo implements Bar {
  final int field0;
  final int field1;
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
  final int field64;

  Foo(
      this.field0,
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
      this.field64);

  toString() => '''
     $field0;
     $field1;
     $field2;
     $field3;
     $field4;
     $field5;
     $field6;
     $field7;
     $field8;
     $field9;
    $field10;
    $field11;
    $field12;
    $field13;
    $field14;
    $field15;
    $field16;
    $field17;
    $field18;
    $field19;
    $field20;
    $field21;
    $field22;
    $field23;
    $field24;
    $field25;
    $field26;
    $field27;
    $field28;
    $field29;
    $field30;
    $field31;
    $field32;
    $field33;
    $field34;
    $field35;
    $field36;
    $field37;
    $field38;
    $field39;
    $field40;
    $field41;
    $field42;
    $field43;
    $field44;
    $field45;
    $field46;
    $field47;
    $field48;
    $field49;
    $field50;
    $field51;
    $field52;
    $field53;
    $field54;
    $field55;
    $field56;
    $field57;
    $field58;
    $field59;
    $field60;
    $field61;
    $field62;
    $field63;
    $field64;
    ''';
}
