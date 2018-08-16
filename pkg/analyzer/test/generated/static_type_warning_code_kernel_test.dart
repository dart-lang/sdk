// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_type_warning_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeWarningCodeTest_Kernel);
    defineReflectiveTests(StrongModeStaticTypeWarningCodeTest_Kernel);
  });
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class StaticTypeWarningCodeTest_Kernel
    extends StaticTypeWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  test_assert_message_suppresses_type_promotion() async {
    await super.test_assert_message_suppresses_type_promotion();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_method_invocation() async {
    await super.test_instanceAccessToStaticMember_method_invocation();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_method_reference() async {
    await super.test_instanceAccessToStaticMember_method_reference();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_propertyAccess_field() async {
    await super.test_instanceAccessToStaticMember_propertyAccess_field();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_propertyAccess_getter() async {
    await super.test_instanceAccessToStaticMember_propertyAccess_getter();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_propertyAccess_setter() async {
    await super.test_instanceAccessToStaticMember_propertyAccess_setter();
  }

  @override
  @failingTest
  test_invalidAssignment_dynamic() async {
    await super.test_invalidAssignment_dynamic();
  }

  @override
  @failingTest
  test_nonTypeAsTypeArgument_notAType() async {
    await super.test_nonTypeAsTypeArgument_notAType();
  }

  @override
  @failingTest
  test_returnOfInvalidType_async_future_int_mismatches_int() async {
    await super.test_returnOfInvalidType_async_future_int_mismatches_int();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_classTypeAlias() async {
    await super.test_typeArgumentNotMatchingBounds_classTypeAlias();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_extends() async {
    await super.test_typeArgumentNotMatchingBounds_extends();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_extends_regressionInIssue18468Fix() async {
    await super
        .test_typeArgumentNotMatchingBounds_extends_regressionInIssue18468Fix();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_fieldFormalParameter() async {
    await super.test_typeArgumentNotMatchingBounds_fieldFormalParameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_functionReturnType() async {
    await super.test_typeArgumentNotMatchingBounds_functionReturnType();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_functionTypeAlias() async {
    await super.test_typeArgumentNotMatchingBounds_functionTypeAlias();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_functionTypedFormalParameter() async {
    await super
        .test_typeArgumentNotMatchingBounds_functionTypedFormalParameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_implements() async {
    await super.test_typeArgumentNotMatchingBounds_implements();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_is() async {
    await super.test_typeArgumentNotMatchingBounds_is();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodInvocation_localFunction() async {
    await super
        .test_typeArgumentNotMatchingBounds_methodInvocation_localFunction();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodInvocation_method() async {
    await super.test_typeArgumentNotMatchingBounds_methodInvocation_method();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodInvocation_topLevelFunction() async {
    await super
        .test_typeArgumentNotMatchingBounds_methodInvocation_topLevelFunction();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodReturnType() async {
    await super.test_typeArgumentNotMatchingBounds_methodReturnType();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_new() async {
    await super.test_typeArgumentNotMatchingBounds_new();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_new_superTypeOfUpperBound() async {
    await super.test_typeArgumentNotMatchingBounds_new_superTypeOfUpperBound();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_parameter() async {
    await super.test_typeArgumentNotMatchingBounds_parameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_redirectingConstructor() async {
    await super.test_typeArgumentNotMatchingBounds_redirectingConstructor();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_typeArgumentList() async {
    await super.test_typeArgumentNotMatchingBounds_typeArgumentList();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_typeParameter() async {
    await super.test_typeArgumentNotMatchingBounds_typeParameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_variableDeclaration() async {
    await super.test_typeArgumentNotMatchingBounds_variableDeclaration();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_with() async {
    await super.test_typeArgumentNotMatchingBounds_with();
  }

  @override
  @failingTest
  test_typeParameterSupertypeOfItsBound() async {
    await super.test_typeParameterSupertypeOfItsBound();
  }

  @override
  @failingTest
  test_typePromotion_booleanAnd_useInRight_mutatedInLeft() async {
    await super.test_typePromotion_booleanAnd_useInRight_mutatedInLeft();
  }

  @override
  @failingTest
  test_typePromotion_if_and_right_hasAssignment() async {
    await super.test_typePromotion_if_and_right_hasAssignment();
  }

  @override
  @failingTest
  test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle() async {
    await super.test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle();
  }

  @override
  @failingTest
  test_undefinedGetter_wrongNumberOfTypeArguments_tooMany() async {
    await super.test_undefinedGetter_wrongNumberOfTypeArguments_tooMany();
  }

  @override
  @failingTest
  test_undefinedMethod_generic_function_call() async {
    await super.test_undefinedMethod_generic_function_call();
  }

  @override
  @failingTest
  test_undefinedMethod_ignoreTypePropagation() async {
    await super.test_undefinedMethod_ignoreTypePropagation();
  }

  @override
  @failingTest
  test_undefinedMethod_leastUpperBoundWithNull() async {
    await super.test_undefinedMethod_leastUpperBoundWithNull();
  }

  @override
  @failingTest
  test_undefinedMethod_object_call() async {
    await super.test_undefinedMethod_object_call();
  }

  @override
  @failingTest
  test_undefinedMethod_ofNull() async {
    await super.test_undefinedMethod_ofNull();
  }

  @override
  @failingTest
  test_undefinedMethod_proxy_annotation_fakeProxy() async {
    await super.test_undefinedMethod_proxy_annotation_fakeProxy();
  }

  @override
  @failingTest
  test_undefinedMethod_typeLiteral_cascadeTarget() async {
    await super.test_undefinedMethod_typeLiteral_cascadeTarget();
  }

  @override
  @failingTest
  test_undefinedSuperMethod() async {
    await super.test_undefinedSuperMethod();
  }

  @override
  @failingTest
  test_yield_async_to_basic_type() async {
    await super.test_yield_async_to_basic_type();
  }

  @override
  @failingTest
  test_yield_async_to_iterable() async {
    await super.test_yield_async_to_iterable();
  }

  @override
  @failingTest
  test_yield_sync_to_basic_type() async {
    await super.test_yield_sync_to_basic_type();
  }

  @override
  @failingTest
  test_yield_sync_to_stream() async {
    await super.test_yield_sync_to_stream();
  }
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest_Kernel
    extends StrongModeStaticTypeWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  test_genericMethodWrongNumberOfTypeArguments() async {
    await super.test_genericMethodWrongNumberOfTypeArguments();
  }
}
