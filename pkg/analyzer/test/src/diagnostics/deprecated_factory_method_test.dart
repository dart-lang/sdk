// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedFactoryMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedFactoryMethodTest extends PubPackageResolutionTest {
  test_noTypeOrModifier_after() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  factory() => throw 0;
}
''');
  }

  test_noTypeOrModifier_before() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  factory() => throw 0;
//^^^^^^^
// [diag.deprecatedFactoryMethod] Methods named 'factory' will become constructors when the primary_constructors feature is enabled.
}
''');
  }

  test_withAnnotation_after() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  @deprecated
  factory() => throw 0;
}
''');
  }

  test_withAnnotation_before() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  @deprecated
  factory() => throw 0;
//^^^^^^^
// [diag.deprecatedFactoryMethod] Methods named 'factory' will become constructors when the primary_constructors feature is enabled.
}
''');
  }

  test_withModifier_augment_after() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  augment factory() => throw 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_withModifier_augment_before() async {
    // TODO(brianwilkerson): The diagnostic produced here is expected to
    //  change to `deprecatedFactoryMethod` when `augmentations` is enabled
    //  for tests.
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  augment factory() => throw 0;
//^^^^^^^
// [diag.undefinedClass] Undefined class 'augment'.
}
''');
  }

  test_withModifier_augmentAndExternal_after() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  augment external factory();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
}
''');
  }

  test_withModifier_augmentAndExternal_before() async {
    // TODO(brianwilkerson): The `deprecatedFactoryMethod` diagnostic is
    //  expected to be the only diagnostic when `augmentations` is enabled for
    //  tests.
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  augment external factory();
//^^^^^^^
// [diag.undefinedClass] Undefined class 'augment'.
//        ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^^^^^^^^
// [diag.concreteClassWithAbstractMember] 'factory' must have a method body because 'C' isn't abstract.
//                 ^^^^^^^
// [diag.deprecatedFactoryMethod] Methods named 'factory' will become constructors when the primary_constructors feature is enabled.
}
''');
  }

  test_withModifier_external_after() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  external factory();
}
''');
  }

  test_withModifier_external_before() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  external factory();
//         ^^^^^^^
// [diag.deprecatedFactoryMethod] Methods named 'factory' will become constructors when the primary_constructors feature is enabled.
}
''');
  }

  test_withModifier_static_after() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static factory() {}
}
''');
  }

  test_withModifier_static_before() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  static factory() {}
}
''');
  }

  test_withType_after() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int factory() => 0;
}
''');
  }

  test_withType_before() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  int factory() => 0;
}
''');
  }
}
