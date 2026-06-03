// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingSizeAnnotationArray);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingSizeAnnotationArray extends PubPackageResolutionTest {
  test_one() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Struct {
  @Array(8)
  external Array<Uint8> a0;
}
''');
  }

  test_two() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Struct {
  external Array<Uint8> a0;
//         ^^^^^^^^^^^^
// [diag.missingSizeAnnotationCarray] Fields of type 'Array' must have exactly one 'Array' annotation.
}
''');
  }
}
