// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstConstructorsTest);
  });
}

@reflectiveTest
class PreferConstConstructorsTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'prefer_const_constructors';

  test_canBeConst_argumentIsAdjacentStrings() async {
    await assertDiagnostics(r'''
class A {
  const A(String s);
}
var a = A('adjacent' 'string');
''', [
      lint(41, 22),
    ]);
  }

  test_canBeConst_argumentIsListLiteral() async {
    await assertDiagnostics(r'''
class A {
  const A(List<int> l);
}
var a = A([]);
''', [
      lint(44, 5),
    ]);
  }

  test_canBeConst_argumentIsMap_nonLiteral() async {
    await assertNoDiagnostics(r'''
class A {
  const A(Map<int, int> m);
}
A f(Map<int, int> m) => A(m);
''');
  }

  test_canBeConst_argumentIsMapLiteral_containsNonLiteral() async {
    await assertNoDiagnostics(r'''
class A {
  const A(Map<int, int> m);
}
A f(int x) => A({x: x});
''');
  }

  test_canBeConst_argumentIsMapLiteral_instantiated() async {
    await assertDiagnostics(r'''
class A {
  const A(Map<int, int> m);
}
var a = A({});
''', [
      lint(48, 5),
    ]);
  }

  test_canBeConst_explicitTypeArgument_dynamic() async {
    await assertDiagnostics(r'''
class A<T> {
  const A();
}
var a = A<dynamic>();
''', [
      lint(36, 12),
    ]);
  }

  test_canBeConst_explicitTypeArgument_string() async {
    await assertDiagnostics(r'''
class A<T> {
  const A();
}
var a = A<String>();
''', [
      lint(36, 11),
    ]);
  }

  test_canBeConst_intLiteralArgument() async {
    await assertDiagnostics(r'''
class A {
  const A(int x);
}
var a = A(5);
''', [
      lint(38, 4),
    ]);
  }

  test_canBeConst_optionalNamedParameter() async {
    await assertDiagnostics(r'''
class A {
  const A({A? parent});
}
var a = A();
''', [
      lint(44, 3),
    ]);
  }

  test_canBeConst_optionalNamedParameter_nested() async {
    await assertDiagnostics(r'''
class A {
  const A({A? parent});
  const A.a();
}
var a = A(
  parent: A.a(),
);
''', [
      lint(59, 21),
      lint(72, 5),
    ]);
  }

  test_canBeConst_optionalNamedParameter_newKeyword() async {
    await assertDiagnostics(r'''
class A {
  const A({A? parent});
}
var a = new A();
''', [
      lint(44, 7),
    ]);
  }

  test_cannotBeConst_argumentIsAdjacentStrings_withInterpolation() async {
    await assertNoDiagnostics(r'''
class A {
  const A(String s);
}
A f(int i) => A('adjacent' '$i');
''');
  }

  test_cannotBeConst_argumentIsListLiteral_nonLiteralElement() async {
    await assertNoDiagnostics(r'''
class A {
  const A(List<int> l);
}
A f(int i) => A([i]);
''');
  }

  test_cannotBeConst_argumentIsLocalVariable() async {
    await assertNoDiagnostics(r'''
class A {
  const A(String s);
}

void f() {
  final s = '';
  var a = A(s);
}
''');
  }

  test_cannotBeConst_argumentIsNonLiteral() async {
    await assertNoDiagnostics(r'''
class A {
  const A(String s);
}
A f(String s) => A(s);
''');
  }

  test_cannotBeConst_argumentIsNonLiteralList() async {
    await assertNoDiagnostics(r'''
class A {
  const A(List<int> l);
}
A f(List<int> l) => A(l);
''');
  }

  test_cannotBeConst_explicitTypeArgument_typeVariable() async {
    await assertNoDiagnostics(r'''
class A<T> {
  const A();
}
void f<U>() => A<U>();
''');
  }

  test_cannotBeConst_nonConstArgument() async {
    await assertNoDiagnostics(r'''
class A {
  final int x;

  const A(this.x);
}
A f(int x) => A(x);
''');
  }

  test_cannotBeConst_notConstConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  A();
}
var a = A();
''');
  }

  test_cannotBeConst_stringLiteralArgument_withInterpolation() async {
    await assertNoDiagnostics(r'''
class A {
  const A(String s);
  static A m1(int i) => A('$i');
}
''');
  }

  test_deferred_arg() async {
    newFile2('$testPackageLibPath/a.dart', '''
class A {
  const A();
}

const aa = A();
''');

    await assertNoDiagnostics(r'''
import 'a.dart' deferred as a;

class B {
  const B(Object a);
}

main() {
  var b = B(a.aa);
}
''');
  }

  test_deferredConstructorCall() async {
    newFile2('$testPackageLibPath/a.dart', '''
class A {
  const A();
}
''');

    await assertNoDiagnostics(r'''
import 'a.dart' deferred as a;

void f() {
  var aa = a.A();
}
''');
  }

  test_extensionType_constPrimaryConstructor() async {
    await assertDiagnostics(r'''
extension type const E(int i) {}

var e = E(1);
''', [
      lint(42, 4),
    ]);
  }

  test_extensionType_nonConstPrimaryConstructor() async {
    await assertNoDiagnostics(r'''
extension type E(int i) {}

var e = E(1);
''');
  }

  test_extraPositionalArgument() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

class K {
  @literal
  const K();
}

K k() {
  var kk = K();
  return kk;
}
''', [
      // No lint
      error(WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR, 90, 3),
    ]);
  }

  test_isConst_intLiteralArgument() async {
    await assertNoDiagnostics(r'''
class A {
  final int x;

  const A(this.x);
}
A f() => const A(5);
''');
  }

  test_isConstCall_optionalNamedParameter() async {
    await assertNoDiagnostics(r'''
class A {
  const A({A? parent});
}
var a = const A();
''');
  }

  test_objectConstructorCall() async {
    await assertNoDiagnostics(r'''
var x = Object();
''');
  }
}
