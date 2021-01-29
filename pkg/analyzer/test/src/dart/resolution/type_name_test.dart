// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeNameResolutionTest);
    defineReflectiveTests(TypeNameResolutionWithNullSafetyTest);
    defineReflectiveTests(TypeNameResolutionWithNonFunctionTypeAliasesTest);
  });
}

@reflectiveTest
class TypeNameResolutionTest extends PubPackageResolutionTest {
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
      findElement.typeAlias('F'),
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
      findElement.typeAlias('F'),
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
      findElement.typeAlias('F'),
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
      findElement.typeAlias('F'),
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
class TypeNameResolutionWithNonFunctionTypeAliasesTest
    extends PubPackageResolutionTest with WithNonFunctionTypeAliasesMixin {
  test_typeAlias_asInstanceCreation_explicitNew_typeArguments_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  new X<int>();
}
''');

    assertTypeName(
      findNode.typeName('X<int>()'),
      findElement.typeAlias('X'),
      'A<int>',
    );
  }

  @FailingTest(reason: 'We attempt to do type inference on A')
  test_typeAlias_asInstanceCreation_implicitNew_toBounds_noTypeParameters_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X = A<int>;

void f() {
  X();
}
''');

    assertTypeName(
      findNode.typeName('X()'),
      findElement.typeAlias('X'),
      'A<int>',
    );
  }

  test_typeAlias_asInstanceCreation_implicitNew_typeArguments_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  X<int>();
}
''');

    assertTypeName(
      findNode.typeName('X<int>()'),
      findElement.typeAlias('X'),
      'A<int>',
    );
  }

  test_typeAlias_asParameterType_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
void f(X<String> a, X<String?> b) {}
''');

    assertTypeName(
      findNode.typeName('X<String>'),
      findElement.typeAlias('X'),
      'Map<int, String>',
    );

    assertTypeName(
      findNode.typeName('X<String?>'),
      findElement.typeAlias('X'),
      'Map<int, String?>',
    );
  }

  test_typeAlias_asParameterType_interfaceType_none_inLegacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef X<T> = Map<int, T>;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X<String> a) {}
''');

    assertTypeName(
      findNode.typeName('X<String>'),
      findElement.importFind('package:test/a.dart').typeAlias('X'),
      'Map<int*, String*>*',
    );
  }

  test_typeAlias_asParameterType_interfaceType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = List<T?>;
void f(X<int> a, X<int?> b) {}
''');

    assertTypeName(
      findNode.typeName('X<int>'),
      findElement.typeAlias('X'),
      'List<int?>',
    );

    assertTypeName(
      findNode.typeName('X<int?>'),
      findElement.typeAlias('X'),
      'List<int?>',
    );
  }

  test_typeAlias_asParameterType_interfaceType_question_inLegacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef X<T> = List<T?>;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X<int> a) {}
''');

    assertTypeName(
      findNode.typeName('X<int>'),
      findElement.importFind('package:test/a.dart').typeAlias('X'),
      'List<int*>*',
    );
  }

  test_typeAlias_asParameterType_Never_none() async {
    await assertNoErrorsInCode(r'''
typedef X = Never;
void f(X a, X? b) {}
''');

    assertTypeName(
      findNode.typeName('X a'),
      findElement.typeAlias('X'),
      'Never',
    );

    assertTypeName(
      findNode.typeName('X? b'),
      findElement.typeAlias('X'),
      'Never?',
    );
  }

  test_typeAlias_asParameterType_Never_none_inLegacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef X = Never;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X a) {}
''');

    assertTypeName(
      findNode.typeName('X a'),
      findElement.importFind('package:test/a.dart').typeAlias('X'),
      'Null*',
    );
  }

  test_typeAlias_asParameterType_Never_question() async {
    await assertNoErrorsInCode(r'''
typedef X = Never?;
void f(X a, X? b) {}
''');

    assertTypeName(
      findNode.typeName('X a'),
      findElement.typeAlias('X'),
      'Never?',
    );

    assertTypeName(
      findNode.typeName('X? b'),
      findElement.typeAlias('X'),
      'Never?',
    );
  }

  test_typeAlias_asParameterType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = T?;
void f(X<int> a) {}
''');

    assertTypeName(
      findNode.typeName('X<int>'),
      findElement.typeAlias('X'),
      'int?',
    );
  }

  test_typeAlias_asReturnType_interfaceType() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
X<String> f() => {};
''');

    assertTypeName(
      findNode.typeName('X<String>'),
      findElement.typeAlias('X'),
      'Map<int, String>',
    );
  }

  test_typeAlias_asReturnType_void() async {
    await assertNoErrorsInCode(r'''
typedef Nothing = void;
Nothing f() {}
''');

    assertTypeName(
      findNode.typeName('Nothing f()'),
      findElement.typeAlias('Nothing'),
      'void',
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
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
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F = int Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.typeName('F a');
    assertTypeName(typeName, element, 'int* Function(bool*)*');

    assertFunctionTypeTypedef(
      typeName.type,
      element: element,
      typeArguments: [],
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_dynamic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.typeName('F a');
    assertTypeName(typeName, element, 'dynamic Function(bool*)*');

    assertFunctionTypeTypedef(
      typeName.type,
      element: element,
      typeArguments: ['dynamic'],
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_toBounds() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T extends num> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.typeName('F a');
    assertTypeName(typeName, element, 'num* Function(bool*)*');

    assertFunctionTypeTypedef(
      typeName.type,
      element: element,
      typeArguments: ['num*'],
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F<int> a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.typeName('F<int> a');
    assertTypeName(typeName, element, 'int* Function(bool*)*');

    assertFunctionTypeTypedef(
      typeName.type,
      element: element,
      typeArguments: ['int*'],
    );
  }

  test_optOut_fromOptIn_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A',
    );
  }

  test_optOut_fromOptIn_class_generic_toBounds() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A<T extends num> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A<num*>',
    );
  }

  test_optOut_fromOptIn_class_generic_toBounds_dynamic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A<T> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('A a'),
      import_a.class_('A'),
      'A<dynamic>',
    );
  }

  test_optOut_fromOptIn_class_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A<T> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A<int> a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('A<int> a'),
      import_a.class_('A'),
      'A<int>',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F = int Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('F a'),
      import_a.typeAlias('F'),
      'int* Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F<T extends num> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('F a'),
      import_a.typeAlias('F'),
      'num* Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds_dynamic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('F a'),
      import_a.typeAlias('F'),
      'dynamic Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F<int> a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertTypeName(
      findNode.typeName('F<int> a'),
      import_a.typeAlias('F'),
      'int* Function()',
    );
  }
}
