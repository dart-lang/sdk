// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedConstructorInInitializerDefaultTest);
  });
}

@reflectiveTest
class UndefinedConstructorInInitializerDefaultTest
    extends PubPackageResolutionTest {
  test_hasOptionalParameters_defined() async {
    await assertNoErrorsInCode(r'''
class A {
  A([p]) {}
}
class B extends A {
  B();
}
''');
  }

  test_implicit_defined_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B extends A {
  B();
}
''');
  }

  test_implicit_defined_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B() extends A {
  this;
}
''');
  }

  test_implicit_defined_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B() extends A;
''');
  }

  test_implicit_notDefined_constructor_newHead() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named();
}
class B extends A {
  new foo();
}
''',
      [error(diag.undefinedConstructorInInitializerDefault, 47, 7)],
    );
  }

  test_implicit_notDefined_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named();
}
class B extends A {
  B.foo();
}
''',
      [error(diag.undefinedConstructorInInitializerDefault, 47, 5)],
    );
  }

  test_implicit_notDefined_primaryConstructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named();
}
class B.foo() extends A {
  this;
}
''',
      [error(diag.undefinedConstructorInInitializerDefault, 53, 4)],
    );
  }

  test_implicit_notDefined_primaryConstructor_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A.named();
}
class B.foo() extends A;
''',
      [error(diag.undefinedConstructorInInitializerDefault, 31, 5)],
    );
  }
}
