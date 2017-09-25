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
  test_async_future_int_with_return_future_int() async {
    return super.test_async_future_int_with_return_future_int();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_setter() async {
    return super.test_conflictingConstructorNameAndMember_setter();
  }

  @override
  @failingTest
  test_constConstructorWithNonConstSuper_unresolved() async {
    return super.test_constConstructorWithNonConstSuper_unresolved();
  }

  @override
  @failingTest
  test_constDeferredClass_new() async {
    return super.test_constDeferredClass_new();
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
  test_constWithUndefinedConstructor() async {
    return super.test_constWithUndefinedConstructor();
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
  test_propagateTypeArgs_intoSupertype() async {
    return super.test_propagateTypeArgs_intoSupertype();
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
  test_unqualifiedReferenceToNonLocalStaticMember_fromComment_new() async {
    return super
        .test_unqualifiedReferenceToNonLocalStaticMember_fromComment_new();
  }
}
