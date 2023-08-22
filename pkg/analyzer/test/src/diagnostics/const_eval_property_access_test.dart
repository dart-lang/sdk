// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalPropertyAccessTest);
  });
}

@reflectiveTest
class ConstEvalPropertyAccessTest extends PubPackageResolutionTest {
  test_length_invalidTarget() async {
    await assertErrorsInCode('''
void main() {
  const RequiresNonEmptyList([1]);
}

class RequiresNonEmptyList {
  const RequiresNonEmptyList(List<int> numbers) : assert(numbers.length > 0);
}
''', [
      error(
        CompileTimeErrorCode.CONST_EVAL_PROPERTY_ACCESS,
        16,
        31,
        contextMessages: [
          ExpectedContextMessage(testFile.path, 138, 14,
              text:
                  "The error is in the assert initializer of 'RequiresNonEmptyList', and occurs here."),
        ],
      ),
    ]);
  }
}
