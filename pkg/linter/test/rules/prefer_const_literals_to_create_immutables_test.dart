// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstLiteralsToCreateImmutablesTest);
  });
}

@reflectiveTest
class PreferConstLiteralsToCreateImmutablesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.prefer_const_literals_to_create_immutables;

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
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';

@immutable
extension type E(List<int> i) { }

var e = E([![1]!]);
''');
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
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(List<Object> p);
}
var x = C(/*[0*/[
  /*[1*/[]/*1]*/,
]/*0]*/);
''');
  }

  test_listLiteral_noConst() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(List<Object> p);
}
var x = C([![]!]);
''');
  }

  test_listLiteral_noConst_instantiationAnnotation() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@Immutable('')
class C {
  const C(List<Object> p);
}
var x = C([![]!]);
''');
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
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Object? p);
}
var x = C((([!{}!])));
''');
  }

  test_mapLiteral_intToDouble_noConst() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C([!{1: 1.0}!]);
''');
  }

  test_mapLiteral_intToInstantiation_const() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Object? p);
}
var x = C([!{1: const C(null)}!]);
''');
  }

  test_mapLiteral_intToInt_noConst() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C([!{1: 1}!]);
''');
  }

  test_mapLiteral_intToNull_noConst() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C([!{1: null}!]);
''');
  }

  test_mapLiteral_intToString_noConst() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, Object?> p);
}
var x = C([!{1: ''}!]);
''');
  }

  test_mapLiteral_noConst() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C(Map<int, int> p);
}
var x = C([!{1: 2}!]);
''');
  }

  test_missingRequiredArgument() async {
    await assertDiagnostics(
      r'''
import 'package:meta/meta.dart';

@immutable
class K {
  final List<K> children;
  const K({required this.children});
}

final k = K(
  children: <K>[for (var i = 0; i < 5; ++i) K()], // OK
);
''',
      [
        // No lint
        error(diag.missingRequiredArgument, 178, 1),
      ],
    );
  }

  test_namedParameter_noConst() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:meta/meta.dart';
@immutable
class C {
  const C({Object? p});
}
var x = C(p: [![]!]);
''');
  }

  test_newWithNonType() async {
    await assertDiagnostics(
      r'''
var e1 = new B([]); // OK
''',
      [
        // No lint
        error(diag.newWithNonType, 13, 1),
      ],
    );
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
