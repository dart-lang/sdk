// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericTypeAliasDriverResolutionTest);
  });
}

@reflectiveTest
class GenericTypeAliasDriverResolutionTest extends DriverResolutionTest
    with GenericTypeAliasResolutionMixin {}

mixin GenericTypeAliasResolutionMixin implements ResolutionTest {
  test_genericFunctionTypeCannotBeTypeArgument_def_class() async {
    addTestFile(r'''
class C<T> {}

typedef G = Function<S>();

C<G> x;
''');
    await resolveTestFile();
    assertTestErrors(
      [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT],
    );
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_class() async {
    addTestFile(r'''
class C<T> {}

C<Function<S>()> x;
''');
    await resolveTestFile();
    assertTestErrors(
      [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT],
    );
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_function() async {
    addTestFile(r'''
T f<T>(T) => null;

main() {
  f<Function<S>()>(null);
}
''');
    await resolveTestFile();
    assertTestErrors(
      [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT],
    );
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_functionType() async {
    addTestFile(r'''
T Function<T>(T) f;

main() {
  f<Function<S>()>(null);
}
''');
    await resolveTestFile();
    assertTestErrors(
      [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT],
    );
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_method() async {
    addTestFile(r'''
class C {
  T f<T>(T) => null;
}

main() {
  new C().f<Function<S>()>(null);
}
''');
    await resolveTestFile();
    assertTestErrors(
      [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT],
    );
  }

  test_genericFunctionTypeCannotBeTypeArgument_literal_typedef() async {
    addTestFile(r'''
typedef T F<T>(T t);

F<Function<S>()> x;
''');
    await resolveTestFile();
    assertTestErrors(
      [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT],
    );
  }

  test_genericFunctionTypeCannotBeTypeArgument_OK_def_class() async {
    addTestFile(r'''
class C<T> {}

typedef G = Function();

C<G> x;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_genericFunctionTypeCannotBeTypeArgument_OK_literal_class() async {
    addTestFile(r'''
class C<T> {}

C<Function()> x;
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_typeParameters() async {
    addTestFile(r'''
class A {}

class B {}

typedef F<T extends A> = B<T> Function<U extends B>(T a, U b);
''');
    await resolveTestFile();

    var f = findElement.genericTypeAlias('F');
    expect(f.typeParameters, hasLength(1));

    var t = f.typeParameters[0];
    expect(t.name, 'T');
    assertElementTypeString(t.bound, 'A');

    var ff = f.function;
    expect(ff.typeParameters, hasLength(1));

    var u = ff.typeParameters[0];
    expect(u.name, 'U');
    assertElementTypeString(u.bound, 'B');
  }
}
