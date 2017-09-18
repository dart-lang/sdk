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

@reflectiveTest
class NonErrorResolverTest_Kernel extends NonErrorResolverTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_commentReference_beforeMethod() async {
    fail('This test fails only in checked mode.');
    return super.test_commentReference_beforeMethod();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_setter() async {
    return super.test_conflictingConstructorNameAndMember_setter();
  }

  @override
  @failingTest
  test_const_constructor_with_named_generic_parameter() async {
    return super.test_const_constructor_with_named_generic_parameter();
  }

  @override
  @failingTest
  test_const_dynamic() async {
    return super.test_const_dynamic();
  }

  @override
  @failingTest
  test_const_imported_defaultParameterValue_withImportPrefix() async {
    return super.test_const_imported_defaultParameterValue_withImportPrefix();
  }

  @override
  @failingTest
  test_constConstructorWithNonConstSuper_unresolved() async {
    return super.test_constConstructorWithNonConstSuper_unresolved();
  }

  @override
  @failingTest
  test_constConstructorWithNonFinalField_finalInstanceVar() async {
    return super.test_constConstructorWithNonFinalField_finalInstanceVar();
  }

  @override
  @failingTest
  test_constDeferredClass_new() async {
    return super.test_constDeferredClass_new();
  }

  @override
  @failingTest
  test_constEval_functionTypeLiteral() async {
    return super.test_constEval_functionTypeLiteral();
  }

  @override
  @failingTest
  test_constEval_propertyExtraction_fieldStatic_targetType() async {
    return super.test_constEval_propertyExtraction_fieldStatic_targetType();
  }

  @override
  @failingTest
  test_constEval_propertyExtraction_methodStatic_targetType() async {
    return super.test_constEval_propertyExtraction_methodStatic_targetType();
  }

  @override
  @failingTest
  test_constEval_symbol() async {
    return super.test_constEval_symbol();
  }

  @override
  @failingTest
  test_constEvalTypeBoolNumString_equal() async {
    return super.test_constEvalTypeBoolNumString_equal();
  }

  @override
  @failingTest
  test_constEvalTypeBoolNumString_notEqual() async {
    return super.test_constEvalTypeBoolNumString_notEqual();
  }

  @override
  @failingTest
  test_constEvelTypeNum_String() async {
    return super.test_constEvelTypeNum_String();
  }

  @override
  @failingTest
  test_constNotInitialized_field() async {
    return super.test_constNotInitialized_field();
  }

  @override
  @failingTest
  test_constRedirectSkipsSupertype() async {
    return super.test_constRedirectSkipsSupertype();
  }

  @override
  @failingTest
  test_constructorDeclaration_scope_signature() async {
    return super.test_constructorDeclaration_scope_signature();
  }

  @override
  @failingTest
  test_constWithNonConstantArgument_constField() async {
    return super.test_constWithNonConstantArgument_constField();
  }

  @override
  @failingTest
  test_constWithTypeParameters_direct() async {
    return super.test_constWithTypeParameters_direct();
  }

  @override
  @failingTest
  test_constWithUndefinedConstructor() async {
    return super.test_constWithUndefinedConstructor();
  }

  @override
  @failingTest
  test_deprecatedMemberUse_hide() async {
    return super.test_deprecatedMemberUse_hide();
  }

  @override
  @failingTest
  test_duplicateDefinition_emptyName() async {
    return super.test_duplicateDefinition_emptyName();
  }

  @override
  @failingTest
  test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() async {
    return super
        .test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal();
  }

  @override
  @failingTest
  test_finalNotInitialized_atDeclaration() async {
    return super.test_finalNotInitialized_atDeclaration();
  }

  @override
  @failingTest
  test_finalNotInitialized_fieldFormal() async {
    return super.test_finalNotInitialized_fieldFormal();
  }

  @override
  @failingTest
  test_finalNotInitialized_hasNativeClause_hasConstructor() async {
    return super.test_finalNotInitialized_hasNativeClause_hasConstructor();
  }

  @override
  @failingTest
  test_finalNotInitialized_hasNativeClause_noConstructor() async {
    fail('This test fails only in checked mode.');
    return super.test_finalNotInitialized_hasNativeClause_noConstructor();
  }

  @override
  @failingTest
  test_finalNotInitialized_redirectingConstructor() async {
    return super.test_finalNotInitialized_redirectingConstructor();
  }

  @override
  @failingTest
  test_functionDeclaration_scope_signature() async {
    return super.test_functionDeclaration_scope_signature();
  }

  @override
  @failingTest
  test_functionTypeAlias_scope_signature() async {
    return super.test_functionTypeAlias_scope_signature();
  }

  @override
  @failingTest
  test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters() async {
    return super.test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_castsAndTypeChecks_noTypeParameters() async {
    return super.test_genericTypeAlias_castsAndTypeChecks_noTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_fieldAndReturnType_noTypeParameters() async {
    return super.test_genericTypeAlias_fieldAndReturnType_noTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments() async {
    return super
        .test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments();
  }

  @override
  @failingTest
  test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments() async {
    return super
        .test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments();
  }

  @override
  @failingTest
  test_genericTypeAlias_invalidGenericFunctionType() async {
    return super.test_genericTypeAlias_invalidGenericFunctionType();
  }

  @override
  @failingTest
  test_genericTypeAlias_noTypeParameters() async {
    return super.test_genericTypeAlias_noTypeParameters();
  }

  @override
  @failingTest
  test_genericTypeAlias_typeParameters() async {
    return super.test_genericTypeAlias_typeParameters();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_constructorName() async {
    return super.test_implicitThisReferenceInInitializer_constructorName();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_topLevelField() async {
    return super.test_implicitThisReferenceInInitializer_topLevelField();
  }

  @override
  @failingTest
  test_invalidAnnotation_constantVariable_field() async {
    return super.test_invalidAnnotation_constantVariable_field();
  }

  @override
  @failingTest
  test_invalidAnnotation_constantVariable_field_importWithPrefix() async {
    return super
        .test_invalidAnnotation_constantVariable_field_importWithPrefix();
  }

  @override
  @failingTest
  test_invalidAnnotation_constantVariable_topLevel() async {
    return super.test_invalidAnnotation_constantVariable_topLevel();
  }

  @override
  @failingTest
  test_invalidAssignment_defaultValue_named() async {
    return super.test_invalidAssignment_defaultValue_named();
  }

  @override
  @failingTest
  test_invalidAssignment_defaultValue_optional() async {
    return super.test_invalidAssignment_defaultValue_optional();
  }

  @override
  @failingTest
  test_invalidAssignment_implicitlyImplementFunctionViaCall_1() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_1();
  }

  @override
  @failingTest
  test_invalidAssignment_implicitlyImplementFunctionViaCall_2() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_2();
  }

  @override
  @failingTest
  test_invalidAssignment_implicitlyImplementFunctionViaCall_3() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_3();
  }

  @override
  @failingTest
  test_invalidAssignment_implicitlyImplementFunctionViaCall_4() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_4();
  }

  @override
  @failingTest
  test_invalidOverrideDifferentDefaultValues_named() async {
    return super.test_invalidOverrideDifferentDefaultValues_named();
  }

  @override
  @failingTest
  test_invalidOverrideDifferentDefaultValues_named_function() async {
    return super.test_invalidOverrideDifferentDefaultValues_named_function();
  }

  @override
  @failingTest
  test_invalidOverrideDifferentDefaultValues_positional() async {
    return super.test_invalidOverrideDifferentDefaultValues_positional();
  }

  @override
  @failingTest
  test_invalidOverrideDifferentDefaultValues_positional_changedOrder() async {
    return super
        .test_invalidOverrideDifferentDefaultValues_positional_changedOrder();
  }

  @override
  @failingTest
  test_invalidOverrideDifferentDefaultValues_positional_function() async {
    return super
        .test_invalidOverrideDifferentDefaultValues_positional_function();
  }

  @override
  @failingTest
  test_invocationOfNonFunction_proxyOnFunctionClass() async {
    return super.test_invocationOfNonFunction_proxyOnFunctionClass();
  }

  @override
  @failingTest
  test_listElementTypeNotAssignable() async {
    return super.test_listElementTypeNotAssignable();
  }

  @override
  @failingTest
  test_loadLibraryDefined() async {
    fail('This test fails only in checked mode.');
    return super.test_loadLibraryDefined();
  }

  @override
  @failingTest
  test_mapKeyTypeNotAssignable() async {
    return super.test_mapKeyTypeNotAssignable();
  }

  @override
  @failingTest
  test_memberWithClassName_setter() async {
    return super.test_memberWithClassName_setter();
  }

  @override
  @failingTest
  test_methodDeclaration_scope_signature() async {
    return super.test_methodDeclaration_scope_signature();
  }

  @override
  @failingTest
  test_nativeConstConstructor() async {
    return super.test_nativeConstConstructor();
  }

  @override
  @failingTest
  test_nativeFunctionBodyInNonSDKCode_function() async {
    return super.test_nativeFunctionBodyInNonSDKCode_function();
  }

  @override
  @failingTest
  test_newWithUndefinedConstructor() async {
    return super.test_newWithUndefinedConstructor();
  }

  @override
  @failingTest
  test_nonAbstractClassInheritsAbstractMemberOne_overridesMethodInObject() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_overridesMethodInObject();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_constField() async {
    return super.test_nonConstantDefaultValue_constField();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_function_named() async {
    return super.test_nonConstantDefaultValue_function_named();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_function_positional() async {
    return super.test_nonConstantDefaultValue_function_positional();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_inConstructor_named() async {
    return super.test_nonConstantDefaultValue_inConstructor_named();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_inConstructor_positional() async {
    return super.test_nonConstantDefaultValue_inConstructor_positional();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_method_named() async {
    return super.test_nonConstantDefaultValue_method_named();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_method_positional() async {
    return super.test_nonConstantDefaultValue_method_positional();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_typedConstList() async {
    return super.test_nonConstantDefaultValue_typedConstList();
  }

  @override
  @failingTest
  test_nonConstCaseExpression_constField() async {
    return super.test_nonConstCaseExpression_constField();
  }

  @override
  @failingTest
  test_nonConstListElement_constField() async {
    return super.test_nonConstListElement_constField();
  }

  @override
  @failingTest
  test_nonConstMapKey_constField() async {
    return super.test_nonConstMapKey_constField();
  }

  @override
  @failingTest
  test_nonConstMapValue_constField() async {
    return super.test_nonConstMapValue_constField();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_bool() async {
    return super.test_nonConstValueInInitializer_binary_bool();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_dynamic() async {
    return super.test_nonConstValueInInitializer_binary_dynamic();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_int() async {
    return super.test_nonConstValueInInitializer_binary_int();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_num() async {
    return super.test_nonConstValueInInitializer_binary_num();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_redirecting() async {
    return super.test_nonConstValueInInitializer_redirecting();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_unary() async {
    return super.test_nonConstValueInInitializer_unary();
  }

  @override
  @failingTest
  test_nonGenerativeConstructor() async {
    return super.test_nonGenerativeConstructor();
  }

  @override
  @failingTest
  test_parameterDefaultDoesNotReferToParameterName() async {
    return super.test_parameterDefaultDoesNotReferToParameterName();
  }

  @override
  @failingTest
  test_propagateTypeArgs_intoSupertype() async {
    return super.test_propagateTypeArgs_intoSupertype();
  }

  @override
  @failingTest
  test_proxy_annotation_prefixed() async {
    return super.test_proxy_annotation_prefixed();
  }

  @override
  @failingTest
  test_proxy_annotation_prefixed2() async {
    return super.test_proxy_annotation_prefixed2();
  }

  @override
  @failingTest
  test_proxy_annotation_prefixed3() async {
    return super.test_proxy_annotation_prefixed3();
  }

  @override
  @failingTest
  test_proxy_annotation_proxyHasPrefixedIdentifier() async {
    return super.test_proxy_annotation_proxyHasPrefixedIdentifier();
  }

  @override
  @failingTest
  test_proxy_annotation_simple() async {
    return super.test_proxy_annotation_simple();
  }

  @override
  @failingTest
  test_proxy_annotation_superclass() async {
    return super.test_proxy_annotation_superclass();
  }

  @override
  @failingTest
  test_proxy_annotation_superclass_mixin() async {
    return super.test_proxy_annotation_superclass_mixin();
  }

  @override
  @failingTest
  test_proxy_annotation_superinterface() async {
    return super.test_proxy_annotation_superinterface();
  }

  @override
  @failingTest
  test_recursiveConstructorRedirect() async {
    return super.test_recursiveConstructorRedirect();
  }

  @override
  @failingTest
  test_redirectToNonConstConstructor() async {
    return super.test_redirectToNonConstConstructor();
  }

  @override
  @failingTest
  test_referenceToDeclaredVariableInInitializer_constructorName() async {
    return super
        .test_referenceToDeclaredVariableInInitializer_constructorName();
  }

  @override
  @failingTest
  test_returnOfInvalidType_dynamicAsTypeArgument() async {
    return super.test_returnOfInvalidType_dynamicAsTypeArgument();
  }

  @override
  @failingTest
  test_staticAccessToInstanceMember_annotation() async {
    return super.test_staticAccessToInstanceMember_annotation();
  }

  @override
  @failingTest
  test_undefinedConstructorInInitializer_explicit_named() async {
    return super.test_undefinedConstructorInInitializer_explicit_named();
  }

  @override
  @failingTest
  test_undefinedConstructorInInitializer_redirecting() async {
    return super.test_undefinedConstructorInInitializer_redirecting();
  }

  @override
  @failingTest
  test_undefinedGetter_static_conditionalAccess() async {
    return super.test_undefinedGetter_static_conditionalAccess();
  }

  @override
  @failingTest
  test_undefinedIdentifier_synthetic_whenExpression() async {
    return super.test_undefinedIdentifier_synthetic_whenExpression();
  }

  @override
  @failingTest
  test_undefinedIdentifier_synthetic_whenMethodName() async {
    return super.test_undefinedIdentifier_synthetic_whenMethodName();
  }

  @override
  @failingTest
  test_undefinedOperator_tilde() async {
    return super.test_undefinedOperator_tilde();
  }

  @override
  @failingTest
  test_unqualifiedReferenceToNonLocalStaticMember_fromComment_new() async {
    return super
        .test_unqualifiedReferenceToNonLocalStaticMember_fromComment_new();
  }

  @override
  @failingTest
  test_uriDoesNotExist_dll() async {
    return super.test_uriDoesNotExist_dll();
  }

  @override
  @failingTest
  test_uriDoesNotExist_dylib() async {
    return super.test_uriDoesNotExist_dylib();
  }

  @override
  @failingTest
  test_uriDoesNotExist_so() async {
    return super.test_uriDoesNotExist_so();
  }
}
