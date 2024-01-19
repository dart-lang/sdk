// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

exhaustiveDynamicAsStringOrInt(o) => switch (o) {
      final String value => value,
      final value as int => '$value',
    };

exhaustiveDynamicAsStringOrIntAnd(o) => switch (o) {
      final String value => value,
      (final value && final value2) as int => '$value$value2',
    };

exhaustiveDynamicAsStringOrNum(o) => switch (o) {
      final String value => value,
      final num value as int => '$value',
    };

exhaustiveDynamicAsStringOrIntUnrestricted(o) => switch (o) {
      final String value => value,
      int(:bool isEven) as int => '$isEven',
    };

sealed class M {}

class A extends M {}

class B extends M {}

class C extends M {}

exhaustiveMAsM(M m) => switch (m) {
      (A() || B() || C()) as M => 0,
    };

exhaustiveDynamicAsM(dynamic m) => switch (m) {
      (A() || B() || C()) as M => 0,
    };

exhaustiveDynamicAsMUnrestricted(dynamic m) => switch (m) {
      (A() || B() || C(hashCode: int())) as M => 0,
    };

exhaustiveDynamicAsMSeeminglyRestricted(dynamic m) => switch (m) {
      (A() || B() || C(hashCode: 5)) as A => 0,
    };

exhaustiveList(o) => switch (o) {
      [_] => 1,
      [...] as List => 0,
    };

main() {
  Expect.equals('foo', exhaustiveDynamicAsStringOrInt('foo'));
  Expect.equals('42', exhaustiveDynamicAsStringOrInt(42));
  Expect.throws(() => exhaustiveDynamicAsStringOrInt(true));

  Expect.equals('foo', exhaustiveDynamicAsStringOrIntAnd('foo'));
  Expect.equals('4242', exhaustiveDynamicAsStringOrIntAnd(42));
  Expect.throws(() => exhaustiveDynamicAsStringOrIntAnd(true));

  Expect.equals('foo', exhaustiveDynamicAsStringOrNum('foo'));
  Expect.equals('42', exhaustiveDynamicAsStringOrNum(42));
  Expect.throws(() => exhaustiveDynamicAsStringOrNum(3.14));

  Expect.equals('foo', exhaustiveDynamicAsStringOrIntUnrestricted('foo'));
  Expect.equals('true', exhaustiveDynamicAsStringOrIntUnrestricted(42));
  Expect.equals('false', exhaustiveDynamicAsStringOrIntUnrestricted(87));
  Expect.throws(() => exhaustiveDynamicAsStringOrIntUnrestricted(true));

  Expect.equals(0, exhaustiveMAsM(A()));
  Expect.equals(0, exhaustiveMAsM(B()));
  Expect.equals(0, exhaustiveMAsM(C()));

  Expect.equals(0, exhaustiveDynamicAsM(A()));
  Expect.equals(0, exhaustiveDynamicAsM(B()));
  Expect.equals(0, exhaustiveDynamicAsM(C()));
  Expect.throws(() => exhaustiveDynamicAsM(true));

  Expect.equals(0, exhaustiveDynamicAsMUnrestricted(A()));
  Expect.equals(0, exhaustiveDynamicAsMUnrestricted(B()));
  Expect.equals(0, exhaustiveDynamicAsMUnrestricted(C()));
  Expect.throws(() => exhaustiveDynamicAsMUnrestricted(true));

  Expect.equals(0, exhaustiveDynamicAsMSeeminglyRestricted(A()));
  Expect.throws(() => exhaustiveDynamicAsMSeeminglyRestricted(B()));
  Expect.throws(() => exhaustiveDynamicAsMSeeminglyRestricted(C()));
  Expect.throws(() => exhaustiveDynamicAsMSeeminglyRestricted(true));

  Expect.equals(0, exhaustiveList([]));
  Expect.equals(1, exhaustiveList([0]));
  Expect.equals(0, exhaustiveList([0, 1]));
  Expect.throws(() => exhaustiveList(true));
}
