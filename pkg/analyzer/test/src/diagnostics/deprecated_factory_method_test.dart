// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedFactoryMethodTest);
  });
}

@reflectiveTest
class DeprecatedFactoryMethodTest extends PubPackageResolutionTest {
  test_noTypeOrModifier_after() async {
    await assertNoErrorsInCode('''
class C {
  factory() => throw 0;
}
''');
  }

  test_noTypeOrModifier_before() async {
    await assertErrorsInCode(
      '''
// @dart=2.12
class C {
  factory() => throw 0;
}
''',
      [error(diag.deprecatedFactoryMethod, 26, 7)],
    );
  }

  test_withAnnotation_after() async {
    await assertNoErrorsInCode('''
class C {
  @deprecated
  factory() => throw 0;
}
''');
  }

  test_withAnnotation_before() async {
    await assertErrorsInCode(
      '''
// @dart=2.12
class C {
  @deprecated
  factory() => throw 0;
}
''',
      [error(diag.deprecatedFactoryMethod, 40, 7)],
    );
  }

  test_withModifier_augment_after() async {
    await assertNoErrorsInCode('''
class C {
  augment factory() => throw 0;
}
''');
  }

  test_withModifier_augment_before() async {
    await assertErrorsInCode(
      '''
// @dart=2.12
class C {
  augment factory() => throw 0;
}
''',
      // TODO(brianwilkerson): The diagnostic produced here is expected to
      //  change to `deprecatedFactoryMethod` when `augmentations` is enabled
      //  for tests.
      [error(diag.undefinedClass, 26, 7)],
    );
  }

  test_withModifier_augmentAndExternal_after() async {
    await assertErrorsInCode(
      '''
class C {
  augment external factory();
}
''',
      // TODO(brianwilkerson): The `conflictingModifiers` diagnostic should not
      //  be produced here.
      [error(diag.conflictingModifiers, 20, 8)],
    );
  }

  test_withModifier_augmentAndExternal_before() async {
    await assertErrorsInCode(
      '''
// @dart=2.12
class C {
  augment external factory();
}
''',
      // TODO(brianwilkerson): The `deprecatedFactoryMethod` diagnostic is
      //  expected to be the only diagnostic when `augmentations` is enabled for
      //  tests.
      [
        error(diag.undefinedClass, 26, 7),
        error(diag.expectedToken, 34, 8),
        error(diag.concreteClassWithAbstractMember, 43, 10),
        error(diag.deprecatedFactoryMethod, 43, 7),
      ],
    );
  }

  test_withModifier_external_after() async {
    await assertNoErrorsInCode('''
class C {
  external factory();
}
''');
  }

  test_withModifier_external_before() async {
    await assertErrorsInCode(
      '''
// @dart=2.12
class C {
  external factory();
}
''',
      [error(diag.deprecatedFactoryMethod, 35, 7)],
    );
  }

  test_withModifier_static_after() async {
    await assertNoErrorsInCode('''
class C {
  static factory() {}
}
''');
  }

  test_withModifier_static_before() async {
    await assertNoErrorsInCode('''
// @dart=2.12
class C {
  static factory() {}
}
''');
  }

  test_withType_after() async {
    await assertNoErrorsInCode('''
class C {
  int factory() => 0;
}
''');
  }

  test_withType_before() async {
    await assertNoErrorsInCode('''
// @dart=2.12
class C {
  int factory() => 0;
}
''');
  }
}
