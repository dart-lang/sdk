// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_error_resolver_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest_Kernel);
  });
}

/// Tests marked with this annotation fail because they test features that
/// were implemented in Analyzer, but are intentionally not included into
/// the Dart 2.0 plan, or disabled for Dart 2.0 altogether.
const notForDart2 = const Object();

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class NonErrorResolverTest_Kernel extends NonErrorResolverTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31625')
  test_ambiguousImport_showCombinator() async {
    return super.test_ambiguousImport_showCombinator();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31758')
  test_argumentTypeNotAssignable_classWithCall_Function() async {
    return super.test_argumentTypeNotAssignable_classWithCall_Function();
  }

  @override
  @failingTest
  @notForDart2
  test_async_return_flattens_futures() async {
    // Only FutureOr is flattened.
    return super.test_async_return_flattens_futures();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeConstructor() async {
    return super.test_commentReference_beforeConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeEnum() async {
    return super.test_commentReference_beforeEnum();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeFunction_blockBody() async {
    return super.test_commentReference_beforeFunction_blockBody();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeFunction_expressionBody() async {
    return super.test_commentReference_beforeFunction_expressionBody();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeFunctionTypeAlias() async {
    return super.test_commentReference_beforeFunctionTypeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeGenericTypeAlias() async {
    return super.test_commentReference_beforeGenericTypeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeGetter() async {
    return super.test_commentReference_beforeGetter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_beforeMethod() async {
    return super.test_commentReference_beforeMethod();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_class() async {
    return super.test_commentReference_class();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31604')
  test_commentReference_setter() async {
    return super.test_commentReference_setter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constConstructorWithNonConstSuper_unresolved() async {
    return super.test_constConstructorWithNonConstSuper_unresolved();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constConstructorWithNonFinalField_mixin() async {
    return super.test_constConstructorWithNonFinalField_mixin();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constDeferredClass_new() async {
    return super.test_constDeferredClass_new();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_constructorDeclaration_scope_signature() async {
    return super.test_constructorDeclaration_scope_signature();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_hasNativeClause_hasConstructor() async {
    return super.test_finalNotInitialized_hasNativeClause_hasConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_hasNativeClause_noConstructor() async {
    return super.test_finalNotInitialized_hasNativeClause_noConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_forEach_genericFunctionType() async {
    return super.test_forEach_genericFunctionType();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_functionDeclaration_scope_signature() async {
    return super.test_functionDeclaration_scope_signature();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_functionTypeAlias_scope_signature() async {
    return super.test_functionTypeAlias_scope_signature();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_genericTypeAlias_invalidGenericFunctionType() async {
    return super.test_genericTypeAlias_invalidGenericFunctionType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_integerLiteralOutOfRange_negative_valid() async {
    return super.test_integerLiteralOutOfRange_negative_valid();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31641')
  test_invalidAnnotation_constantVariable_field() async {
    return super.test_invalidAnnotation_constantVariable_field();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31758')
  test_invalidAssignment_implicitlyImplementFunctionViaCall_1() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_1();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31758')
  test_invalidAssignment_implicitlyImplementFunctionViaCall_2() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31758')
  test_invalidAssignment_implicitlyImplementFunctionViaCall_3() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_3();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31758')
  test_invalidAssignment_implicitlyImplementFunctionViaCall_4() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_4();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31758')
  test_invocationOfNonFunction_Object() async {
    return super.test_invocationOfNonFunction_Object();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_loadLibraryDefined() async {
    return super.test_loadLibraryDefined();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30834')
  test_memberWithClassName_setter() async {
    return super.test_memberWithClassName_setter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_methodDeclaration_scope_signature() async {
    return super.test_methodDeclaration_scope_signature();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31628')
  test_nonConstCaseExpression_constField() async {
    return super.test_nonConstCaseExpression_constField();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31627')
  test_nonConstMapKey_constField() async {
    return super.test_nonConstMapKey_constField();
  }

  @override
  @failingTest
  @notForDart2
  test_null_callMethod() async {
    return super.test_null_callMethod();
  }

  @override
  @failingTest
  @notForDart2
  test_null_callOperator() async {
    return super.test_null_callOperator();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_returnOfInvalidType_typeParameter_18468() async {
    return super.test_returnOfInvalidType_typeParameter_18468();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_sharedDeferredPrefix() async {
    return super.test_sharedDeferredPrefix();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_staticAccessToInstanceMember_annotation() async {
    return super.test_staticAccessToInstanceMember_annotation();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeArgument_boundToFunctionType() async {
    return super.test_typeArgument_boundToFunctionType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedIdentifier_synthetic_whenExpression() async {
    return super.test_undefinedIdentifier_synthetic_whenExpression();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedIdentifier_synthetic_whenMethodName() async {
    return super.test_undefinedIdentifier_synthetic_whenMethodName();
  }
}
