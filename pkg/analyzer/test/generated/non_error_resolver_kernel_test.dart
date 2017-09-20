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
  test_duplicateDefinition_emptyName() async {
    return super.test_duplicateDefinition_emptyName();
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
  test_loadLibraryDefined() async {
    fail('This test fails only in checked mode.');
    return super.test_loadLibraryDefined();
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
  test_parameterDefaultDoesNotReferToParameterName() async {
    return super.test_parameterDefaultDoesNotReferToParameterName();
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
  test_returnOfInvalidType_dynamicAsTypeArgument() async {
    return super.test_returnOfInvalidType_dynamicAsTypeArgument();
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
