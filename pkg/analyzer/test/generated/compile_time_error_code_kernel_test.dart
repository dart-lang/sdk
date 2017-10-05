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

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

@reflectiveTest
class CompileTimeErrorCodeTest_Kernel extends CompileTimeErrorCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30985')
  test_bug_23176() async {
    return super.test_bug_23176();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30986')
  test_builtInIdentifierAsType_variableDeclaration() async {
    return super.test_builtInIdentifierAsType_variableDeclaration();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_conflictingConstructorNameAndMember_field() async {
    return super.test_conflictingConstructorNameAndMember_field();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_conflictingConstructorNameAndMember_getter() async {
    return super.test_conflictingConstructorNameAndMember_getter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_conflictingConstructorNameAndMember_method() async {
    return super.test_conflictingConstructorNameAndMember_method();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_constConstructor_redirect_generic() async {
    return super.test_constConstructor_redirect_generic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_constDeferredClass_namedConstructor() async {
    return super.test_constDeferredClass_namedConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_constWithUndefinedConstructorDefault() async {
    return super.test_constWithUndefinedConstructorDefault();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30997')
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
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30982')
  test_fieldInitializerRedirectingConstructor_afterRedirection() async {
    return super.test_fieldInitializerRedirectingConstructor_afterRedirection();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30982')
  test_fieldInitializerRedirectingConstructor_beforeRedirection() async {
    return super
        .test_fieldInitializerRedirectingConstructor_beforeRedirection();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30982')
  test_fieldInitializingFormalRedirectingConstructor() async {
    return super.test_fieldInitializingFormalRedirectingConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_genericFunctionTypedParameter() async {
    return super.test_genericFunctionTypedParameter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_getterAndMethodWithSameName() async {
    return super.test_getterAndMethodWithSameName();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
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
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_instanceMemberAccessFromFactory_named() async {
    return super.test_instanceMemberAccessFromFactory_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_instanceMemberAccessFromFactory_unnamed() async {
    return super.test_instanceMemberAccessFromFactory_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_invalidAnnotationFromDeferredLibrary_namedConstructor() async {
    return super.test_invalidAnnotationFromDeferredLibrary_namedConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31001')
  test_invalidConstructorName_notEnclosingClassName_defined() async {
    return super.test_invalidConstructorName_notEnclosingClassName_defined();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31001')
  test_invalidConstructorName_notEnclosingClassName_undefined() async {
    return super.test_invalidConstructorName_notEnclosingClassName_undefined();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30999')
  test_invalidFactoryNameNotAClass_notClassName() async {
    return super.test_invalidFactoryNameNotAClass_notClassName();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30999')
  test_invalidFactoryNameNotAClass_notEnclosingClassName() async {
    return super.test_invalidFactoryNameNotAClass_notEnclosingClassName();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31004')
  test_invalidUri_part() async {
    return super.test_invalidUri_part();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30981')
  test_memberWithClassName_getter() async {
    return super.test_memberWithClassName_getter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_methodAndGetterWithSameName() async {
    return super.test_methodAndGetterWithSameName();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_mixinHasNoConstructors_mixinClass_namedSuperCall() async {
    return super.test_mixinHasNoConstructors_mixinClass_namedSuperCall();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31005')
  test_mixinOfNonClass_typeAlias() async {
    return super.test_mixinOfNonClass_typeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30982')
  test_multipleRedirectingConstructorInvocations() async {
    return super.test_multipleRedirectingConstructorInvocations();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30982')
  test_multipleSuperInitializers() async {
    return super.test_multipleSuperInitializers();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam() async {
    return super
        .test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_mixinWithNamedParam() async {
    return super.test_noDefaultSuperConstructorExplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall() async {
    return super
        .test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam() async {
    return super
        .test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorImplicit_mixinWithNamedParam() async {
    return super.test_noDefaultSuperConstructorImplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam() async {
    return super
        .test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_noDefaultSuperConstructorImplicit_superOnlyNamed() async {
    return super.test_noDefaultSuperConstructorImplicit_superOnlyNamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_nonConstantAnnotationConstructor_named() async {
    return super.test_nonConstantAnnotationConstructor_named();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstantDefaultValueFromDeferredLibrary_nested() async {
    return super.test_nonConstantDefaultValueFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30983')
  test_nonConstMapAsExpressionStatement_begin() async {
    return super.test_nonConstMapAsExpressionStatement_begin();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30983')
  test_nonConstMapAsExpressionStatement_only() async {
    return super.test_nonConstMapAsExpressionStatement_only();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_nonConstValueInInitializer_redirecting() async {
    return super.test_nonConstValueInInitializer_redirecting();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_nonConstValueInInitializerFromDeferredLibrary_redirecting() async {
    return super
        .test_nonConstValueInInitializerFromDeferredLibrary_redirecting();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_nonGenerativeConstructor_explicit() async {
    return super.test_nonGenerativeConstructor_explicit();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31004')
  test_partOfNonPart() async {
    return super.test_partOfNonPart();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_prefixCollidesWithTopLevelMembers_functionTypeAlias() async {
    return super.test_prefixCollidesWithTopLevelMembers_functionTypeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_prefixCollidesWithTopLevelMembers_topLevelFunction() async {
    return super.test_prefixCollidesWithTopLevelMembers_topLevelFunction();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_prefixCollidesWithTopLevelMembers_topLevelVariable() async {
    return super.test_prefixCollidesWithTopLevelMembers_topLevelVariable();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_prefixCollidesWithTopLevelMembers_type() async {
    return super.test_prefixCollidesWithTopLevelMembers_type();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_recursiveCompileTimeConstant_initializer_after_toplevel_var() async {
    return super
        .test_recursiveCompileTimeConstant_initializer_after_toplevel_var();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_recursiveConstructorRedirect() async {
    return super.test_recursiveConstructorRedirect();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_recursiveFactoryRedirect_named() async {
    return super.test_recursiveFactoryRedirect_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_recursiveInterfaceInheritance_mixin() async {
    return super.test_recursiveInterfaceInheritance_mixin();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_recursiveInterfaceInheritanceBaseCaseWith() async {
    return super.test_recursiveInterfaceInheritanceBaseCaseWith();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_redirectGenerativeToNonGenerativeConstructor() async {
    return super.test_redirectGenerativeToNonGenerativeConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_redirectToMissingConstructor_unnamed() async {
    return super.test_redirectToMissingConstructor_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_redirectToNonConstConstructor() async {
    return super.test_redirectToNonConstConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30982')
  test_superInRedirectingConstructor_redirectionSuper() async {
    return super.test_superInRedirectingConstructor_redirectionSuper();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30982')
  test_superInRedirectingConstructor_superRedirection() async {
    return super.test_superInRedirectingConstructor_superRedirection();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_11987() async {
    return super.test_typeAliasCannotReferenceItself_11987();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_generic() async {
    return super.test_typeAliasCannotReferenceItself_generic();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_parameterType_named() async {
    return super.test_typeAliasCannotReferenceItself_parameterType_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_parameterType_positional() async {
    return super.test_typeAliasCannotReferenceItself_parameterType_positional();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_parameterType_required() async {
    return super.test_typeAliasCannotReferenceItself_parameterType_required();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_parameterType_typeArgument() async {
    return super
        .test_typeAliasCannotReferenceItself_parameterType_typeArgument();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_typeVariableBounds() async {
    return super.test_typeAliasCannotReferenceItself_typeVariableBounds();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    return super.test_undefinedConstructorInInitializer_explicit_unnamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30812')
  test_undefinedConstructorInInitializer_implicit() async {
    return super.test_undefinedConstructorInInitializer_implicit();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31004')
  test_uriDoesNotExist_part() async {
    return super.test_uriDoesNotExist_part();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30984')
  test_uriWithInterpolation_constant() async {
    return super.test_uriWithInterpolation_constant();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30984')
  test_uriWithInterpolation_nonConstant() async {
    return super.test_uriWithInterpolation_nonConstant();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
