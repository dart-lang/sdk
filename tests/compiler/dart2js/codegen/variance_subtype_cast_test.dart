// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String LEGACY_COV_CAST = r"""
class LegacyCovariant<T> {
  void method() {}
}
foo(param) {
  LegacyCovariant<num> c = LegacyCovariant<num>();
  (c as LegacyCovariant<int>).method();
  // present: 'LegacyCovariant_int._as'
}
""";

const String LEGACY_COV_NO_CAST = r"""
class LegacyCovariant<T> {
  void method() {}
}
foo(param) {
  LegacyCovariant<num> c = LegacyCovariant<num>();
  (c as LegacyCovariant<Object>).method();
  // absent: 'LegacyCovariant_Object._as'
}
""";

const String COV_CAST = r"""
class Covariant<out T> {
  void method() {}
}
foo(param) {
  Covariant<num> c = Covariant<num>();
  (c as Covariant<int>).method();
  // present: 'Covariant_int._as'
}
""";

const String COV_NO_CAST = r"""
class Covariant<out T> {
  void method() {}
}
foo(param) {
  Covariant<num> c = Covariant<num>();
  (c as Covariant<Object>).method();
  // absent: 'Covariant_Object._as'
}
""";

const String CONTRA_CAST = r"""
class Contravariant<in T> {
  void method() {}
}
foo(param) {
  Contravariant<num> c = Contravariant<num>();
  (c as Contravariant<Object>).method();
  // present: 'Contravariant_Object._as'
}
""";

const String CONTRA_NO_CAST = r"""
class Contravariant<in T> {
  void method() {}
}
foo(param) {
  Contravariant<num> c = Contravariant<num>();
  (c as Contravariant<int>).method();
  // absent: 'Contravariant_int._as'
}
""";

const String INV_CAST1 = r"""
class Invariant<inout T> {
  void method() {}
}
foo(param) {
  Invariant<num> i = Invariant<num>();
  (i as Invariant<Object>).method();
  // present: 'Invariant_Object._as'
}
""";

const String INV_CAST2 = r"""
class Invariant<inout T> {
  void method() {}
}
foo(param) {
  Invariant<num> i = Invariant<num>();
  (i as Invariant<int>).method();
  // present: 'Invariant_int._as'
}
""";

const String INV_NO_CAST = r"""
class Invariant<inout T> {
  void method() {}
}
foo(param) {
  Invariant<num> i = Invariant<num>();
  (i as Invariant<num>).method();
  // absent: 'Invariant_num._as'
}
""";

main() {
  runTests() async {
    Future check(String test) {
      return compile(test,
          entry: 'foo',
          check: checkerForAbsentPresent(test),
          newRti: true,
          enableVariance: true);
    }

    await check(LEGACY_COV_CAST);
    await check(LEGACY_COV_NO_CAST);
    await check(COV_CAST);
    await check(COV_NO_CAST);
    await check(CONTRA_CAST);
    await check(CONTRA_NO_CAST);
    await check(INV_CAST1);
    await check(INV_CAST2);
    await check(INV_NO_CAST);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
