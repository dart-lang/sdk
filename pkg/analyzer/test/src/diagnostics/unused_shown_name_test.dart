// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedShownNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnusedShownNameTest extends PubPackageResolutionTest {
  test_dartCore_unused() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as core show int;
''');
  }

  test_extension_instance_method_unused() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
String s = '';
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' show E, s;
//                      ^
// [diag.unusedShownName] The name E is shown, but isn't used.

f() {
  s.length;
}
''');
  }

  test_extension_instance_method_used() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {
  String empty() => '';
}
''');
    await resolveTestCodeWithDiagnostics('''
import 'lib1.dart' show E;

f() {
  ''.empty();
}
''');
  }

  test_referenced_prefixed_assignmentExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p show a;

void f() {
  p.a = 0;
}
''');
  }

  test_referenced_prefixed_postfixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p show a;

void f() {
  p.a++;
}
''');
  }

  test_referenced_prefixed_prefixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p show a;

void f() {
  ++p.a;
}
''');
  }

  test_referenced_unprefixed_assignmentExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show a;

void f() {
  a = 0;
}
''');
  }

  test_referenced_unprefixed_postfixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show a;

void f() {
  a++;
}
''');
  }

  test_referenced_unprefixed_prefixExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
var a = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show a;

void f() {
  ++a;
}
''');
  }

  test_unreferenced() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' show A, B;
//                         ^
// [diag.unusedShownName] The name B is shown, but isn't used.
A a = A();
''');
  }

  test_unreferenced_dotShorthand() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}

void f(A a) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' show A, f;
//                   ^
// [diag.unusedShownName] The name A is shown, but isn't used.

void g() {
  f(.new());
}
''');
  }

  test_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' show max, FooBar;
//                           ^^^^^^
// [diag.undefinedShownName] The library 'dart:math' doesn't export a member with the shown name 'FooBar'.
main() {
  print(max(1, 2));
}
''');
  }

  test_unusedShownName_as() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as p show A, B;
//                              ^
// [diag.unusedShownName] The name B is shown, but isn't used.
p.A a = p.A();
''');
  }

  test_unusedShownName_duplicates() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
class C {}
class D {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' show A, B;
//                         ^
// [diag.unusedShownName] The name B is shown, but isn't used.
import 'lib1.dart' show C, D;
//                         ^
// [diag.unusedShownName] The name D is shown, but isn't used.
A a = A();
C c = C();
''');
  }

  test_unusedShownName_topLevelVariable() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int var1 = 1;
const int var2 = 2;
const int var3 = 3;
const int var4 = 4;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' show var1, var2;
import 'lib1.dart' show var3, var4;
//                            ^^^^
// [diag.unusedShownName] The name var4 is shown, but isn't used.
int a = var1;
int b = var2;
int c = var3;
''');
  }
}
