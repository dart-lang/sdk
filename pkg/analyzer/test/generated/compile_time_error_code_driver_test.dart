// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'compile_time_error_code_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest_Driver);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest_Driver extends CompileTimeErrorCodeTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  @override
  test_fieldInitializerOutsideConstructor_inFunctionTypeParameter() {
    return super
        .test_fieldInitializerOutsideConstructor_inFunctionTypeParameter();
  }

  @failingTest
  @override
  test_fromEnvironment_bool_badDefault_whenDefined() {
    return super.test_fromEnvironment_bool_badDefault_whenDefined();
  }

  @failingTest
  @override
  test_nonConstValueInInitializer_assert_condition() {
    return super.test_nonConstValueInInitializer_assert_condition();
  }

  @failingTest
  @override
  test_nonConstValueInInitializer_assert_message() {
    return super.test_nonConstValueInInitializer_assert_message();
  }

  @failingTest
  @override
  test_prefixCollidesWithTopLevelMembers_functionTypeAlias() {
    return super.test_prefixCollidesWithTopLevelMembers_functionTypeAlias();
  }

  @failingTest
  @override
  test_prefixCollidesWithTopLevelMembers_topLevelFunction() {
    return super.test_prefixCollidesWithTopLevelMembers_topLevelFunction();
  }

  @failingTest
  @override
  test_prefixCollidesWithTopLevelMembers_topLevelVariable() {
    return super.test_prefixCollidesWithTopLevelMembers_topLevelVariable();
  }

  @failingTest
  @override
  test_prefixCollidesWithTopLevelMembers_type() {
    return super.test_prefixCollidesWithTopLevelMembers_type();
  }

  @failingTest
  @override
  test_typeAliasCannotReferenceItself_typeVariableBounds() {
    return super.test_typeAliasCannotReferenceItself_typeVariableBounds();
  }

  @failingTest
  @override
  test_uriDoesNotExist_import_appears_after_deleting_target() {
    return super.test_uriDoesNotExist_import_appears_after_deleting_target();
  }

  @failingTest
  @override
  test_uriWithInterpolation_nonConstant() {
    return super.test_uriWithInterpolation_nonConstant();
  }
}
