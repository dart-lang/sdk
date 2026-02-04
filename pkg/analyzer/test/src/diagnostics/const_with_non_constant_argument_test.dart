// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
      [error(diag.constWithNonConstantArgument, 45, 1)],
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
        error(diag.constWithNonConstantArgument, 94, 3),
        error(diag.undefinedIdentifier, 94, 3),
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
      [error(diag.constWithNonConstantArgument, 26, 1)],
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
      [error(diag.constWithNonConstantArgument, 48, 1)],
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
      [error(diag.constWithNonConstantArgument, 83, 5)],
    );
  }
}
