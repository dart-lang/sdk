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
  @failingTest
  test_ambiguousImport_function() async {
    // Bad state: No reference information for f at 53
    await super.test_ambiguousImport_function();
  }

  @override
  @failingTest
  test_assert_message_suppresses_type_promotion() async {
    // Bad state: No reference information for () {x = new C(); return 'msg';}() at 89
    await super.test_assert_message_suppresses_type_promotion();
  }

  @override
  @failingTest
  test_awaitForIn_declaredVariableWrongType() async {
    // Expected 1 errors of type StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, found 0
    await super.test_awaitForIn_declaredVariableWrongType();
  }

  @override
  @failingTest
  test_awaitForIn_existingVariableWrongType() async {
    // Expected 1 errors of type StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, found 0
    await super.test_awaitForIn_existingVariableWrongType();
  }

  @override
  @failingTest
  test_awaitForIn_notStream() async {
    // Expected 1 errors of type StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, found 0
    await super.test_awaitForIn_notStream();
  }

  @override
  @failingTest
  test_expectedOneListTypeArgument() async {
    // Bad state: Found 1 argument types for 2 type arguments
    await super.test_expectedOneListTypeArgument();
  }

  @override
  @failingTest
  test_expectedTwoMapTypeArguments_one() async {
    // Bad state: Found 2 argument types for 1 type arguments
    await super.test_expectedTwoMapTypeArguments_one();
  }

  @override
  @failingTest
  test_expectedTwoMapTypeArguments_three() async {
    // Bad state: Found 2 argument types for 3 type arguments
    await super.test_expectedTwoMapTypeArguments_three();
  }

  @override
  @failingTest
  test_forIn_declaredVariableWrongType() async {
    // Expected 1 errors of type StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, found 0
    await super.test_forIn_declaredVariableWrongType();
  }

  @override
  @failingTest
  test_forIn_existingVariableWrongType() async {
    // Expected 1 errors of type StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, found 0
    await super.test_forIn_existingVariableWrongType();
  }

  @override
  @failingTest
  test_forIn_notIterable() async {
    // Expected 1 errors of type StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, found 0
    await super.test_forIn_notIterable();
  }

  @override
  @failingTest
  test_forIn_typeBoundBad() async {
    // Expected 1 errors of type StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, found 0
    await super.test_forIn_typeBoundBad();
  }

  @override
  @failingTest
  test_illegalAsyncGeneratorReturnType_function_nonStream() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_illegalAsyncGeneratorReturnType_function_nonStream();
  }

  @override
  @failingTest
  test_illegalAsyncGeneratorReturnType_function_subtypeOfStream() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_illegalAsyncGeneratorReturnType_function_subtypeOfStream();
  }

  @override
  @failingTest
  test_illegalAsyncGeneratorReturnType_method_nonStream() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_illegalAsyncGeneratorReturnType_method_nonStream();
  }

  @override
  @failingTest
  test_illegalAsyncGeneratorReturnType_method_subtypeOfStream() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_illegalAsyncGeneratorReturnType_method_subtypeOfStream();
  }

  @override
  @failingTest
  test_illegalAsyncReturnType_function_nonFuture() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, found 0
    await super.test_illegalAsyncReturnType_function_nonFuture();
  }

  @override
  @failingTest
  test_illegalAsyncReturnType_function_subtypeOfFuture() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, found 0
    await super.test_illegalAsyncReturnType_function_subtypeOfFuture();
  }

  @override
  @failingTest
  test_illegalAsyncReturnType_method_nonFuture() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, found 0
    await super.test_illegalAsyncReturnType_method_nonFuture();
  }

  @override
  @failingTest
  test_illegalAsyncReturnType_method_subtypeOfFuture() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, found 0
    await super.test_illegalAsyncReturnType_method_subtypeOfFuture();
  }

  @override
  @failingTest
  test_illegalSyncGeneratorReturnType_function_nonIterator() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_illegalSyncGeneratorReturnType_function_nonIterator();
  }

  @override
  @failingTest
  test_illegalSyncGeneratorReturnType_function_subclassOfIterator() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, found 0
    await super
        .test_illegalSyncGeneratorReturnType_function_subclassOfIterator();
  }

  @override
  @failingTest
  test_illegalSyncGeneratorReturnType_method_nonIterator() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_illegalSyncGeneratorReturnType_method_nonIterator();
  }

  @override
  @failingTest
  test_illegalSyncGeneratorReturnType_method_subclassOfIterator() async {
    // Expected 1 errors of type StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_illegalSyncGeneratorReturnType_method_subclassOfIterator();
  }

  @override
  @failingTest
  test_inconsistentMethodInheritance_paramCount() async {
    // Expected 1 errors of type StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE, found 0
    await super.test_inconsistentMethodInheritance_paramCount();
  }

  @override
  @failingTest
  test_inconsistentMethodInheritance_paramType() async {
    // Expected 1 errors of type StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE, found 0
    await super.test_inconsistentMethodInheritance_paramType();
  }

  @override
  @failingTest
  test_inconsistentMethodInheritance_returnType() async {
    // Expected 1 errors of type StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE, found 0
    await super.test_inconsistentMethodInheritance_returnType();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_method_invocation() async {
    // Expected 1 errors of type StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, found 0
    await super.test_instanceAccessToStaticMember_method_invocation();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_method_reference() async {
    // Expected 1 errors of type StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, found 0
    await super.test_instanceAccessToStaticMember_method_reference();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_propertyAccess_field() async {
    // Expected 1 errors of type StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, found 0
    await super.test_instanceAccessToStaticMember_propertyAccess_field();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_propertyAccess_getter() async {
    // Expected 1 errors of type StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, found 0
    await super.test_instanceAccessToStaticMember_propertyAccess_getter();
  }

  @override
  @failingTest
  test_instanceAccessToStaticMember_propertyAccess_setter() async {
    // Expected 1 errors of type StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, found 0
    await super.test_instanceAccessToStaticMember_propertyAccess_setter();
  }

  @override
  @failingTest
  test_invalidAssignment_defaultValue_named() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t1 = 0 in let ...
    await super.test_invalidAssignment_defaultValue_named();
  }

  @override
  @failingTest
  test_invalidAssignment_defaultValue_optional() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t2 = 0 in let ...
    await super.test_invalidAssignment_defaultValue_optional();
  }

  @override
  @failingTest
  test_invalidAssignment_dynamic() async {
    // Bad state: No reference information for dynamic at 11
    await super.test_invalidAssignment_dynamic();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_class() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, found 0
    await super.test_invocationOfNonFunction_class();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_localObject() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, found 0
    await super.test_invocationOfNonFunction_localObject();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_localVariable() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, found 0
    await super.test_invocationOfNonFunction_localVariable();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_ordinaryInvocation() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, found 0
    await super.test_invocationOfNonFunction_ordinaryInvocation();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_staticInvocation() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, found 0
    await super.test_invocationOfNonFunction_staticInvocation();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_superExpression() async {
    // Expected 1 errors of type StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION, found 0
    await super.test_invocationOfNonFunction_superExpression();
  }

  @override
  @failingTest
  test_invocationOfNonFunctionExpression_literal() async {
    // Bad state: Expected a type for 5 at 10; got one for kernel offset 9
    await super.test_invocationOfNonFunctionExpression_literal();
  }

  @override
  @failingTest
  test_nonBoolCondition_conditional() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_CONDITION, found 0
    await super.test_nonBoolCondition_conditional();
  }

  @override
  @failingTest
  test_nonBoolCondition_do() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_CONDITION, found 0
    await super.test_nonBoolCondition_do();
  }

  @override
  @failingTest
  test_nonBoolCondition_for() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_CONDITION, found 0
    await super.test_nonBoolCondition_for();
  }

  @override
  @failingTest
  test_nonBoolCondition_if() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_CONDITION, found 0
    await super.test_nonBoolCondition_if();
  }

  @override
  @failingTest
  test_nonBoolCondition_while() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_CONDITION, found 0
    await super.test_nonBoolCondition_while();
  }

  @override
  @failingTest
  test_nonBoolExpression_functionType_bool() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_EXPRESSION, found 0
    await super.test_nonBoolExpression_functionType_bool();
  }

  @override
  @failingTest
  test_nonBoolExpression_functionType_int() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_EXPRESSION, found 0
    await super.test_nonBoolExpression_functionType_int();
  }

  @override
  @failingTest
  test_nonBoolExpression_interfaceType() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_EXPRESSION, found 0
    await super.test_nonBoolExpression_interfaceType();
  }

  @override
  @failingTest
  test_nonBoolNegationExpression() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION, found 0
    await super.test_nonBoolNegationExpression();
  }

  @override
  @failingTest
  test_nonBoolOperand_and_left() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_OPERAND, found 0
    await super.test_nonBoolOperand_and_left();
  }

  @override
  @failingTest
  test_nonBoolOperand_and_right() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_OPERAND, found 0
    await super.test_nonBoolOperand_and_right();
  }

  @override
  @failingTest
  test_nonBoolOperand_or_left() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_OPERAND, found 0
    await super.test_nonBoolOperand_or_left();
  }

  @override
  @failingTest
  test_nonBoolOperand_or_right() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_BOOL_OPERAND, found 0
    await super.test_nonBoolOperand_or_right();
  }

  @override
  @failingTest
  test_nonTypeAsTypeArgument_notAType() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, found 0
    await super.test_nonTypeAsTypeArgument_notAType();
  }

  @override
  @failingTest
  test_nonTypeAsTypeArgument_undefinedIdentifier() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, found 0
    await super.test_nonTypeAsTypeArgument_undefinedIdentifier();
  }

  @override
  @failingTest
  test_returnOfInvalidType_async_future_int_mismatches_future_string() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super
        .test_returnOfInvalidType_async_future_int_mismatches_future_string();
  }

  @override
  @failingTest
  test_returnOfInvalidType_async_future_int_mismatches_int() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0;
    //          1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, found 0
    await super.test_returnOfInvalidType_async_future_int_mismatches_int();
  }

  @override
  @failingTest
  test_returnOfInvalidType_expressionFunctionBody_function() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_expressionFunctionBody_function();
  }

  @override
  @failingTest
  test_returnOfInvalidType_expressionFunctionBody_getter() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_expressionFunctionBody_getter();
  }

  @override
  @failingTest
  test_returnOfInvalidType_expressionFunctionBody_localFunction() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_expressionFunctionBody_localFunction();
  }

  @override
  @failingTest
  test_returnOfInvalidType_expressionFunctionBody_method() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_expressionFunctionBody_method();
  }

  @override
  @failingTest
  test_returnOfInvalidType_function() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_function();
  }

  @override
  @failingTest
  test_returnOfInvalidType_getter() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_getter();
  }

  @override
  @failingTest
  test_returnOfInvalidType_localFunction() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_localFunction();
  }

  @override
  @failingTest
  test_returnOfInvalidType_method() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_method();
  }

  @override
  @failingTest
  test_returnOfInvalidType_void() async {
    // Expected 1 errors of type StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, found 0
    await super.test_returnOfInvalidType_void();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_classTypeAlias() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_classTypeAlias();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_extends() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_extends();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_extends_regressionInIssue18468Fix() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super
        .test_typeArgumentNotMatchingBounds_extends_regressionInIssue18468Fix();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_fieldFormalParameter() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_fieldFormalParameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_functionReturnType() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_functionReturnType();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_functionTypeAlias() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_functionTypeAlias();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_functionTypedFormalParameter() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super
        .test_typeArgumentNotMatchingBounds_functionTypedFormalParameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_implements() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_implements();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_is() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_is();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodInvocation_localFunction() async {
    // 'package:analyzer/src/fasta/resolution_applier.dart': Failed assertion: line 236 pos 18: 'typeParameter.bound == null': is not true.
    await super
        .test_typeArgumentNotMatchingBounds_methodInvocation_localFunction();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodInvocation_method() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_methodInvocation_method();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodInvocation_topLevelFunction() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super
        .test_typeArgumentNotMatchingBounds_methodInvocation_topLevelFunction();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_methodReturnType() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_methodReturnType();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_new() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_new();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_new_superTypeOfUpperBound() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_new_superTypeOfUpperBound();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_parameter() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_parameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_redirectingConstructor() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0;
    //          1 errors of type StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE, found 0
    await super.test_typeArgumentNotMatchingBounds_redirectingConstructor();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_typeArgumentList() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_typeArgumentList();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_typeParameter() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_typeParameter();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_variableDeclaration() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_variableDeclaration();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_with() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_with();
  }

  @override
  @failingTest
  test_typeParameterSupertypeOfItsBound() async {
    // Expected 1 errors of type StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, found 0
    await super.test_typeParameterSupertypeOfItsBound();
  }

  @override
  @failingTest
  test_typePromotion_booleanAnd_useInRight_mutatedInLeft() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_GETTER, found 0
    await super.test_typePromotion_booleanAnd_useInRight_mutatedInLeft();
  }

  @override
  @failingTest
  test_typePromotion_if_and_right_hasAssignment() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_GETTER, found 0
    await super.test_typePromotion_if_and_right_hasAssignment();
  }

  @override
  @failingTest
  test_undefinedFunction() async {
    // Bad state: No reference information for g at 13
    await super.test_undefinedFunction();
  }

  @override
  @failingTest
  test_undefinedFunction_inCatch() async {
    // Bad state: No reference information for g at 39
    await super.test_undefinedFunction_inCatch();
  }

  @override
  @failingTest
  test_undefinedFunction_inImportedLib() async {
    // Bad state: No reference information for f at 40
    await super.test_undefinedFunction_inImportedLib();
  }

  @override
  @failingTest
  test_undefinedGetter_static() async {
    // Bad state: No reference information for A at 19
    await super.test_undefinedGetter_static();
  }

  @override
  @failingTest
  test_undefinedGetter_typeLiteral_conditionalAccess() async {
    // Bad state: No reference information for A at 18
    await super.test_undefinedGetter_typeLiteral_conditionalAccess();
  }

  @override
  @failingTest
  test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle() async {
    // AnalysisException: Element mismatch in /test.dart at main(A<dynamic, dynamic> a) → dynamic
    await super.test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle();
  }

  @override
  @failingTest
  test_undefinedGetter_wrongNumberOfTypeArguments_tooMany() async {
    // AnalysisException: Element mismatch in /test.dart at main(A<dynamic> a) → dynamic
    await super.test_undefinedGetter_wrongNumberOfTypeArguments_tooMany();
  }

  @override
  @failingTest
  test_undefinedGetter_wrongOfTypeArgument() async {
    // Expected 1 errors of type StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, found 0
    await super.test_undefinedGetter_wrongOfTypeArgument();
  }

  @override
  @failingTest
  test_undefinedMethod_generic_function_call() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_METHOD, found 0
    await super.test_undefinedMethod_generic_function_call();
  }

  @override
  @failingTest
  test_undefinedMethod_ignoreTypePropagation() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_METHOD, found 0
    await super.test_undefinedMethod_ignoreTypePropagation();
  }

  @override
  @failingTest
  test_undefinedMethod_leastUpperBoundWithNull() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_METHOD, found 0
    await super.test_undefinedMethod_leastUpperBoundWithNull();
  }

  @override
  @failingTest
  test_undefinedMethod_object_call() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_METHOD, found 0
    await super.test_undefinedMethod_object_call();
  }

  @override
  @failingTest
  test_undefinedMethod_ofNull() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_METHOD, found 0
    await super.test_undefinedMethod_ofNull();
  }

  @override
  @failingTest
  test_undefinedMethod_proxy_annotation_fakeProxy() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_METHOD, found 0
    await super.test_undefinedMethod_proxy_annotation_fakeProxy();
  }

  @override
  @failingTest
  test_undefinedMethod_typeLiteral_cascadeTarget() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_METHOD, found 0
    await super.test_undefinedMethod_typeLiteral_cascadeTarget();
  }

  @override
  @failingTest
  test_undefinedMethod_typeLiteral_conditionalAccess() async {
    // Bad state: No reference information for A at 18
    await super.test_undefinedMethod_typeLiteral_conditionalAccess();
  }

  @override
  @failingTest
  test_undefinedMethodWithConstructor() async {
    // Bad state: No reference information for C at 35
    await super.test_undefinedMethodWithConstructor();
  }

  @override
  @failingTest
  test_undefinedOperator_indexBoth() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_undefinedOperator_indexBoth();
  }

  @override
  @failingTest
  test_undefinedOperator_indexGetter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_undefinedOperator_indexGetter();
  }

  @override
  @failingTest
  test_undefinedOperator_indexSetter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_undefinedOperator_indexSetter();
  }

  @override
  @failingTest
  test_undefinedOperator_plus() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_undefinedOperator_plus();
  }

  @override
  @failingTest
  test_undefinedOperator_postfixExpression() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_undefinedOperator_postfixExpression();
  }

  @override
  @failingTest
  test_undefinedOperator_prefixExpression() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_undefinedOperator_prefixExpression();
  }

  @override
  @failingTest
  test_undefinedSetter_static() async {
    // Bad state: No reference information for A at 17
    await super.test_undefinedSetter_static();
  }

  @override
  @failingTest
  test_undefinedSuperGetter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_SUPER_GETTER, found 0
    await super.test_undefinedSuperGetter();
  }

  @override
  @failingTest
  test_undefinedSuperMethod() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_SUPER_METHOD, found 0
    await super.test_undefinedSuperMethod();
  }

  @override
  @failingTest
  test_undefinedSuperOperator_binaryExpression() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR, found 0
    await super.test_undefinedSuperOperator_binaryExpression();
  }

  @override
  @failingTest
  test_undefinedSuperOperator_indexBoth() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR, found 0
    await super.test_undefinedSuperOperator_indexBoth();
  }

  @override
  @failingTest
  test_undefinedSuperOperator_indexGetter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR, found 0
    await super.test_undefinedSuperOperator_indexGetter();
  }

  @override
  @failingTest
  test_undefinedSuperOperator_indexSetter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR, found 0
    await super.test_undefinedSuperOperator_indexSetter();
  }

  @override
  @failingTest
  test_undefinedSuperSetter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_SUPER_SETTER, found 0
    await super.test_undefinedSuperSetter();
  }

  @override
  @failingTest
  test_unqualifiedReferenceToNonLocalStaticMember_getter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER, found 0
    await super.test_unqualifiedReferenceToNonLocalStaticMember_getter();
  }

  @override
  @failingTest
  test_unqualifiedReferenceToNonLocalStaticMember_getter_invokeTarget() async {
    // Bad state: No reference information for foo at 72
    await super
        .test_unqualifiedReferenceToNonLocalStaticMember_getter_invokeTarget();
  }

  @override
  @failingTest
  test_unqualifiedReferenceToNonLocalStaticMember_method() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER, found 0
    await super.test_unqualifiedReferenceToNonLocalStaticMember_method();
  }

  @override
  @failingTest
  test_unqualifiedReferenceToNonLocalStaticMember_setter() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER, found 0
    await super.test_unqualifiedReferenceToNonLocalStaticMember_setter();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_classAlias() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_wrongNumberOfTypeArguments_classAlias();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_tooFew() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_wrongNumberOfTypeArguments_tooFew();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_tooMany() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_wrongNumberOfTypeArguments_tooMany();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_typeTest_tooFew() async {
    // Bad state: Found 2 argument types for 1 type arguments
    await super.test_wrongNumberOfTypeArguments_typeTest_tooFew();
  }

  @override
  @failingTest
  test_wrongNumberOfTypeArguments_typeTest_tooMany() async {
    // Bad state: Found 1 argument types for 2 type arguments
    await super.test_wrongNumberOfTypeArguments_typeTest_tooMany();
  }

  @override
  @failingTest
  test_yield_async_to_basic_type() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0;
    //          1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_yield_async_to_basic_type();
  }

  @override
  @failingTest
  test_yield_async_to_iterable() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0;
    //          1 errors of type StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_yield_async_to_iterable();
  }

  @override
  @failingTest
  test_yield_async_to_mistyped_stream() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0
    await super.test_yield_async_to_mistyped_stream();
  }

  @override
  @failingTest
  test_yield_each_async_non_stream() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0
    await super.test_yield_each_async_non_stream();
  }

  @override
  @failingTest
  test_yield_each_async_to_mistyped_stream() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0
    await super.test_yield_each_async_to_mistyped_stream();
  }

  @override
  @failingTest
  test_yield_each_sync_non_iterable() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0
    await super.test_yield_each_sync_non_iterable();
  }

  @override
  @failingTest
  test_yield_each_sync_to_mistyped_iterable() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0
    await super.test_yield_each_sync_to_mistyped_iterable();
  }

  @override
  @failingTest
  test_yield_sync_to_basic_type() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0;
    //          1 errors of type StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, found 0
    await super.test_yield_sync_to_basic_type();
  }

  @override
  @failingTest
  test_yield_sync_to_mistyped_iterable() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0
    await super.test_yield_sync_to_mistyped_iterable();
  }

  @override
  @failingTest
  test_yield_sync_to_stream() async {
    // Expected 1 errors of type StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, found 0;
    //          1 errors of type StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, found 0
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
  @failingTest
  test_genericMethodWrongNumberOfTypeArguments() async {
    // Bad state: Found 0 argument types for 1 type arguments
    await super.test_genericMethodWrongNumberOfTypeArguments();
  }
}
