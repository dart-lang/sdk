// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionTypeCannotBeBoundTest);
    defineReflectiveTests(
      GenericFunctionTypeCannotBeBoundWithoutGenericMetadataTest,
    );
  });
}

@reflectiveTest
class GenericFunctionTypeCannotBeBoundTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends S Function<S>(S)> {
}
''');
  }

  test_genericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
late T Function<T extends S Function<S>(S)>(T) fun;
''');
  }

  test_genericFunction_optOutOfGenericMetadata() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef F = S Function<S>(S);
''');
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
import 'a.dart';
late T Function<T extends F>(T) fun;
//                        ^
// [diag.genericFunctionTypeCannotBeBound] Generic function types can't be used as type parameter bounds.
''');
  }

  test_genericFunctionTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef foo = T Function<T extends S Function<S>(S)>(T t);
''');
  }

  test_parameterOfFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends void Function(S Function<S>(S))> {}
''');
  }

  test_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T foo<T extends S Function<S>(S)>(T t);
''');
  }
}

@reflectiveTest
class GenericFunctionTypeCannotBeBoundWithoutGenericMetadataTest
    extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
class C<T extends S Function<S>(S)> {
//                ^^^^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeBound] Generic function types can't be used as type parameter bounds.
}
''');
  }

  test_genericFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
late T Function<T extends S Function<S>(S)>(T) fun;
//                        ^^^^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeBound] Generic function types can't be used as type parameter bounds.
''');
  }

  test_genericFunctionTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
typedef foo = T Function<T extends S Function<S>(S)>(T t);
//                                 ^^^^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeBound] Generic function types can't be used as type parameter bounds.
''');
  }

  test_parameterOfFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends void Function(S Function<S>(S))> {}
''');
  }

  test_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.12
typedef T foo<T extends S Function<S>(S)>(T t);
//                      ^^^^^^^^^^^^^^^^
// [diag.genericFunctionTypeCannotBeBound] Generic function types can't be used as type parameter bounds.
''');
  }
}
