// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorAlreadyCompleteTest);
  });
}

@reflectiveTest
class ConstructorAlreadyCompleteTest extends PubPackageResolutionTest {
  test_secondary_factory_completedBy_body() async {
    await assertErrorsInCode(
      r'''
class A {
  A._();
  factory A() => A._();
  augment factory A() => A._();
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          45,
          7,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  test_secondary_factory_completedBy_redirection() async {
    await assertErrorsInCode(
      r'''
class A {
  A._();
  factory A() = A._;
  augment factory A() => A._();
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          42,
          7,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_secondary_factory_introductory_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A._();
  factory A();
  augment factory A() => A._();
}
''');
  }

  test_secondary_generative_completedBy_assertInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  A() : assert(true);
  augment A() {}
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          34,
          7,
          contextMessages: [message(testFile, 12, 1)],
        ),
      ],
    );
  }

  test_secondary_generative_completedBy_augmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  A();
  augment A() {}
  augment A() {}
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          36,
          7,
          contextMessages: [message(testFile, 27, 1)],
        ),
      ],
    );
  }

  test_secondary_generative_completedBy_body() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
  augment A() {}
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          21,
          7,
          contextMessages: [message(testFile, 12, 1)],
        ),
      ],
    );
  }

  test_secondary_generative_completedBy_fieldFormalParameter() async {
    await assertErrorsInCode(
      r'''
class A {
  final int x;
  A(this.x);
  augment A() {}
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          40,
          7,
          contextMessages: [message(testFile, 27, 1)],
        ),
      ],
    );
  }

  test_secondary_generative_completedBy_fieldInitializer() async {
    await assertErrorsInCode(
      r'''
class A {
  final int x;
  A() : x = 0;
  augment A() {}
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          42,
          7,
          contextMessages: [message(testFile, 27, 1)],
        ),
      ],
    );
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_secondary_generative_completedBy_superFormalParameter() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int x);
}
class B extends A {
  B(super.x);
  augment B(int x) {}
}
''',
      [
        error(
          diag.constructorAlreadyComplete,
          60,
          7,
          contextMessages: [message(testFile, 46, 1)],
        ),
      ],
    );
  }

  test_secondary_generative_introductory_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
  augment A() {}
}
''');
  }
}
