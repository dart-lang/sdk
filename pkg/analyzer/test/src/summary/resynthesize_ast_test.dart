// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_text.dart';
import 'resynthesize_common.dart';
import 'test_strategies.dart';

main() {
  if (AnalysisDriver.useSummary2) return;
  defineReflectiveSuite(() {
    defineReflectiveTests(ApplyCheckElementTextReplacements);
    defineReflectiveTests(ResynthesizeAstStrongTest);
  });
}

@reflectiveTest
class ApplyCheckElementTextReplacements {
  test_applyReplacements() {
    applyCheckElementTextReplacements();
  }
}

@reflectiveTest
class ResynthesizeAstStrongTest extends ResynthesizeTestStrategyTwoPhase
    with ResynthesizeTestCases, GetElementTestCases, ResynthesizeTestHelpers {
  @failingTest // See dartbug.com/32290
  test_const_constructor_inferred_args() =>
      super.test_const_constructor_inferred_args();

  @failingTest // See dartbug.com/33441
  test_const_list_inferredType() => super.test_const_list_inferredType();

  @failingTest // See dartbug.com/33441
  test_const_map_inferredType() => super.test_const_map_inferredType();

  @FailingTest(
      reason: "NoSuchMethodError: Class 'ExtensionElementForLink' has no "
          "instance method 'getGetter' with matching arguments.")
  test_const_reference_staticMethod_ofExtension() async {
    await super.test_const_reference_staticMethod_ofExtension();
  }

  @failingTest // See dartbug.com/33441
  test_const_set_inferredType() => super.test_const_set_inferredType();

  @override
  @failingTest
  test_defaultValue_refersToExtension_method_inside() async {
    await super.test_defaultValue_refersToExtension_method_inside();
  }

  @override
  @failingTest
  test_defaultValue_refersToGenericClass() async {
    await super.test_defaultValue_refersToGenericClass();
  }

  @FailingTest(
    reason: 'Inference for extension fields is not implemented in summary1.',
  )
  test_duplicateDeclaration_extension() async {
    await super.test_duplicateDeclaration_extension();
  }

  @FailingTest(
    reason: 'Inference for extension fields is not implemented in summary1.',
  )
  test_extension_field_inferredType_const() async {
    await super.test_extension_field_inferredType_const();
  }

  @override
  @failingTest
  test_infer_generic_typedef_complex() async {
    await super.test_infer_generic_typedef_complex();
  }

  @override
  @failingTest
  test_syntheticFunctionType_inGenericClass() async {
    await super.test_syntheticFunctionType_inGenericClass();
  }
}
