// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'non_error_resolver_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest_Kernel);
  });
}

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
  bool get previewDart2 => true;

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31625')
  test_ambiguousImport_showCombinator() async {
    return super.test_ambiguousImport_showCombinator();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_assignmentToFinals_importWithPrefix() async {
    return super.test_assignmentToFinals_importWithPrefix();
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
  @potentialAnalyzerProblem
  test_constEval_propertyExtraction_fieldStatic_targetType() async {
    return super.test_constEval_propertyExtraction_fieldStatic_targetType();
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
  test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters() async {
    return super.test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_genericTypeAlias_castsAndTypeChecks_noTypeParameters() async {
    return super.test_genericTypeAlias_castsAndTypeChecks_noTypeParameters();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_genericTypeAlias_fieldAndReturnType_noTypeParameters() async {
    return super.test_genericTypeAlias_fieldAndReturnType_noTypeParameters();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30838')
  test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments() async {
    return super
        .test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30838')
  test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments() async {
    return super
        .test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments();
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
  test_genericTypeAlias_noTypeParameters() async {
    return super.test_genericTypeAlias_noTypeParameters();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_genericTypeAlias_typeParameters() async {
    return super.test_genericTypeAlias_typeParameters();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_importPrefixes_withFirstLetterDifference() async {
    return super.test_importPrefixes_withFirstLetterDifference();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAnnotation_constantVariable_field() async {
    return super.test_invalidAnnotation_constantVariable_field();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAnnotation_constantVariable_field_importWithPrefix() async {
    return super
        .test_invalidAnnotation_constantVariable_field_importWithPrefix();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAnnotation_constantVariable_topLevel_importWithPrefix() async {
    return super
        .test_invalidAnnotation_constantVariable_topLevel_importWithPrefix();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAnnotation_constConstructor_importWithPrefix() async {
    return super.test_invalidAnnotation_constConstructor_importWithPrefix();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAnnotation_constConstructor_named_importWithPrefix() async {
    return super
        .test_invalidAnnotation_constConstructor_named_importWithPrefix();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invocationOfNonFunction_dynamic() async {
    // TODO(scheglov) This test fails only in checked mode.
    fail('This test fails only in checked mode');
    return super.test_invocationOfNonFunction_dynamic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invocationOfNonFunction_functionTypeTypeParameter() async {
    return super.test_invocationOfNonFunction_functionTypeTypeParameter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invocationOfNonFunction_getter() async {
    // TODO(scheglov) This test fails only in checked mode.
    fail('This test fails only in checked mode');
    return super.test_invocationOfNonFunction_getter();
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
  @potentialAnalyzerProblem
  test_nonConstantValueInInitializer_namedArgument() async {
    return super.test_nonConstantValueInInitializer_namedArgument();
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
  @potentialAnalyzerProblem
  test_nonConstValueInInitializer_binary_dynamic() async {
    return super.test_nonConstValueInInitializer_binary_dynamic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_prefixCollidesWithTopLevelMembers() async {
    return super.test_prefixCollidesWithTopLevelMembers();
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
  test_typeType_class_prefixed() async {
    return super.test_typeType_class_prefixed();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeType_functionTypeAlias_prefixed() async {
    return super.test_typeType_functionTypeAlias_prefixed();
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

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedMethod_functionExpression_callMethod() async {
    return super.test_undefinedMethod_functionExpression_callMethod();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedMethod_functionExpression_directCall() async {
    return super.test_undefinedMethod_functionExpression_directCall();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedSetter_importWithPrefix() async {
    return super.test_undefinedSetter_importWithPrefix();
  }
}
