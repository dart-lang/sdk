// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StrictModeTest_Kernel);
    defineReflectiveTests(TypePropagationTest_Kernel);
  });
}

@reflectiveTest
class StrictModeTest_Kernel extends StrictModeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get previewDart2 => true;

  @override
  @failingTest
  test_assert_is() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_assert_is();
  }

  @override
  @failingTest
  test_conditional_isNot() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_conditional_isNot();
  }

  @override
  @failingTest
  test_conditional_or_is() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_conditional_or_is();
  }

  @override
  @failingTest
  test_forEach() async {
    // 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart': Failed assertion: line 441 pos 16: 'identical(combiner.arguments.positional[0], rhs)': is not true.
    await super.test_forEach();
  }

  @override
  @failingTest
  test_if_isNot() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_if_isNot();
  }

  @override
  @failingTest
  test_if_isNot_abrupt() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_if_isNot_abrupt();
  }

  @override
  @failingTest
  test_if_or_is() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_if_or_is();
  }

  @override
  @failingTest
  test_localVar() async {
    // Expected 1 errors of type StaticTypeWarningCode.UNDEFINED_OPERATOR, found 0
    await super.test_localVar();
  }
}

@reflectiveTest
class TypePropagationTest_Kernel extends TypePropagationTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get previewDart2 => true;

  @override
  @failingTest
  test_as() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_as();
  }

  @override
  @failingTest
  test_assert() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_assert();
  }

  @override
  @failingTest
  test_assignment() async {
    // Expected: InterfaceTypeImpl:<int>
    await super.test_assignment();
  }

  @override
  @failingTest
  test_assignment_afterInitializer() async {
    // Expected: InterfaceTypeImpl:<double>
    await super.test_assignment_afterInitializer();
  }

  @override
  @failingTest
  test_assignment_throwExpression() async {
    // Bad state: Expected element reference for analyzer offset 25; got one for kernel offset 21
    await super.test_assignment_throwExpression();
  }

  @override
  @failingTest
  test_CanvasElement_getContext() async {
    // NoSuchMethodError: The getter 'name' was called on null.
    await super.test_CanvasElement_getContext();
  }

  @override
  @failingTest
  test_forEach() async {
    // Expected: InterfaceTypeImpl:<String>
    await super.test_forEach();
  }

  @override
  @failingTest
  test_forEach_async() async {
    // Expected: InterfaceTypeImpl:<String>
    await super.test_forEach_async();
  }

  @override
  @failingTest
  test_forEach_async_inheritedStream() async {
    // Expected: InterfaceTypeImpl:<List<String>>
    await super.test_forEach_async_inheritedStream();
  }

  @override
  @failingTest
  test_functionExpression_asInvocationArgument() async {
    // Expected: InterfaceTypeImpl:<int>
    await super.test_functionExpression_asInvocationArgument();
  }

  @override
  @failingTest
  test_functionExpression_asInvocationArgument_fromInferredInvocation() async {
    // Expected: InterfaceTypeImpl:<int>
    await super
        .test_functionExpression_asInvocationArgument_fromInferredInvocation();
  }

  @override
  @failingTest
  test_functionExpression_asInvocationArgument_functionExpressionInvocation() async {
    // Bad state: Expected a type for v at 43; got one for kernel offset 32
    await super
        .test_functionExpression_asInvocationArgument_functionExpressionInvocation();
  }

  @override
  @failingTest
  test_functionExpression_asInvocationArgument_notSubtypeOfStaticType() async {
    // Expected 1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super
        .test_functionExpression_asInvocationArgument_notSubtypeOfStaticType();
  }

  @override
  @failingTest
  test_functionExpression_asInvocationArgument_replaceIfMoreSpecific() async {
    // Expected: InterfaceTypeImpl:<String>
    await super
        .test_functionExpression_asInvocationArgument_replaceIfMoreSpecific();
  }

  @override
  @failingTest
  test_Future_then() async {
    // Expected: InterfaceTypeImpl:<int>
    await super.test_Future_then();
  }

  @override
  @failingTest
  test_initializer() async {
    // Expected: DynamicTypeImpl:<dynamic>
    await super.test_initializer();
  }

  @override
  @failingTest
  test_initializer_dereference() async {
    // Expected: InterfaceTypeImpl:<String>
    await super.test_initializer_dereference();
  }

  @override
  @failingTest
  test_is_conditional() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_is_conditional();
  }

  @override
  @failingTest
  test_is_if() async {
    // type 'ParenthesizedExpressionImpl' is not a subtype of type 'IsExpression' of 'isExpression' where
    await super.test_is_if();
  }

  @override
  @failingTest
  test_is_if_logicalAnd() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_is_if_logicalAnd();
  }

  @override
  @failingTest
  test_is_postConditional() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_is_postConditional();
  }

  @override
  @failingTest
  test_is_postIf() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_is_postIf();
  }

  @override
  @failingTest
  test_is_while() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_is_while();
  }

  @override
  @failingTest
  test_isNot_conditional() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_isNot_conditional();
  }

  @override
  @failingTest
  test_isNot_if() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_isNot_if();
  }

  @override
  @failingTest
  test_isNot_if_logicalOr() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_isNot_if_logicalOr();
  }

  @override
  @failingTest
  test_isNot_postConditional() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_isNot_postConditional();
  }

  @override
  @failingTest
  test_isNot_postIf() async {
    // Expected: same instance as InterfaceTypeImpl:<A>
    await super.test_isNot_postIf();
  }

  @override
  @failingTest
  test_listLiteral_same() async {
    // NoSuchMethodError: The getter 'element' was called on null.
    await super.test_listLiteral_same();
  }

  @override
  @failingTest
  test_mapLiteral_different() async {
    // NoSuchMethodError: The getter 'element' was called on null.
    await super.test_mapLiteral_different();
  }

  @override
  @failingTest
  test_mapLiteral_same() async {
    // NoSuchMethodError: The getter 'element' was called on null.
    await super.test_mapLiteral_same();
  }

  @override
  @failingTest
  test_mergePropagatedTypes_afterIfThen_different() async {
    // Expected: InterfaceTypeImpl:<String>
    await super.test_mergePropagatedTypes_afterIfThen_different();
  }

  @override
  @failingTest
  test_mergePropagatedTypes_afterIfThen_same() async {
    // Expected: InterfaceTypeImpl:<int>
    await super.test_mergePropagatedTypes_afterIfThen_same();
  }

  @override
  @failingTest
  test_mergePropagatedTypes_afterIfThenElse_same() async {
    // Expected: InterfaceTypeImpl:<int>
    await super.test_mergePropagatedTypes_afterIfThenElse_same();
  }

  @override
  @failingTest
  test_mergePropagatedTypesAtJoinPoint_4() async {
    // Expected: InterfaceTypeImpl:<int>
    await super.test_mergePropagatedTypesAtJoinPoint_4();
  }

  @override
  @failingTest
  test_objectAccessInference_enabled_for_cascades() async {
    // Expected: DynamicTypeImpl:<dynamic>
    await super.test_objectAccessInference_enabled_for_cascades();
  }

  @override
  @failingTest
  test_objectMethodInference_enabled_for_cascades() async {
    // Expected: DynamicTypeImpl:<dynamic>
    await super.test_objectMethodInference_enabled_for_cascades();
  }

  @override
  @failingTest
  test_objectMethodOnDynamicExpression_doubleEquals() async {
    // Expected: InterfaceTypeImpl:<bool>
    await super.test_objectMethodOnDynamicExpression_doubleEquals();
  }

  @override
  @failingTest
  test_objectMethodOnDynamicExpression_hashCode() async {
    // Expected: InterfaceTypeImpl:<int>
    await super.test_objectMethodOnDynamicExpression_hashCode();
  }

  @override
  @failingTest
  test_objectMethodOnDynamicExpression_runtimeType() async {
    // Expected: InterfaceTypeImpl:<Type>
    await super.test_objectMethodOnDynamicExpression_runtimeType();
  }

  @override
  @failingTest
  test_objectMethodOnDynamicExpression_toString() async {
    // Expected: InterfaceTypeImpl:<String>
    await super.test_objectMethodOnDynamicExpression_toString();
  }

  @override
  @failingTest
  test_propagatedReturnType_localFunction() async {
    // Expected: DynamicTypeImpl:<dynamic>
    await super.test_propagatedReturnType_localFunction();
  }

  @override
  @failingTest
  test_query() async {
    // NoSuchMethodError: The getter 'name' was called on null.
    await super.test_query();
  }
}
