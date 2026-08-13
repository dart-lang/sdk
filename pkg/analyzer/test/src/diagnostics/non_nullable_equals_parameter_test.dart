// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullableEqualsParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonNullableEqualsParameterTest extends PubPackageResolutionTest {
  test_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  @override
  bool operator ==(dynamic other) => false;
//              ^^
// [diag.nonNullableEqualsParameter] The parameter type of '==' operators should be non-nullable.
}
''');
  }

  test_inheritedDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  @override
  bool operator ==(dynamic other) => false;
//              ^^
// [diag.nonNullableEqualsParameter] The parameter type of '==' operators should be non-nullable.
}
class D extends C {
  @override
  bool operator ==(other) => false;
//              ^^
// [diag.nonNullableEqualsParameter] The parameter type of '==' operators should be non-nullable.
}
''');
  }

  test_inheritedFromObject() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  @override
  bool operator ==(other) => false;
}
''');
  }

  test_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  @override
  bool operator ==(covariant int other) => false;
}
''');
  }

  test_nullableObject() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  @override
  bool operator ==(Object? other) => false;
//              ^^
// [diag.nonNullableEqualsParameter] The parameter type of '==' operators should be non-nullable.
}
''');
  }

  test_object() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  @override
  bool operator ==(Object other) => false;
}
''');
  }
}
