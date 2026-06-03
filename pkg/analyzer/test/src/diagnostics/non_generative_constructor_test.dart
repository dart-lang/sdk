// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonGenerativeConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonGenerativeConstructorTest extends PubPackageResolutionTest {
  test_factory_explicit_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named() => throw 0;
  A.generative();
}
class B extends A {
  B() : super.named();
//      ^^^^^^^^^^^^^
// [diag.nonGenerativeConstructor] The generative constructor 'A.named()' is expected, but a factory was found.
}
''');
  }

  test_factory_explicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named() => throw 0;
  A.generative();
}
class B() extends A {
  this : super.named();
//       ^^^^^^^^^^^^^
// [diag.nonGenerativeConstructor] The generative constructor 'A.named()' is expected, but a factory was found.
}
''');
  }

  test_factory_implicit_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw 0;
  A.named();
}
class B extends A {
  new foo();
//^^^^^^^
// [diag.nonGenerativeConstructor] The generative constructor 'A()' is expected, but a factory was found.
}
''');
  }

  test_factory_implicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw 0;
  A.named();
}
class B extends A {
  B.foo();
//^^^^^
// [diag.nonGenerativeConstructor] The generative constructor 'A()' is expected, but a factory was found.
}
''');
  }

  test_factory_implicit_constructor_typeName_external() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
  factory A() => throw 0;
}
class B extends A {
  external B();
}
''');
  }

  test_factory_implicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw 0;
  A.named();
}
class B() extends A {
  this;
//^^^^
// [diag.nonGenerativeConstructor] The generative constructor 'A()' is expected, but a factory was found.
}
''');
  }

  test_generative_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
  factory A() => throw 0;
}
class B extends A {
  B() : super.named();
}
''');
  }

  test_generative_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
  factory A() => throw 0;
}
class B() extends A {
  this : super.named();
}
''');
  }

  test_generative_primaryContructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
  factory A() => throw 0;
}
class B() extends A {
  this : super.named();
}
''');
  }
}
