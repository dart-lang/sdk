// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericTypeAliasDriverResolutionTest);
  });
}

@reflectiveTest
class GenericTypeAliasDriverResolutionTest extends PubPackageResolutionTest {
  test_genericFunctionTypeCannotBeTypeArgument_def_class() async {
    await assertErrorsInCode(r'''
class C<T> {}

typedef G = Function<S>();

C<G> x;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          45, 1),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_class() async {
    await assertErrorsInCode(r'''
class C<T> {}

C<Function<S>()> x;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          17, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_function() async {
    await assertErrorsInCode(r'''
T f<T>(T) => null;

main() {
  f<Function<S>()>(null);
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          33, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_functionType() async {
    await assertErrorsInCode(r'''
T Function<T>(T) f;

main() {
  f<Function<S>()>(null);
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          34, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_method() async {
    await assertErrorsInCode(r'''
class C {
  T f<T>(T) => null;
}

main() {
  new C().f<Function<S>()>(null);
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          55, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_typedef() async {
    await assertErrorsInCode(r'''
typedef T F<T>(T t);

F<Function<S>()> x;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT,
          24, 13),
    ]);
  }

  test_genericFunctionTypeCannotBeTypeArgument_OK_def_class() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

typedef G = Function();

C<G> x;
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_OK_literal_class() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

C<Function()> x;
''');
  }

  test_missingGenericFunction() async {
    await assertErrorsInCode(r'''
typedef F<T> = ;

void f() {
  F.a;
}
''', [
      error(ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE, 13, 1),
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 15, 1),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 15, 0),
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 33, 1),
    ]);
  }

  test_missingGenericFunction_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T> = ;
''');
    await assertErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.F.a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }

  test_type_element() async {
    await assertNoErrorsInCode(r'''
G<int> g;

typedef G<T> = T Function(double);
''');
    var type = findElement.topVar('g').type as FunctionType;
    assertType(type, 'int Function(double)');

    var typedefG = findElement.typeAlias('G');
    var functionG = typedefG.aliasedElement as GenericFunctionTypeElement;

    expect(type.element, functionG);
    expect(type.element?.enclosingElement, typedefG);

    assertElementTypeStrings(type.typeArguments, ['int']);
  }

  test_typeParameters() async {
    await assertNoErrorsInCode(r'''
class A {}

class B {}

typedef F<T extends A> = B Function<U extends B>(T a, U b);
''');
    var f = findElement.typeAlias('F');
    expect(f.typeParameters, hasLength(1));

    var t = f.typeParameters[0];
    expect(t.name, 'T');
    assertType(t.bound, 'A');

    var ff = f.aliasedElement as GenericFunctionTypeElement;
    expect(ff.typeParameters, hasLength(1));

    var u = ff.typeParameters[0];
    expect(u.name, 'U');
    assertType(u.bound, 'B');
  }
}
