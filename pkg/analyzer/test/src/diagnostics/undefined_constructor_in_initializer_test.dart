// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedConstructorInInitializerTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedConstructorInInitializerTest extends PubPackageResolutionTest {
  test_explicit_named_defined_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super.named();
}
''');
  }

  test_explicit_named_defined_primaryConstructorBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
}
class B() extends A {
  this : super.named();
}
''');
  }

  test_explicit_named_notDefined_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  B() : super.named();
//      ^^^^^^^^^^^^^
// [diag.undefinedConstructorInInitializer] The class 'A' doesn't have a constructor named 'named'.
}
''');
  }

  test_explicit_named_notDefined_primateConstructorBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B() extends A {
  this : super.named();
//       ^^^^^^^^^^^^^
// [diag.undefinedConstructorInInitializer] The class 'A' doesn't have a constructor named 'named'.
}
''');
  }

  test_explicit_unnamed_defined_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
class B extends A {
  B() : super();
}
''');
  }

  test_explicit_unnamed_defined_primaryConstructorBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
class B() extends A {
  this : super();
}
''');
  }

  test_explicit_unnamed_notDefined_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super();
//      ^^^^^^^
// [diag.undefinedConstructorInInitializerDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }

  test_explicit_unnamed_notDefined_primaryConstructorBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named() {}
}
class B() extends A {
  this : super();
//       ^^^^^^^
// [diag.undefinedConstructorInInitializerDefault] The class 'A' doesn't have an unnamed constructor.
}
''');
  }
}
