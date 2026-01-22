// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinClassDeclaresConstructorTest);
  });
}

@reflectiveTest
class MixinClassDeclaresConstructorTest extends PubPackageResolutionTest {
  test_mixinClass_constructor_factory_blockBody() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A.named();
  factory A.x() {
    return A.named();
  }
}
class B with A {}
''');
  }

  test_mixinClass_constructor_factory_redirect() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A.named();
  factory A.x() = A.named;
}
class B with A {}
''');
  }

  test_mixinClass_constructor_generative_redirect() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  A() : this.named();
  A.named();
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 1)],
    );
  }

  test_mixinClass_constructor_newHead_nonTrivial_blockBody() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  new() {}
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 3)],
    );
  }

  test_mixinClass_constructor_newHead_nonTrivial_external() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  external new();
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 27, 3)],
    );
  }

  test_mixinClass_constructor_newHead_nonTrivial_hasFormalParameter() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  new(int foo);
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 3)],
    );
  }

  test_mixinClass_constructor_newHead_nonTrivial_super() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  new(): super();
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 3)],
    );
  }

  test_mixinClass_constructor_newHead_trivial() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  new();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_newHead_trivial_const() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  const new();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_trivial_named() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A.named();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_trivial_named_const() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  const A.named();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_nonTrivial_blockBody() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  A() {}
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 1)],
    );
  }

  test_mixinClass_constructor_typeName_nonTrivial_blockBody_named() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  A.named() {}
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 7)],
    );
  }

  test_mixinClass_constructor_typeName_nonTrivial_external() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  external A();
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 27, 1)],
    );
  }

  test_mixinClass_constructor_typeName_nonTrivial_hasFormalParameter() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  A(int foo);
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 1)],
    );
  }

  test_mixinClass_constructor_typeName_nonTrivial_super() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  A(): super();
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 18, 1)],
    );
  }

  test_mixinClass_constructor_typeName_trivial() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_trivial_const() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  const A();
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_named_nonTrivial_hasBody_block() async {
    await assertErrorsInCode(
      r'''
mixin class A.named() {
  this {}
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 12, 7)],
    );
  }

  test_mixinClass_primaryConstructor_named_nonTrivial_hasFormalParameter() async {
    await assertErrorsInCode(
      r'''
mixin class A.named(int x) {}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 12, 7)],
    );
  }

  test_mixinClass_primaryConstructor_named_nonTrivial_hasInitializer() async {
    await assertErrorsInCode(
      r'''
mixin class A.named() {
  this : assert(true);
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 12, 7)],
    );
  }

  test_mixinClass_primaryConstructor_named_trivial() async {
    await assertNoErrorsInCode(r'''
mixin class A.named() {}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_named_trivial_hasBody_empty() async {
    await assertNoErrorsInCode(r'''
mixin class A.named() {
  this;
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_nonTrivial_hasBody_block() async {
    await assertErrorsInCode(
      r'''
mixin class A() {
  this {}
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 12, 1)],
    );
  }

  test_mixinClass_primaryConstructor_unnamed_nonTrivial_hasFormalParameter() async {
    await assertErrorsInCode(
      r'''
mixin class A(int x) {}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 12, 1)],
    );
  }

  test_mixinClass_primaryConstructor_unnamed_nonTrivial_hasInitializer() async {
    await assertErrorsInCode(
      r'''
mixin class A() {
  this : assert(true);
}
class B with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 12, 1)],
    );
  }

  test_mixinClass_primaryConstructor_unnamed_trivial() async {
    await assertNoErrorsInCode(r'''
mixin class A() {}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_trivial_hasBody_empty() async {
    await assertNoErrorsInCode(r'''
mixin class A() {
  this;
}
class B with A {}
''');
  }

  test_withClause_class() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}
class B extends Object with A {}
''',
      [error(diag.mixinClassDeclaresConstructor, 49, 1)],
    );
  }

  test_withClause_classTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}
class B = Object with A;
''',
      [error(diag.mixinClassDeclaresConstructor, 43, 1)],
    );
  }

  test_withClause_enum() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}

enum E with A {
  v
}
''',
      [error(diag.mixinClassDeclaresConstructor, 34, 1)],
    );
  }
}
