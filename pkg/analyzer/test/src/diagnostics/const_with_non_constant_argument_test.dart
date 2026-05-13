// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithNonConstantArgumentTest);
  });
}

@reflectiveTest
class ConstWithNonConstantArgumentTest extends PubPackageResolutionTest {
  test_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int p);
}
var v = 42;
@A(v)
// ^
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
main() {
}
''');
  }

  test_classShadowedBySetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class Annotation {
  const Annotation(Object obj);
}

class Bar {}

class Foo {
  @Annotation(Bar)
//            ^^^
// [diag.undefinedIdentifier] Undefined name 'Bar'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  set Bar(int value) {}
}
''');
  }

  test_enumConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
var a = 42;

enum E {
  v(a);
//  ^
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  const E(_);
}
''');
  }

  test_enumConstant_constantContext() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v([]);
  const E(_);
}
''');
  }

  test_instanceCreation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(a);
}
f(p) { return const A(p); }
//                    ^
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
''');
  }

  test_issue47603() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final void Function() c;
  const C(this.c);
}

void main() {
  const C(() {});
//        ^^^^^
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
}
''');
  }
}
