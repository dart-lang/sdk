// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(
      r'''
class A {
  const A(int p);
}
var v = 42;
@A(v)
main() {
}
''',
      [error(CompileTimeErrorCode.constWithNonConstantArgument, 45, 1)],
    );
  }

  test_classShadowedBySetter() async {
    await assertErrorsInCode(
      r'''
class Annotation {
  const Annotation(Object obj);
}

class Bar {}

class Foo {
  @Annotation(Bar)
  set Bar(int value) {}
}
''',
      [
        error(CompileTimeErrorCode.constWithNonConstantArgument, 94, 3),
        error(CompileTimeErrorCode.undefinedIdentifier, 94, 3),
      ],
    );
  }

  test_enumConstant() async {
    await assertErrorsInCode(
      r'''
var a = 42;

enum E {
  v(a);
  const E(_);
}
''',
      [error(CompileTimeErrorCode.constWithNonConstantArgument, 26, 1)],
    );
  }

  test_enumConstant_constantContext() async {
    await assertNoErrorsInCode(r'''
enum E {
  v([]);
  const E(_);
}
''');
  }

  test_instanceCreation() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(a);
}
f(p) { return const A(p); }
''',
      [error(CompileTimeErrorCode.constWithNonConstantArgument, 48, 1)],
    );
  }

  test_issue47603() async {
    await assertErrorsInCode(
      r'''
class C {
  final void Function() c;
  const C(this.c);
}

void main() {
  const C(() {});
}
''',
      [error(CompileTimeErrorCode.constWithNonConstantArgument, 83, 5)],
    );
  }
}
