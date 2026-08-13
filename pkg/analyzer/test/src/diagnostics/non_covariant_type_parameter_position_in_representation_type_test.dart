// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      NonCovariantTypeParameterPositionInRepresentationTypeTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonCovariantTypeParameterPositionInRepresentationTypeTest
    extends PubPackageResolutionTest {
  test_contravariant() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(void Function(T) it) {}
//               ^
// [diag.nonCovariantTypeParameterPositionInRepresentationType] An extension type parameter can't be used in a non-covariant position of its representation type.
''');
  }

  test_covariant() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(T Function() it) {}
''');
  }

  test_invariant() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(T Function(T) it) {}
//               ^
// [diag.nonCovariantTypeParameterPositionInRepresentationType] An extension type parameter can't be used in a non-covariant position of its representation type.
''');
  }
}
