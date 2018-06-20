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
  test_argumentTypeNotAssignable_invocation_typedef_generic() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super.test_argumentTypeNotAssignable_invocation_typedef_generic();
  }

  @override
  @failingTest
  test_argumentTypeNotAssignable_optionalNew() {
    // Bad state: No data for (builder: () {return Widget();}) at 164
    return super.test_argumentTypeNotAssignable_optionalNew();
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
  test_const_dynamic() {
    // UnimplementedError: TODO(paulberry): DynamicType
    return super.test_const_dynamic();
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
  test_duplicateDefinition_emptyName() {
    // NoSuchMethodError: The setter 'enclosingElement=' was called on null.
    return super.test_duplicateDefinition_emptyName();
  }

  @override
  @failingTest
  test_dynamicIdentifier() {
    // UnimplementedError: TODO(paulberry): DynamicType
    return super.test_dynamicIdentifier();
  }

  @override
  @failingTest
  test_fieldFormalParameter_genericFunctionTyped() {
    // Expected 0 errors of type ParserErrorCode.EXPECTED_TOKEN, found 1 (88)
    return super.test_fieldFormalParameter_genericFunctionTyped();
  }

  @override
  @failingTest
  test_fieldFormalParameter_genericFunctionTyped_named() {
    // Expected 0 errors of type ParserErrorCode.EXPECTED_TOKEN, found 1 (89)
    return super.test_fieldFormalParameter_genericFunctionTyped_named();
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
  test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super.test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_castsAndTypeChecks_noTypeParameters() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super.test_genericTypeAlias_castsAndTypeChecks_noTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_fieldAndReturnType_noTypeParameters() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super.test_genericTypeAlias_fieldAndReturnType_noTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super
        .test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments();
  }

  @override
  @failingTest
  test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
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
  test_genericTypeAlias_noTypeParameters() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super.test_genericTypeAlias_noTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_typeParameters() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super.test_genericTypeAlias_typeParameters();
  }

  @override // passes with kernel
  test_infer_mixin() => super.test_infer_mixin();

  @override // Passes with kernel
  test_infer_mixin_multiplyConstrained() =>
      super.test_infer_mixin_multiplyConstrained();

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
  test_invalidAnnotation_constantVariable_field_importWithPrefix() {
    // type 'PrefixedIdentifierImpl' is not a subtype of type 'SimpleIdentifier'
    // of 'topEntity'
    return super
        .test_invalidAnnotation_constantVariable_field_importWithPrefix();
  }

  @override
  @failingTest
  test_invalidAnnotation_constantVariable_topLevel_importWithPrefix() {
    // type 'PrefixedIdentifierImpl' is not a subtype of type 'SimpleIdentifier'
    // of 'topEntity'
    return super
        .test_invalidAnnotation_constantVariable_topLevel_importWithPrefix();
  }

  @override
  @failingTest
  test_invalidAnnotation_constConstructor_importWithPrefix() {
    // type 'PrefixedIdentifierImpl' is not a subtype of type 'SimpleIdentifier'
    // of 'topEntity'
    return super.test_invalidAnnotation_constConstructor_importWithPrefix();
  }

  @override
  @failingTest
  test_invalidAnnotation_constConstructor_named_importWithPrefix() {
    // Bad state: No data for named at 29
    return super
        .test_invalidAnnotation_constConstructor_named_importWithPrefix();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_functionTypeTypeParameter() {
    // UnimplementedError: TODO(paulberry): resynthesize generic typedef
    return super.test_invocationOfNonFunction_functionTypeTypeParameter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31758')
  test_invocationOfNonFunction_Object() async {
    return super.test_invocationOfNonFunction_Object();
  }

  @override
  @failingTest
  test_issue_32394() {
    // Failed assertion: line 1133 pos 12: 'element != null': is not true.
    return super.test_issue_32394();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_loadLibraryDefined() async {
    return super.test_loadLibraryDefined();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30609')
  test_metadata_enumConstantDeclaration() {
    // Failed to resolve 2 nodes
    return super.test_metadata_enumConstantDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_methodDeclaration_scope_signature() async {
    return super.test_methodDeclaration_scope_signature();
  }

  @override
  @failingTest
  test_nativeConstConstructor() {
    // Expected 0 errors of type ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, found 1 (35)
    return super.test_nativeConstConstructor();
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
  test_optionalNew_rewrite_instantiatesToBounds() {
    // Bad state: No data for named1 at 21
    return super.test_optionalNew_rewrite_instantiatesToBounds();
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
  test_undefinedGetter_static_conditionalAccess() {
    // Bad state: No data for A at 36
    return super.test_undefinedGetter_static_conditionalAccess();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedIdentifier_synthetic_whenMethodName() async {
    return super.test_undefinedIdentifier_synthetic_whenMethodName();
  }

  @override
  @failingTest
  test_undefinedMethod_static_conditionalAccess() {
    // Bad state: No data for A at 39
    return super.test_undefinedMethod_static_conditionalAccess();
  }

  @override
  @failingTest
  test_undefinedSetter_static_conditionalAccess() {
    // Bad state: No data for A at 34
    return super.test_undefinedSetter_static_conditionalAccess();
  }
}
