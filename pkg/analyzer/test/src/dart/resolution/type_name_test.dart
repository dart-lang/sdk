// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeNameResolutionTest);
    defineReflectiveTests(TypeNameResolutionWithNnbdTest);
  });
}

@reflectiveTest
class TypeNameResolutionTest extends DriverResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      findElement.class_('A'),
      'A',
    );
  }

  test_class_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {}

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      findElement.class_('A'),
      'A<num>',
    );
  }

  test_class_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      findElement.class_('A'),
      'A<dynamic>',
    );
  }

  test_class_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A<int> a) {}
''');

    assertTypeName(
      findNode.typeName('A<int> a'),
      findElement.class_('A'),
      'A<int>',
    );
  }

  test_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F = int Function();

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      findElement.functionTypeAlias('F'),
      'int Function()',
    );
  }

  test_functionTypeAlias_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
typedef F<T extends num> = T Function();

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      findElement.functionTypeAlias('F'),
      'num Function()',
    );
  }

  test_functionTypeAlias_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      findElement.functionTypeAlias('F'),
      'dynamic Function()',
    );
  }

  test_functionTypeAlias_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F<int> a) {}
''');

    assertTypeName(
      findNode.typeName('F<int> a'),
      findElement.functionTypeAlias('F'),
      'int Function()',
    );
  }
}

@reflectiveTest
class TypeNameResolutionWithNnbdTest extends TypeNameResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.7.0', additionalFeatures: [Feature.non_nullable]);

  ImportFindElement get import_a {
    return findElement.importFind('package:test/a.dart');
  }

  @override
  bool get typeToStringWithNullability => true;

  test_optIn_fromOptOut_class() async {
    newFile('/test/lib/a.dart', content: r'''
class A {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A*',
    );
  }

  test_optIn_fromOptOut_class_generic_toBounds() async {
    newFile('/test/lib/a.dart', content: r'''
class A<T extends num> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A<num*>*',
    );
  }

  test_optIn_fromOptOut_class_generic_toBounds_dynamic() async {
    newFile('/test/lib/a.dart', content: r'''
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A<dynamic>*',
    );
  }

  test_optIn_fromOptOut_class_generic_typeArguments() async {
    newFile('/test/lib/a.dart', content: r'''
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A<int> a) {}
''');

    assertTypeName(
      findNode.typeName('A<int> a'),
      import_a.class_('A'),
      'A<int*>*',
    );
  }

  test_optIn_fromOptOut_functionTypeAlias() async {
    newFile('/test/lib/a.dart', content: r'''
typedef F = int Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      import_a.functionTypeAlias('F'),
      'int* Function(bool*)*',
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_dynamic() async {
    newFile('/test/lib/a.dart', content: r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      import_a.functionTypeAlias('F'),
      'dynamic Function(bool*)*',
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_toBounds() async {
    newFile('/test/lib/a.dart', content: r'''
typedef F<T extends num> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      import_a.functionTypeAlias('F'),
      'num* Function(bool*)*',
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_typeArguments() async {
    newFile('/test/lib/a.dart', content: r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F<int> a) {}
''');

    assertTypeName(
      findNode.typeName('F<int> a'),
      import_a.functionTypeAlias('F'),
      'int* Function(bool*)*',
    );
  }

  test_optOut_fromOptIn_class() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
class A {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A',
    );
  }

  test_optOut_fromOptIn_class_generic_toBounds() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
class A<T extends num> {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A<num*>',
    );
  }

  test_optOut_fromOptIn_class_generic_toBounds_dynamic() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A<dynamic>',
    );
  }

  test_optOut_fromOptIn_class_generic_typeArguments() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(A<int> a) {}
''');

    assertTypeName(
      findNode.typeName('A<int> a'),
      import_a.class_('A'),
      'A<int>',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
typedef F = int Function();
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      import_a.functionTypeAlias('F'),
      'int* Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
typedef F<T extends num> = T Function();
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      import_a.functionTypeAlias('F'),
      'num* Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds_dynamic() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''');

    assertTypeName(
      findNode.typeName('F a'),
      import_a.functionTypeAlias('F'),
      'dynamic Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_typeArguments() async {
    newFile('/test/lib/a.dart', content: r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

f(F<int> a) {}
''');

    assertTypeName(
      findNode.typeName('F<int> a'),
      import_a.functionTypeAlias('F'),
      'int* Function()',
    );
  }
}
