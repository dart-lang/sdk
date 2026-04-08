// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassUsedAsMixinDeclaresGenerativeConstructorTest);
  });
}

@reflectiveTest
class ClassUsedAsMixinDeclaresGenerativeConstructorTest
    extends PubPackageResolutionTest {
  test_withClause_class_language219_factory() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
class A {
  factory A() => throw 0;
}
class B extends Object with A {}
''');
  }

  test_withClause_class_language219_generative_named() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A {
  A.named();
}
class B extends Object with A {}
''',
      [error(diag.classUsedAsMixinDeclaresGenerativeConstructor, 69, 1)],
    );
  }

  test_withClause_class_language219_generative_unnamed() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A {
  A();
}
class B extends Object with A {}
''',
      [error(diag.classUsedAsMixinDeclaresGenerativeConstructor, 63, 1)],
    );
  }

  test_withClause_classTypeAlias_language219_generative_unnamed() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A {
  A();
}
class B = Object with A;
''',
      [error(diag.classUsedAsMixinDeclaresGenerativeConstructor, 57, 1)],
    );
  }

  test_withClause_enum_language219_generative_unnamed() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A {
  A();
}

enum E with A {
  v
}
''',
      [error(diag.classUsedAsMixinDeclaresGenerativeConstructor, 48, 1)],
    );
  }
}
