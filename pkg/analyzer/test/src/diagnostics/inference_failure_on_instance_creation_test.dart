// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnInstanceCreationTest);
  });
}

@reflectiveTest
class InferenceFailureOnInstanceCreationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
    );
  }

  test_constructorNames_named() async {
    await assertErrorsInCode('''
import 'dart:collection';
void f() {
  HashMap.from({1: 1, 2: 2, 3: 3});
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 39, 12),
    ]);
    expect(result.errors[0].message, contains("'HashMap.from'"));
  }

  test_constructorNames_unnamed() async {
    await assertErrorsInCode('''
import 'dart:collection';
void f() {
  HashMap();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 39, 7),
    ]);
    expect(result.errors[0].message, contains("'HashMap'"));
  }

  test_explicitTypeArgument() async {
    await assertNoErrorsInCode(r'''
import 'dart:collection';
void f() {
  HashMap<int, int>();
}
''');
  }

  test_missingTypeArgument_downwardInference() async {
    await assertNoErrorsInCode(r'''
import 'dart:collection';
HashMap<int, int> f() {
  return HashMap();
}
''');
  }

  test_missingTypeArgument_noInference() async {
    await assertErrorsInCode(r'''
import 'dart:collection';
void f() {
  HashMap();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 39, 7),
    ]);
  }

  test_missingTypeArgument_noInference_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
void f() {
  C();
}
''');
  }

  test_missingTypeArgument_upwardInference() async {
    await assertNoErrorsInCode(r'''
import 'dart:collection';
void f() {
  HashMap.of({1: 1, 2: 2, 3: 3});
}
''');
  }
}
