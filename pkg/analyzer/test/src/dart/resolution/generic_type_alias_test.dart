// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericTypeAliasResolutionTest);
    defineReflectiveTests(
      GenericTypeAliasResolutionTest_WithoutGenericMetadata,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class GenericTypeAliasResolutionTest extends PubPackageResolutionTest
    with GenericTypeAliasResolutionTestCases {
  test_genericFunctionTypeCannotBeTypeArgument_def_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}

typedef G = Function<S>();

C<G>? x;
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}

C<Function<S>()>? x;
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_function() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T) {}

main() {
  f<Function<S>()>(null);
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
late T Function<T>(T?) f;

main() {
  f<Function<S>()>(null);
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void f<T>(T) {}
}

main() {
  new C().f<Function<S>()>(null);
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T F<T>(T t);

F<Function<S>()>? x;
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_optOutOfGenericMetadata() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef G = Function<S>();
''');
    await resolveTestCodeWithDiagnostics('''
// @dart=2.12
import 'a.dart';
class C<T> {}
C<G>? x;
//^
// [diag.genericFunctionTypeCannotBeTypeArgument] A generic function type can't be a type argument.
''');
  }
}

@reflectiveTest
class GenericTypeAliasResolutionTest_WithoutGenericMetadata
    extends PubPackageResolutionTest
    with GenericTypeAliasResolutionTestCases {
  test_genericFunctionTypeCannotBeTypeArgument_def_class() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C<T> {}

typedef G = Function<S>();

C<G>? x;
//^
// [diag.genericFunctionTypeCannotBeTypeArgument] A generic function type can't be a type argument.
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_class() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C<T> {}

C<Function<S>()>? x;
//^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeTypeArgument] A generic function type can't be a type argument.
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_function() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
void f<T>(T) {}

main() {
  f<Function<S>()>(null);
//  ^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeTypeArgument] A generic function type can't be a type argument.
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
late T Function<T>(T?) f;

main() {
  f<Function<S>()>(null);
//  ^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeTypeArgument] A generic function type can't be a type argument.
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_method() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C {
  void f<T>(T) {}
}

main() {
  new C().f<Function<S>()>(null);
//          ^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeTypeArgument] A generic function type can't be a type argument.
}
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
typedef T F<T>(T t);

F<Function<S>()>? x;
//^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeTypeArgument] A generic function type can't be a type argument.
''');
  }
}

mixin GenericTypeAliasResolutionTestCases on PubPackageResolutionTest {
  test_genericFunctionTypeCannotBeTypeArgument_OK_def_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}

typedef G = Function();

C<G> x = C();
''');
  }

  test_genericFunctionTypeCannotBeTypeArgument_OK_literal_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {}

C<Function()> x = C();
''');
  }

  test_missingGenericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = ;
//             ^
// [diag.expectedTypeName] Expected a type name.

void f() {
  F.a;
//  ^
// [diag.undefinedGetter] The getter 'a' isn't defined for the type 'Type'.
}
''');
  }

  test_missingGenericFunction_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef F<T> = ;
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.F.a;
//    ^
// [diag.undefinedGetter] The getter 'a' isn't defined for the type 'Type'.
}
''');
  }

  test_type_element() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
G<int>? g;

typedef G<T> = T Function(double);
''');

    var node = result.findNode.namedType('G<int>');
    assertResolvedNodeText(node, r'''
NamedType
  name: G
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  question: ?
  element: <testLibrary>::@typeAlias::G
  type: int Function(double)?
    alias: <testLibrary>::@typeAlias::G
      typeArguments
        int
      nullabilitySuffix: NullabilitySuffix.question
''');
  }

  test_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

class B {}

typedef F<T extends A> = B Function<U extends B>(T a, U b);
''');
    var f = result.findElement.typeAlias('F');
    expect(f.typeParameters, hasLength(1));

    var t = f.typeParameters[0];
    expect(t.name, 'T');
    assertType(t.bound, 'A');

    var ff = f.aliasedType as FunctionType;
    expect(ff.typeParameters, hasLength(1));

    var u = ff.typeParameters[0];
    expect(u.name, 'U');
    assertType(u.bound, 'B');
  }
}
