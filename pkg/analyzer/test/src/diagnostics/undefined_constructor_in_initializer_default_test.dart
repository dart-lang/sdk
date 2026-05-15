// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedConstructorInInitializerDefaultTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedConstructorInInitializerDefaultTest
    extends PubPackageResolutionTest {
  test_hasOptionalParameters_defined() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([p]) {}
}
class B extends A {
  B();
}
''');
  }

  test_implicit_defined_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
class B extends A {
  B();
}
''');
  }

  test_implicit_defined_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
class B() extends A {
  this;
}
''');
  }

  test_implicit_defined_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
class B() extends A;
''');
  }

  test_implicit_notDefined_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}
class B extends A {
  new foo();
//^^^^^^^
// [diag.undefinedConstructorInInitializerDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_implicit_notDefined_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}
class B extends A {
  B.foo();
//^^^^^
// [diag.undefinedConstructorInInitializerDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_implicit_notDefined_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}
class B.foo() extends A {
  this;
//^^^^
// [diag.undefinedConstructorInInitializerDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_implicit_notDefined_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}
class B.foo() extends A;
//    ^^^^^
// [diag.undefinedConstructorInInitializerDefault] The class 'A' doesn't have an unnamed constructor.
''');
  }
}
