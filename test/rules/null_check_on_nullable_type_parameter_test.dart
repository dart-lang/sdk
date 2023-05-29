// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullCheckOnNullableTypeParameterTest);
  });
}

@reflectiveTest
class NullCheckOnNullableTypeParameterTest extends LintRuleTest {
  @override
  String get lintRule => 'null_check_on_nullable_type_parameter';

  test_nullAssertPattern_ifCase() async {
    await assertDiagnostics(r'''
f<T>(T? x){
  if (x case var y!) print(y);
}
''', [
      lint(30, 1),
    ]);
  }

  test_nullAssertPattern_list() async {
    await assertDiagnostics(r'''
f<T>(List<T?> l){
  var [x!, y] = l;
}
''', [
      lint(26, 1),
    ]);
  }

  test_nullAssertPattern_logicalOr() async {
    await assertDiagnostics(r'''
f<T>(T? x){
  switch(x) {
    case var y! || var y! : print(y);
  }
}
''', [
      lint(40, 1),
      error(WarningCode.DEAD_CODE, 42, 9),
      lint(50, 1),
    ]);
  }

  test_nullAssertPattern_map() async {
    await assertDiagnostics(r'''
f<T>(Map<String, T?> m){
  var {'x': y!} = m;
}
''', [
      lint(38, 1),
    ]);
  }

  test_nullAssertPattern_object() async {
    await assertDiagnostics(r'''
class A<E> {
  E? a;
  A(this.a);
}

f<T>(T? t, A<T> u) {
  A(a: t!) = u;
}
''', [
      lint(66, 1),
    ]);
  }

  test_nullAssertPattern_record() async {
    await assertDiagnostics(r'''
f<T>((T?, T?) p){
  var (x!, y) = p;
}
''', [
      lint(26, 1),
    ]);
  }
}
