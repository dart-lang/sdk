// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoGenerativeConstructorsInSuperclassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NoGenerativeConstructorsInSuperclassTest
    extends PubPackageResolutionTest {
  test_explicit() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw '';
}
class B extends A {
//              ^
// [diag.noGenerativeConstructorsInSuperclass] The class 'B' can't extend 'A' because 'A' only has factory constructors (no generative constructors), and 'B' has at least one generative constructor.
  B() : super();
}
''');
  }

  test_explicit_oneFactory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw '';
}
class B extends A {
//              ^
// [diag.noGenerativeConstructorsInSuperclass] The class 'B' can't extend 'A' because 'A' only has factory constructors (no generative constructors), and 'B' has at least one generative constructor.
  B() : super();
  factory B.second() => throw '';
}
''');
  }

  test_hasFactories() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw '';
}
class B extends A {
  factory B() => throw '';
  factory B.second() => throw '';
}
''');
  }

  test_hasFactory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw '';
}
class B extends A {
  factory B() => throw '';
}
''');
  }

  test_implicit() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw '';
}
class B extends A {
//              ^
// [diag.noGenerativeConstructorsInSuperclass] The class 'B' can't extend 'A' because 'A' only has factory constructors (no generative constructors), and 'B' has at least one generative constructor.
  B();
}
''');
  }

  test_implicit2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() => throw '';
}
class B extends A {
//              ^
// [diag.noGenerativeConstructorsInSuperclass] The class 'B' can't extend 'A' because 'A' only has factory constructors (no generative constructors), and 'B' has at least one generative constructor.
}
''');
  }
}
