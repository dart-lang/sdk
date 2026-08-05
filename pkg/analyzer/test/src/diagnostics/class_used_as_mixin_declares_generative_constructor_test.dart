// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_withClause_class_beforeClassModifiers_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: class-modifiers
class A {
  factory A() => throw 0;
}
class B extends Object with A {}
''');
  }

  test_withClause_class_beforeClassModifiers_generative_named() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: class-modifiers
class A {
  A.named();
}
class B extends Object with A {}
//                          ^
// [diag.classUsedAsMixinDeclaresGenerativeConstructor] The class 'A' can't be used as a mixin because it declares a generative constructor.
''');
  }

  test_withClause_class_beforeClassModifiers_generative_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: class-modifiers
class A {
  A();
}
class B extends Object with A {}
//                          ^
// [diag.classUsedAsMixinDeclaresGenerativeConstructor] The class 'A' can't be used as a mixin because it declares a generative constructor.
''');
  }

  test_withClause_classTypeAlias_beforeClassModifiers_generative_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: class-modifiers
class A {
  A();
}
class B = Object with A;
//                    ^
// [diag.classUsedAsMixinDeclaresGenerativeConstructor] The class 'A' can't be used as a mixin because it declares a generative constructor.
''');
  }

  test_withClause_enum_beforeClassModifiers_generative_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: class-modifiers
class A {
  A();
}

enum E with A {
//          ^
// [diag.classUsedAsMixinDeclaresGenerativeConstructor] The class 'A' can't be used as a mixin because it declares a generative constructor.
  v
}
''');
  }
}
