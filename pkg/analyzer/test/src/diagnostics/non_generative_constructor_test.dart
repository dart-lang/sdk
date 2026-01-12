// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonGenerativeConstructorTest);
  });
}

@reflectiveTest
class NonGenerativeConstructorTest extends PubPackageResolutionTest {
  test_factory_explicit_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A.named() => throw 0;
  A.generative();
}
class B extends A {
  B() : super.named();
}
''',
      [error(diag.nonGenerativeConstructor, 90, 13)],
    );
  }

  test_factory_explicit_primaryConstructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A.named() => throw 0;
  A.generative();
}
class B() extends A {
  this : super.named();
}
''',
      [error(diag.nonGenerativeConstructor, 93, 13)],
    );
  }

  test_factory_implicit_constructor_newHead() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() => throw 0;
  A.named();
}
class B extends A {
  new foo();
}
''',
      [error(diag.nonGenerativeConstructor, 73, 7)],
    );
  }

  test_factory_implicit_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() => throw 0;
  A.named();
}
class B extends A {
  B.foo();
}
''',
      [error(diag.nonGenerativeConstructor, 73, 5)],
    );
  }

  test_factory_implicit_constructor_typeName_external() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(
      r'''
class A {
  factory A() => throw 0;
  A.named();
}
class B() extends A {
  this;
}
''',
      [error(diag.nonGenerativeConstructor, 75, 4)],
    );
  }

  test_generative_constructor() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
