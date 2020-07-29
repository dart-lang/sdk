// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeNameResolutionTest);
    defineReflectiveTests(TypeNameResolutionWithNullSafetyTest);
  });
}

@reflectiveTest
class TypeNameResolutionTest extends DriverResolutionTest {
  @override
  bool get typeToStringWithNullability => true;

  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}

f(A a) {}
''');

    assertTypeName(
      findNode.typeName('A a'),
      findElement.class_('A'),
      typeStr('A', 'A*'),
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
      typeStr('A<num>', 'A<num*>*'),
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
      typeStr('A<dynamic>', 'A<dynamic>*'),
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
      typeStr('A<int>', 'A<int*>*'),
    );
  }

  test_dynamic_explicitCore() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';

dynamic a;
''');

    assertTypeName(
      findNode.typeName('dynamic a;'),
      dynamicElement,
      'dynamic',
    );
  }

  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as mycore;

mycore.dynamic a;
''');

    assertTypeName(
      findNode.typeName('mycore.dynamic a;'),
      dynamicElement,
      'dynamic',
      expectedPrefix: findElement.import('dart:core').prefix,
    );
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    await assertErrorsInCode(r'''
import 'dart:core' as mycore;

dynamic a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 31, 7),
    ]);

    assertTypeName(
      findNode.typeName('dynamic a;'),
      null,
      'dynamic',
    );
  }

  test_dynamic_implicitCore() async {
    await assertNoErrorsInCode(r'''
dynamic a;
''');

    assertTypeName(
      findNode.typeName('dynamic a;'),
      dynamicElement,
      'dynamic',
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
      typeStr('int Function()', 'int* Function()*'),
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
      typeStr('num Function()', 'num* Function()*'),
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
      typeStr('dynamic Function()', 'dynamic Function()*'),
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
      typeStr('int Function()', 'int* Function()*'),
    );
  }

  test_instanceCreation_explicitNew_prefix_unresolvedClass() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  new math.A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 49, 1),
    ]);

    assertTypeName(
      findNode.typeName('A();'),
      null,
      'dynamic',
      expectedPrefix: findElement.prefix('math'),
    );
  }

  test_instanceCreation_explicitNew_resolvedClass() async {
    await assertNoErrorsInCode(r'''
class A {}

main() {
  new A();
}
''');

    assertTypeName(
      findNode.typeName('A();'),
      findElement.class_('A'),
      typeStr('A', 'A*'),
    );
  }

  test_instanceCreation_explicitNew_unresolvedClass() async {
    await assertErrorsInCode(r'''
main() {
  new A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 15, 1),
    ]);

    assertTypeName(
      findNode.typeName('A();'),
      null,
      'dynamic',
    );
  }

  test_invalid_prefixedIdentifier_instanceCreation() async {
    await assertErrorsInCode(r'''
void f() {
  new int.double.other();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 10),
    ]);

    assertTypeName(
      findNode.typeName('int.double'),
      null,
      'dynamic',
      expectedPrefix: intElement,
    );
  }

  test_invalid_prefixedIdentifier_literal() async {
    await assertErrorsInCode(r'''
void f() {
  0 as int.double;
}
''', [
      error(CompileTimeErrorCode.NOT_A_TYPE, 18, 10),
    ]);

    assertTypeName(
      findNode.typeName('int.double'),
      null,
      'dynamic',
      expectedPrefix: intElement,
    );
  }

  test_never() async {
    await assertNoErrorsInCode(r'''
f(Never a) {}
''');

    assertTypeName(
      findNode.typeName('Never a'),
      neverElement,
      typeStr('Never', 'Null*'),
    );
  }
}

@reflectiveTest
class TypeNameResolutionWithNullSafetyTest extends TypeNameResolutionTest
    with WithNullSafetyMixin {
  ImportFindElement get import_a {
    return findElement.importFind('package:test/a.dart');
  }

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
