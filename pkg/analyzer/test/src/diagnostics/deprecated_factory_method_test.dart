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

  test_noTypeOrModifier_beforePrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
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

  test_withAnnotation_beforePrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
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

  test_withModifier_augment_beforePrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
class C {
  augment factory() => throw 0;
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
//        ^^^^^^^
// [diag.deprecatedFactoryMethod] Methods named 'factory' will become constructors when the primary_constructors feature is enabled.
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

  test_withModifier_augmentAndExternal_beforePrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
class C {
  augment external factory();
//^^^^^^^
// [diag.augmentationWithoutDeclaration] The declaration being augmented doesn't exist.
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

  test_withModifier_external_beforePrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
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

  test_withModifier_static_beforePrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
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

  test_withType_beforePrimaryConstructors() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
class C {
  int factory() => 0;
}
''');
  }
}
