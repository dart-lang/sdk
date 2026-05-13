// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionAlreadyCompleteTest);
  });
}

@reflectiveTest
class FunctionAlreadyCompleteTest extends PubPackageResolutionTest {
  test_class_instanceGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
  augment int get foo => 1;
}
''',
      [
        error(
          diag.functionAlreadyComplete,
          32,
          7,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
  }

  test_class_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
  augment void foo() {}
}
''',
      [
        error(
          diag.functionAlreadyComplete,
          28,
          7,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  test_class_instanceMethod_augmentation_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
  augment void foo();
}
''');
  }

  test_class_instanceMethod_introductory_noBody() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo();
  augment void foo() {}
}
''');
  }

  test_class_instanceSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(int _) {}
  augment set foo(int _) {}
}
''',
      [
        error(
          diag.functionAlreadyComplete,
          32,
          7,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_class_operator() async {
    await assertErrorsInCode(
      r'''
class A {
  A operator +(A _) => this;
  augment A operator +(A _) => this;
}
''',
      [
        error(
          diag.functionAlreadyComplete,
          41,
          7,
          contextMessages: [message(testFile, 23, 1)],
        ),
      ],
    );
  }

  test_class_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  static int get foo => 0;
  augment static int get foo => 1;
}
''',
      [
        error(
          diag.functionAlreadyComplete,
          39,
          7,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_class_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
  augment static void foo() {}
}
''',
      [
        error(
          diag.functionAlreadyComplete,
          35,
          7,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_class_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  static set foo(int _) {}
  augment static set foo(int _) {}
}
''',
      [
        error(
          diag.functionAlreadyComplete,
          39,
          7,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(
      r'''
void foo() {}
augment void foo() {}
''',
      [
        error(
          diag.functionAlreadyComplete,
          14,
          7,
          contextMessages: [message(testFile, 5, 3)],
        ),
      ],
    );
  }

  test_topLevelGetter() async {
    await assertErrorsInCode(
      r'''
int get foo => 0;
augment int get foo => 1;
''',
      [
        error(
          diag.functionAlreadyComplete,
          18,
          7,
          contextMessages: [message(testFile, 8, 3)],
        ),
      ],
    );
  }

  test_topLevelSetter() async {
    await assertErrorsInCode(
      r'''
set foo(int _) {}
augment set foo(int _) {}
''',
      [
        error(
          diag.functionAlreadyComplete,
          18,
          7,
          contextMessages: [message(testFile, 4, 3)],
        ),
      ],
    );
  }
}
