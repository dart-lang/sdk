// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeLiteralResolutionTest);
    defineReflectiveTests(TypeLiteralResolutionWithoutConstructorTearoffsTest);
  });
}

@reflectiveTest
class TypeLiteralResolutionTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode('''
class C<T> {}
var t = C<int>;
''');

    var typeLiteral = findNode.typeLiteral('C<int>;');
    assertTypeLiteral(typeLiteral, findElement.class_('C'), 'C<int>');
  }

  test_class_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class C<T> {}
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.C<int>;
''');

    var typeLiteral = findNode.typeLiteral('C<int>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.importFind('package:test/a.dart').class_('C'),
      'C<int>',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }

  test_class_tooFewTypeArgs() async {
    await assertErrorsInCode('''
class C<T, U> {}
var t = C<int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 26, 5),
    ]);

    var typeLiteral = findNode.typeLiteral('C<int>;');
    assertTypeLiteral(
        typeLiteral, findElement.class_('C'), 'C<dynamic, dynamic>');
  }

  test_class_tooManyTypeArgs() async {
    await assertErrorsInCode('''
class C<T> {}
var t = C<int, int>;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 23, 10),
    ]);

    var typeLiteral = findNode.typeLiteral('C<int, int>;');
    assertTypeLiteral(typeLiteral, findElement.class_('C'), 'C<dynamic>');
  }

  test_classAlias() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<int>;
''');

    var typeLiteral = findNode.typeLiteral('CA<int>;');
    assertTypeLiteral(typeLiteral, findElement.typeAlias('CA'), 'C<int>');
  }

  test_classAlias_differentTypeArgCount() async {
    await assertNoErrorsInCode('''
class C<T, U> {}
typedef CA<T> = C<T, int>;
var t = CA<String>;
''');

    var typeLiteral = findNode.typeLiteral('CA<String>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('CA'), 'C<String, int>');
  }

  test_classAlias_functionTypeArg() async {
    await assertNoErrorsInCode('''
class C<T> {}
typedef CA<T> = C<T>;
var t = CA<void Function()>;
''');

    var typeLiteral = findNode.typeLiteral('CA<void Function()>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('CA'), 'C<void Function()>');
  }

  test_classAlias_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class C<T> {}
typedef CA<T> = C<T>;
''');
    await assertNoErrorsInCode('''
import 'a.dart' as a;
var t = a.CA<int>;
''');

    var typeLiteral = findNode.typeLiteral('CA<int>;');
    assertTypeLiteral(
      typeLiteral,
      findElement.importFind('package:test/a.dart').typeAlias('CA'),
      'C<int>',
      expectedPrefix: findElement.import('package:test/a.dart').prefix,
    );
  }

  test_functionAlias() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);
var t = Fn<int>;
''');

    var typeLiteral = findNode.typeLiteral('Fn<int>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('Fn'), 'void Function(int)');
  }

  test_mixin() async {
    await assertNoErrorsInCode('''
mixin M<T> {}
var t = M<int>;
''');

    var typeLiteral = findNode.typeLiteral('M<int>;');
    assertTypeLiteral(typeLiteral, findElement.mixin('M'), 'M<int>');
  }

  test_typeVariableTypeAlias() async {
    await assertNoErrorsInCode('''
typedef T<E> = E;
var t = T<int>;
''');

    var typeLiteral = findNode.typeLiteral('T<int>;');
    assertTypeLiteral(typeLiteral, findElement.typeAlias('T'), 'int');
  }

  test_typeVariableTypeAlias_functionTypeArgument() async {
    await assertNoErrorsInCode('''
typedef T<E> = E;
var t = T<void Function()>;
''');

    var typeLiteral = findNode.typeLiteral('T<void Function()>;');
    assertTypeLiteral(
        typeLiteral, findElement.typeAlias('T'), 'void Function()');
  }
}

@reflectiveTest
class TypeLiteralResolutionWithoutConstructorTearoffsTest
    extends PubPackageResolutionTest with WithoutConstructorTearoffsMixin {
  test_class() async {
    await assertErrorsInCode('''
class C<T> {}
var t = C<int>;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 23, 5),
    ]);
  }

  test_class_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class C<T> {}
''');
    await assertErrorsInCode('''
import 'a.dart' as a;
var t = a.C<int>;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 33, 5),
    ]);
  }
}
