// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'hint_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HintCodeTest_Kernel);
  });
}

@reflectiveTest
class HintCodeTest_Kernel extends HintCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @failingTest
  @override
  test_abstractSuperMemberReference_getter() async {
    return super.test_abstractSuperMemberReference_getter();
  }

  @failingTest
  @override
  test_abstractSuperMemberReference_method_invocation() async {
    return super.test_abstractSuperMemberReference_method_invocation();
  }

  @failingTest
  @override
  test_abstractSuperMemberReference_method_reference() async {
    return super.test_abstractSuperMemberReference_method_reference();
  }

  @failingTest
  @override
  test_abstractSuperMemberReference_superHasNoSuchMethod() async {
    return super.test_abstractSuperMemberReference_superHasNoSuchMethod();
  }

  @failingTest
  @override
  test_deprecatedAnnotationUse_call() async {
    return super.test_deprecatedAnnotationUse_call();
  }

  @failingTest
  @override
  test_deprecatedFunction_class() async {
    return super.test_deprecatedFunction_class();
  }

  @failingTest
  @override
  test_deprecatedFunction_extends() async {
    return super.test_deprecatedFunction_extends();
  }

  @failingTest
  @override
  test_deprecatedFunction_extends2() async {
    return super.test_deprecatedFunction_extends2();
  }

  @failingTest
  @override
  test_deprecatedFunction_mixin() async {
    return super.test_deprecatedFunction_mixin();
  }

  @failingTest
  @override
  test_deprecatedFunction_mixin2() async {
    return super.test_deprecatedFunction_mixin2();
  }

  @failingTest
  @override
  test_duplicateShownHiddenName_hidden() {
    return super.test_duplicateShownHiddenName_hidden();
  }

  @failingTest
  @override
  test_duplicateShownHiddenName_shown() {
    return super.test_duplicateShownHiddenName_shown();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_named_parameter_with_default() async {
    return super.test_invalidRequiredParam_on_named_parameter_with_default();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_class() async {
    return super.test_missingJsLibAnnotation_class();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_externalField() async {
    return super.test_missingJsLibAnnotation_externalField();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_function() async {
    return super.test_missingJsLibAnnotation_function();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_method() async {
    return super.test_missingJsLibAnnotation_method();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_variable() async {
    return super.test_missingJsLibAnnotation_variable();
  }

  @failingTest
  @override
  test_mustCallSuper() async {
    return super.test_mustCallSuper();
  }

  @failingTest
  @override
  test_mustCallSuper_indirect() async {
    return super.test_mustCallSuper_indirect();
  }

  @override
  @failingTest
  test_required_function_param() async {
    return super.test_required_function_param();
  }

  @override
  @failingTest
  test_required_method_param() async {
    return super.test_required_method_param();
  }

  @override
  @failingTest
  test_required_method_param_in_other_lib() async {
    return super.test_required_method_param_in_other_lib();
  }

  @override
  @failingTest
  test_required_typedef_function_param() async {
    return super.test_required_typedef_function_param();
  }

  @failingTest
  @override
  test_strongMode_downCastCompositeHint() async {
    return super.test_strongMode_downCastCompositeHint();
  }

  @failingTest
  @override
  test_strongMode_downCastCompositeWarn() async {
    return super.test_strongMode_downCastCompositeWarn();
  }

  @failingTest
  @override
  test_unusedImport_inComment_libraryDirective() async {
    return super.test_unusedImport_inComment_libraryDirective();
  }

  @failingTest
  @override
  test_unusedShownName() async {
    return super.test_unusedShownName();
  }

  @failingTest
  @override
  test_unusedShownName_as() async {
    return super.test_unusedShownName_as();
  }

  @failingTest
  @override
  test_unusedShownName_duplicates() async {
    return super.test_unusedShownName_duplicates();
  }

  @failingTest
  @override
  test_unusedShownName_topLevelVariable() async {
    return super.test_unusedShownName_topLevelVariable();
  }
}
