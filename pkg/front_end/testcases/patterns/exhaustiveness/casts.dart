// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

nonExhaustiveDynamicAsStringOrDouble(o) => switch (o) {
      final String value => value,
      final double value as num => '$value',
    };

exhaustiveDynamicAsStringOrIntUnrestricted(o) => switch (o) {
      final String value => value,
      int(:bool isEven) as int => '$isEven',
    };

nonExhaustiveDynamicAsStringOrIntRestricted(o) => switch (o) {
      final String value => value,
      int(isEven: true) as int => '',
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

nonExhaustiveDynamicAsMRestricted(dynamic m) => switch (m) {
      (A() || B() || C(hashCode: 5)) as M => 0,
    };

exhaustiveDynamicAsMSeeminglyRestricted(dynamic m) => switch (m) {
      (A() || B() || C(hashCode: 5)) as A => 0,
    };

exhaustiveList(o) => switch (o) {
      [_] => 1,
      [...] as List => 0,
    };

nonExhaustiveList(o) => switch (o) {
      [] as List => 0,
    };
