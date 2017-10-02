// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'compile_time_error_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest_Kernel);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest_Kernel extends CompileTimeErrorCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  test_async_used_as_identifier_in_for_statement() async {
    return super.test_async_used_as_identifier_in_for_statement();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_getter_name() async {
    return super.test_async_used_as_identifier_in_getter_name();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_invocation() async {
    return super.test_async_used_as_identifier_in_invocation();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_setter_name() async {
    return super.test_async_used_as_identifier_in_setter_name();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_string_interpolation() async {
    return super.test_async_used_as_identifier_in_string_interpolation();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_suffix() async {
    return super.test_async_used_as_identifier_in_suffix();
  }

  @override
  @failingTest
  test_bug_23176() async {
    return super.test_bug_23176();
  }

  @override
  @failingTest
  test_builtInIdentifierAsType_variableDeclaration() async {
    return super.test_builtInIdentifierAsType_variableDeclaration();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_field() async {
    return super.test_conflictingConstructorNameAndMember_field();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_getter() async {
    return super.test_conflictingConstructorNameAndMember_getter();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_method() async {
    return super.test_conflictingConstructorNameAndMember_method();
  }

  @override
  @failingTest
  test_const_invalid_constructorFieldInitializer_fromLibrary() async {
    return super.test_const_invalid_constructorFieldInitializer_fromLibrary();
  }

  @override
  @failingTest
  test_constConstructor_redirect_generic() async {
    return super.test_constConstructor_redirect_generic();
  }

  @override
  @failingTest
  test_constDeferredClass_namedConstructor() async {
    return super.test_constDeferredClass_namedConstructor();
  }

  @override
  @failingTest
  test_constEval_newInstance_externalFactoryConstConstructor() async {
    return super.test_constEval_newInstance_externalFactoryConstConstructor();
  }

  @override
  @failingTest
  test_constEvalThrowsException_finalAlreadySet_initializer() async {
    return super.test_constEvalThrowsException_finalAlreadySet_initializer();
  }

  @override
  @failingTest
  test_constEvalThrowsException_finalAlreadySet_initializing_formal() async {
    return super
        .test_constEvalThrowsException_finalAlreadySet_initializing_formal();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValue_finalField() async {
    return super.test_constInitializedWithNonConstValue_finalField();
  }

  @override
  @failingTest
  test_constWithUndefinedConstructorDefault() async {
    return super.test_constWithUndefinedConstructorDefault();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias() async {
    return super.test_defaultValueInFunctionTypeAlias();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypedParameter_named() async {
    return super.test_defaultValueInFunctionTypedParameter_named();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypedParameter_optional() async {
    return super.test_defaultValueInFunctionTypedParameter_optional();
  }

  @override
  @failingTest
  test_defaultValueInRedirectingFactoryConstructor() async {
    return super.test_defaultValueInRedirectingFactoryConstructor();
  }

  @override
  @failingTest
  test_deferredImportWithInvalidUri() async {
    return super.test_deferredImportWithInvalidUri();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_duplicateConstructorName_named() async {
    return super.test_duplicateConstructorName_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_duplicateConstructorName_unnamed() async {
    return super.test_duplicateConstructorName_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_duplicateDefinition_acrossLibraries() async {
    return super.test_duplicateDefinition_acrossLibraries();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_duplicateDefinition_classMembers_fields() async {
    return super.test_duplicateDefinition_classMembers_fields();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_duplicateDefinition_classMembers_fields_oneStatic() async {
    return super.test_duplicateDefinition_classMembers_fields_oneStatic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_duplicateDefinition_classMembers_methods() async {
    return super.test_duplicateDefinition_classMembers_methods();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_duplicateDefinition_inPart() async {
    return super.test_duplicateDefinition_inPart();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30960')
  test_exportOfNonLibrary() async {
    return super.test_exportOfNonLibrary();
  }

  @override
  @failingTest
  test_fieldInitializerRedirectingConstructor_afterRedirection() async {
    return super.test_fieldInitializerRedirectingConstructor_afterRedirection();
  }

  @override
  @failingTest
  test_fieldInitializerRedirectingConstructor_beforeRedirection() async {
    return super
        .test_fieldInitializerRedirectingConstructor_beforeRedirection();
  }

  @override
  @failingTest
  test_fieldInitializingFormalRedirectingConstructor() async {
    return super.test_fieldInitializingFormalRedirectingConstructor();
  }

  @override
  @failingTest
  test_genericFunctionTypedParameter() async {
    return super.test_genericFunctionTypedParameter();
  }

  @override
  @failingTest
  test_getterAndMethodWithSameName() async {
    return super.test_getterAndMethodWithSameName();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() async {
    return super
        .test_implicitThisReferenceInInitializer_redirectingConstructorInvocation();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  test_importOfNonLibrary() async {
    return super.test_importOfNonLibrary();
  }

  @override
  @failingTest
  test_instanceMemberAccessFromFactory_named() async {
    return super.test_instanceMemberAccessFromFactory_named();
  }

  @override
  @failingTest
  test_instanceMemberAccessFromFactory_unnamed() async {
    return super.test_instanceMemberAccessFromFactory_unnamed();
  }

  @override
  @failingTest
  test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation() async {
    return super
        .test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation();
  }

  @override
  @failingTest
  test_invalidAnnotation_notVariableOrConstructorInvocation() async {
    return super.test_invalidAnnotation_notVariableOrConstructorInvocation();
  }

  @override
  @failingTest
  test_invalidAnnotationFromDeferredLibrary_namedConstructor() async {
    return super.test_invalidAnnotationFromDeferredLibrary_namedConstructor();
  }

  @override
  @failingTest
  test_invalidConstructorName_notEnclosingClassName_defined() async {
    return super.test_invalidConstructorName_notEnclosingClassName_defined();
  }

  @override
  @failingTest
  test_invalidConstructorName_notEnclosingClassName_undefined() async {
    return super.test_invalidConstructorName_notEnclosingClassName_undefined();
  }

  @override
  @failingTest
  test_invalidFactoryNameNotAClass_notClassName() async {
    return super.test_invalidFactoryNameNotAClass_notClassName();
  }

  @override
  @failingTest
  test_invalidFactoryNameNotAClass_notEnclosingClassName() async {
    return super.test_invalidFactoryNameNotAClass_notEnclosingClassName();
  }

  @override
  @failingTest
  test_invalidUri_part() async {
    return super.test_invalidUri_part();
  }

  @override
  @failingTest
  test_memberWithClassName_getter() async {
    return super.test_memberWithClassName_getter();
  }

  @override
  @failingTest
  test_methodAndGetterWithSameName() async {
    return super.test_methodAndGetterWithSameName();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass_namedSuperCall() async {
    return super.test_mixinHasNoConstructors_mixinClass_namedSuperCall();
  }

  @override
  @failingTest
  test_mixinOfNonClass_typeAlias() async {
    return super.test_mixinOfNonClass_typeAlias();
  }

  @override
  @failingTest
  test_multipleRedirectingConstructorInvocations() async {
    return super.test_multipleRedirectingConstructorInvocations();
  }

  @override
  @failingTest
  test_multipleSuperInitializers() async {
    return super.test_multipleSuperInitializers();
  }

  @override
  @failingTest
  test_noAnnotationConstructorArguments() async {
    return super.test_noAnnotationConstructorArguments();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam() async {
    return super
        .test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinWithNamedParam() async {
    return super.test_noDefaultSuperConstructorExplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam() async {
    return super
        .test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinWithNamedParam() async {
    return super.test_noDefaultSuperConstructorImplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_superOnlyNamed() async {
    return super.test_noDefaultSuperConstructorImplicit_superOnlyNamed();
  }

  @override
  @failingTest
  test_nonConstantAnnotationConstructor_named() async {
    return super.test_nonConstantAnnotationConstructor_named();
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
  test_nonConstantDefaultValueFromDeferredLibrary_nested() async {
    return super.test_nonConstantDefaultValueFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  test_nonConstMapAsExpressionStatement_begin() async {
    return super.test_nonConstMapAsExpressionStatement_begin();
  }

  @override
  @failingTest
  test_nonConstMapAsExpressionStatement_only() async {
    return super.test_nonConstMapAsExpressionStatement_only();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_instanceCreation_inDifferentFile() async {
    return super
        .test_nonConstValueInInitializer_instanceCreation_inDifferentFile();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_redirecting() async {
    return super.test_nonConstValueInInitializer_redirecting();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_redirecting() async {
    return super
        .test_nonConstValueInInitializerFromDeferredLibrary_redirecting();
  }

  @override
  @failingTest
  test_nonGenerativeConstructor_explicit() async {
    return super.test_nonGenerativeConstructor_explicit();
  }

  @override
  @failingTest
  test_partOfNonPart() async {
    return super.test_partOfNonPart();
  }

  @override
  @failingTest
  test_prefixCollidesWithTopLevelMembers_functionTypeAlias() async {
    return super.test_prefixCollidesWithTopLevelMembers_functionTypeAlias();
  }

  @override
  @failingTest
  test_prefixCollidesWithTopLevelMembers_topLevelFunction() async {
    return super.test_prefixCollidesWithTopLevelMembers_topLevelFunction();
  }

  @override
  @failingTest
  test_prefixCollidesWithTopLevelMembers_topLevelVariable() async {
    return super.test_prefixCollidesWithTopLevelMembers_topLevelVariable();
  }

  @override
  @failingTest
  test_prefixCollidesWithTopLevelMembers_type() async {
    return super.test_prefixCollidesWithTopLevelMembers_type();
  }

  @override
  @failingTest
  test_recursiveCompileTimeConstant_initializer_after_toplevel_var() async {
    return super
        .test_recursiveCompileTimeConstant_initializer_after_toplevel_var();
  }

  @override
  @failingTest
  test_recursiveConstructorRedirect() async {
    return super.test_recursiveConstructorRedirect();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_named() async {
    return super.test_recursiveFactoryRedirect_named();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_mixin() async {
    return super.test_recursiveInterfaceInheritance_mixin();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseWith() async {
    return super.test_recursiveInterfaceInheritanceBaseCaseWith();
  }

  @override
  @failingTest
  test_redirectGenerativeToNonGenerativeConstructor() async {
    return super.test_redirectGenerativeToNonGenerativeConstructor();
  }

  @override
  @failingTest
  test_redirectToMissingConstructor_unnamed() async {
    return super.test_redirectToMissingConstructor_unnamed();
  }

  @override
  @failingTest
  test_redirectToNonConstConstructor() async {
    return super.test_redirectToNonConstConstructor();
  }

  @override
  @failingTest
  test_superInRedirectingConstructor_redirectionSuper() async {
    return super.test_superInRedirectingConstructor_redirectionSuper();
  }

  @override
  @failingTest
  test_superInRedirectingConstructor_superRedirection() async {
    return super.test_superInRedirectingConstructor_superRedirection();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_11987() async {
    return super.test_typeAliasCannotReferenceItself_11987();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_generic() async {
    return super.test_typeAliasCannotReferenceItself_generic();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_parameterType_named() async {
    return super.test_typeAliasCannotReferenceItself_parameterType_named();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_parameterType_positional() async {
    return super.test_typeAliasCannotReferenceItself_parameterType_positional();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_parameterType_required() async {
    return super.test_typeAliasCannotReferenceItself_parameterType_required();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_parameterType_typeArgument() async {
    return super
        .test_typeAliasCannotReferenceItself_parameterType_typeArgument();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_typeVariableBounds() async {
    return super.test_typeAliasCannotReferenceItself_typeVariableBounds();
  }

  @override
  @failingTest
  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    return super.test_undefinedConstructorInInitializer_explicit_unnamed();
  }

  @override
  @failingTest
  test_undefinedConstructorInInitializer_implicit() async {
    return super.test_undefinedConstructorInInitializer_implicit();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import() async {
    return super.test_uriDoesNotExist_import();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import_appears_after_deleting_target() async {
    return super.test_uriDoesNotExist_import_appears_after_deleting_target();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import_disappears_when_fixed() async {
    return super.test_uriDoesNotExist_import_disappears_when_fixed();
  }

  @override
  @failingTest
  test_uriDoesNotExist_part() async {
    return super.test_uriDoesNotExist_part();
  }

  @override
  @failingTest
  test_uriWithInterpolation_constant() async {
    return super.test_uriWithInterpolation_constant();
  }

  @override
  @failingTest
  test_uriWithInterpolation_nonConstant() async {
    return super.test_uriWithInterpolation_nonConstant();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
