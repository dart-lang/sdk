// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      MixinClassDeclaresNonTrivialGenerativeConstructorTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinClassDeclaresNonTrivialGenerativeConstructorTest
    extends PubPackageResolutionTest {
  test_mixinClass_constructor_factory_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A.named();
  factory A.x() = A.named;
}
class B with A {}
''');
  }

  test_mixinClass_constructor_generative_redirect() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A() : this.named();
//^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
  A.named();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_newHead_nonTrivial_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  new() {}
//^^^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_newHead_nonTrivial_external() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  external new();
//         ^^^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_newHead_nonTrivial_hasFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  new(int foo);
//^^^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_newHead_nonTrivial_super() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  new(): super();
//^^^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_newHead_trivial() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  new();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_newHead_trivial_const() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  const new();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_trivial_named() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A.named();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_trivial_named_const() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  const A.named();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_nonTrivial_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A() {}
//^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_nonTrivial_blockBody_named() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A.named() {}
//^^^^^^^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_nonTrivial_external() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  external A();
//         ^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_nonTrivial_hasFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A(int foo);
//^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_nonTrivial_super() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A(): super();
//^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_trivial() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  A();
}
class B with A {}
''');
  }

  test_mixinClass_constructor_typeName_trivial_const() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {
  const A();
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_named_nonTrivial_hasBody_block() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A.named() {
  this {}
//     ^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_named_nonTrivial_hasFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A.named(int x) {}
//          ^^^^^^^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_named_nonTrivial_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A.named() {
  this : assert(true);
//     ^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_named_trivial() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A.named() {}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_named_trivial_hasBody_empty() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A.named() {
  this;
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_nonTrivial_hasBody_block() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A() {
  this {}
//     ^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_nonTrivial_hasBody_block_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A() {
  this : assert(true) {}
//     ^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_nonTrivial_hasFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A(int x) {}
//          ^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_nonTrivial_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A() {
  this : assert(true);
//     ^
// [diag.mixinClassDeclaresNonTrivialGenerativeConstructor] The mixin class 'A' can't declare a non-trivial generative constructor.
}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_trivial() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A() {}
class B with A {}
''');
  }

  test_mixinClass_primaryConstructor_unnamed_trivial_hasBody_empty() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A() {
  this;
}
class B with A {}
''');
  }
}
