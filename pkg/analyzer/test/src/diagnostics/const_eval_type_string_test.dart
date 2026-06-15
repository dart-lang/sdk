// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeStringTest);
  });
}

@reflectiveTest
class ConstEvalTypeStringTest extends PubPackageResolutionTest {
  test_length_unresolvedType() async {
    await resolveTestCodeWithDiagnostics(r'''
class B {
  final l;
  const B(String o) : l = o.length;
//                        ^^^^^^^^
// [context 1] The error is in the field initializer of 'B', and occurs here.
}

const y = B(x);
//        ^^^^
// [diag.constEvalTypeString][context 1] In constant expressions, operands of this operator must be of type 'String'.
//          ^
// [diag.undefinedIdentifier] Undefined name 'x'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
''');
  }
}
