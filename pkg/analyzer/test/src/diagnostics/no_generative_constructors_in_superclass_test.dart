// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoGenerativeConstructorsInSuperclassTest);
  });
}

@reflectiveTest
class NoGenerativeConstructorsInSuperclassTest
    extends PubPackageResolutionTest {
  test_explicit() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() => throw '';
}
class B extends A {
  B() : super();
}
''',
      [error(diag.noGenerativeConstructorsInSuperclass, 55, 1)],
    );
  }

  test_explicit_oneFactory() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() => throw '';
}
class B extends A {
  B() : super();
  factory B.second() => throw '';
}
''',
      [error(diag.noGenerativeConstructorsInSuperclass, 55, 1)],
    );
  }

  test_hasFactories() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
class A {
  factory A() => throw '';
}
class B extends A {
  factory B() => throw '';
}
''');
  }

  test_implicit() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() => throw '';
}
class B extends A {
  B();
}
''',
      [error(diag.noGenerativeConstructorsInSuperclass, 55, 1)],
    );
  }

  test_implicit2() async {
    await assertErrorsInCode(
      r'''
class A {
  factory A() => throw '';
}
class B extends A {
}
''',
      [error(diag.noGenerativeConstructorsInSuperclass, 55, 1)],
    );
  }
}
