// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeStringTest);
  });
}

@reflectiveTest
class ConstEvalTypeStringTest extends PubPackageResolutionTest {
  test_length_unresolvedType() async {
    await assertErrorsInCode(
      '''
class B {
  final l;
  const B(String o) : l = o.length;
}

const y = B(x);
''',
      [
        error(
          CompileTimeErrorCode.constEvalTypeString,
          70,
          4,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              47,
              8,
              text:
                  "The error is in the field initializer of 'B', and occurs here.",
            ),
          ],
        ),
        error(CompileTimeErrorCode.undefinedIdentifier, 72, 1),
        error(CompileTimeErrorCode.constWithNonConstantArgument, 72, 1),
      ],
    );
  }
}
