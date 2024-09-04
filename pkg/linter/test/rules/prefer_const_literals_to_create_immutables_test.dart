// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstLiteralsToCreateImmutablesTest);
  });
}

@reflectiveTest
class PreferConstLiteralsToCreateImmutablesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'prefer_const_literals_to_create_immutables';

  test_boolFromEnvironment() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

const x = bool.fromEnvironment('dart.library.js_util');

@immutable
class A {
  const A(List<int> p);
}

var a = A([
  if (x) e(),
]);

int e() => 7;
''');
  }

  test_extensionType() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
extension type E(List<int> i) { }

var e = E([1]);
''', [
      lint(90, 3),
    ]);
  }

  test_listLiteral_const() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(List<Object> p);
}
var x = C(const []);
''');
  }

  test_listLiteral_nested_const() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(List<Object> p);
}
var x = C(const [
  const [],
]);
''');
  }

  test_listLiteral_nested_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(List<Object> p);
}
var x = C([
  [],
]);
''', [
      lint(93, 9),
      lint(97, 2),
    ]);
  }

  test_listLiteral_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(List<Object> p);
}
var x = C([]);
''', [
      lint(93, 2),
    ]);
  }

  test_listLiteral_notConstable_noConst() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(List<Object> p);
}
class D {}
var x = C([D()]);
''');
  }

  test_mapLiteral_const() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, int> p);
}
var x = C(const {1: 2});
''');
  }

  test_mapLiteral_inParens_const() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Object? p);
}
var x = C(((const {})));
''');
  }

  test_mapLiteral_inParens_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Object? p);
}
var x = C((({})));
''', [
      lint(90, 2),
    ]);
  }

  test_mapLiteral_intToDouble_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C({1: 1.0});
''', [
      lint(98, 8),
    ]);
  }

  test_mapLiteral_intToInstantiation_const() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Object? p);
}
var x = C({1: const C(null)});
''', [
      lint(88, 18),
    ]);
  }

  test_mapLiteral_intToInt_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C({1: 1});
''', [
      lint(98, 6),
    ]);
  }

  test_mapLiteral_intToNull_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C({1: null});
''', [
      lint(98, 9),
    ]);
  }

  test_mapLiteral_intToString_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C({1: ''});
''', [
      lint(98, 7),
    ]);
  }

  test_mapLiteral_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, int> p);
}
var x = C({1: 2});
''', [
      lint(94, 6),
    ]);
  }

  test_missingRequiredArgument() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class K {
  final List<K> children;
  const K({required this.children});
}

final k = K(
  children: <K>[for (var i = 0; i < 5; ++i) K()], // OK
);
''', [
      // No lint
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 178, 1),
    ]);
  }

  test_namedParameter_noConst() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C({Object? p});
}
var x = C(p: []);
''', [
      lint(93, 2),
    ]);
  }

  test_newWithNonType() async {
    await assertDiagnostics(r'''
var e1 = new B([]); // OK
''', [
      // No lint
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 13, 1),
    ]);
  }

  test_notImmutable_noConst() async {
    await assertNoDiagnostics(r'''
class C {
  const C(List<Object> p);
}
var x = C([]);
''');
  }
}
