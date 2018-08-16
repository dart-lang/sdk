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
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  test_accessPrivateEnumField() async {
    await super.test_accessPrivateEnumField();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/12916')
  test_ambiguousExport() async {
    await super.test_ambiguousExport();
  }

  @override
  @failingTest
  test_annotationWithNotClass() async {
    await super.test_annotationWithNotClass();
  }

  @override
  @failingTest
  test_annotationWithNotClass_prefixed() async {
    await super.test_annotationWithNotClass_prefixed();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_break_statement() async {
    await super.test_async_used_as_identifier_in_break_statement();
  }

  @override // Test passes with CFE but fails with the original analyzer.
  test_conflictingConstructorNameAndMember_field() async {
    await super.test_conflictingConstructorNameAndMember_field();
  }

  @override // Test passes with CFE but fails with the original analyzer.
  test_conflictingConstructorNameAndMember_getter() async {
    await super.test_conflictingConstructorNameAndMember_getter();
  }

  @override // Test passes with CFE but fails with the original analyzer.
  test_conflictingConstructorNameAndMember_method() async {
    await super.test_conflictingConstructorNameAndMember_method();
  }

  @override
  @failingTest
  test_conflictingGenericInterfaces_hierarchyLoop() {
    return super.test_conflictingGenericInterfaces_hierarchyLoop();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33827')
  test_conflictingTypeVariableAndMember_setter() async {
    await super.test_conflictingTypeVariableAndMember_setter();
  }

  @override
  @failingTest
  test_constConstructorWithNonFinalField_super() async {
    await super.test_constConstructorWithNonFinalField_super();
  }

  @override
  @failingTest
  test_constEvalThrowsException_binaryMinus_null() async {
    await super.test_constEvalThrowsException_binaryMinus_null();
  }

  @override
  @failingTest
  test_constEvalThrowsException_binaryPlus_null() async {
    await super.test_constEvalThrowsException_binaryPlus_null();
  }

  @override
  @failingTest
  test_constEvalThrowsException_finalAlreadySet_initializer() async {
    await super.test_constEvalThrowsException_finalAlreadySet_initializer();
  }

  @override
  @failingTest
  test_constEvalThrowsException_finalAlreadySet_initializing_formal() async {
    await super
        .test_constEvalThrowsException_finalAlreadySet_initializing_formal();
  }

  @override
  @failingTest
  test_constEvalTypeBool_binary() async {
    await super.test_constEvalTypeBool_binary();
  }

  @override
  @failingTest
  test_constFormalParameter_fieldFormalParameter() async {
    await super.test_constFormalParameter_fieldFormalParameter();
  }

  @override
  @failingTest
  test_constFormalParameter_simpleFormalParameter() async {
    await super.test_constFormalParameter_simpleFormalParameter();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValueFromDeferredClass() async {
    await super.test_constInitializedWithNonConstValueFromDeferredClass();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValueFromDeferredClass_nested() async {
    await super
        .test_constInitializedWithNonConstValueFromDeferredClass_nested();
  }

  @override
  @failingTest
  test_constInstanceField() async {
    await super.test_constInstanceField();
  }

  @override
  @failingTest
  test_constWithInvalidTypeParameters() async {
    await super.test_constWithInvalidTypeParameters();
  }

  @override
  @failingTest
  test_constWithInvalidTypeParameters_tooFew() async {
    await super.test_constWithInvalidTypeParameters_tooFew();
  }

  @override
  @failingTest
  test_constWithInvalidTypeParameters_tooMany() async {
    await super.test_constWithInvalidTypeParameters_tooMany();
  }

  @override
  @failingTest
  test_constWithNonType() async {
    await super.test_constWithNonType();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_new_named() async {
    await super.test_defaultValueInFunctionTypeAlias_new_named();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_new_positional() async {
    await super.test_defaultValueInFunctionTypeAlias_new_positional();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_old_named() async {
    await super.test_defaultValueInFunctionTypeAlias_old_named();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_old_positional() async {
    await super.test_defaultValueInFunctionTypeAlias_old_positional();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypedParameter_named() async {
    await super.test_defaultValueInFunctionTypedParameter_named();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypedParameter_optional() async {
    await super.test_defaultValueInFunctionTypedParameter_optional();
  }

  @override
  @failingTest
  test_defaultValueInRedirectingFactoryConstructor() async {
    await super.test_defaultValueInRedirectingFactoryConstructor();
  }

  @override
  @failingTest
  test_deferredImportWithInvalidUri() async {
    await super.test_deferredImportWithInvalidUri();
  }

  @override
  @failingTest
  test_duplicateConstructorName_named() async {
    return super.test_duplicateConstructorName_named();
  }

  @override
  @failingTest
  test_duplicateConstructorName_unnamed() async {
    return super.test_duplicateConstructorName_unnamed();
  }

  @override
  @failingTest
  test_duplicateDefinition_acrossLibraries() async {
    return super.test_duplicateDefinition_acrossLibraries();
  }

  @override
  @failingTest
  test_duplicateDefinition_classMembers_fields() async {
    return super.test_duplicateDefinition_classMembers_fields();
  }

  @override
  @failingTest
  test_duplicateDefinition_classMembers_fields_oneStatic() async {
    return super.test_duplicateDefinition_classMembers_fields_oneStatic();
  }

  @override
  @failingTest
  test_duplicateDefinition_classMembers_methods() async {
    return super.test_duplicateDefinition_classMembers_methods();
  }

  @override
  @failingTest
  test_duplicateDefinition_inPart() async {
    return super.test_duplicateDefinition_inPart();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  test_exportOfNonLibrary() async {
    return super.test_exportOfNonLibrary();
  }

  @override
  @failingTest
  test_extendsDeferredClass() async {
    await super.test_extendsDeferredClass();
  }

  @override
  @failingTest
  test_extendsDeferredClass_classTypeAlias() async {
    await super.test_extendsDeferredClass_classTypeAlias();
  }

  @override
  test_extendsDisallowedClass_class_Null() async {
    await super.test_extendsDisallowedClass_class_Null();
  }

  @override
  @failingTest
  test_extraPositionalArguments_const_super() async {
    await super.test_extraPositionalArguments_const_super();
  }

  @override
  @failingTest
  test_extraPositionalArgumentsCouldBeNamed_const_super() async {
    await super.test_extraPositionalArgumentsCouldBeNamed_const_super();
  }

  @override
  @failingTest
  test_fieldInitializerOutsideConstructor() async {
    await super.test_fieldInitializerOutsideConstructor();
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
  test_genericFunctionTypeArgument_class() async {
    await super.test_genericFunctionTypeArgument_class();
  }

  @override
  @failingTest
  test_genericFunctionTypeArgument_function() async {
    await super.test_genericFunctionTypeArgument_function();
  }

  @override
  @failingTest
  test_genericFunctionTypeArgument_functionType() async {
    await super.test_genericFunctionTypeArgument_functionType();
  }

  @override
  @failingTest
  test_genericFunctionTypeArgument_inference_function() async {
    await super.test_genericFunctionTypeArgument_inference_function();
  }

  @override
  @failingTest
  test_genericFunctionTypeArgument_inference_functionType() async {
    await super.test_genericFunctionTypeArgument_inference_functionType();
  }

  @override
  @failingTest
  test_genericFunctionTypeArgument_inference_method() async {
    await super.test_genericFunctionTypeArgument_inference_method();
  }

  @override
  @failingTest
  test_genericFunctionTypeArgument_method() async {
    await super.test_genericFunctionTypeArgument_method();
  }

  @override
  @failingTest
  test_genericFunctionTypeAsBound_class() async {
    await super.test_genericFunctionTypeAsBound_class();
  }

  @override
  @failingTest
  test_genericFunctionTypeAsBound_genericFunction() async {
    await super.test_genericFunctionTypeAsBound_genericFunction();
  }

  @override
  @failingTest
  test_genericFunctionTypeAsBound_genericFunctionTypedef() async {
    await super.test_genericFunctionTypeAsBound_genericFunctionTypedef();
  }

  @override
  @failingTest
  test_genericFunctionTypeAsBound_parameterOfFunction() async {
    await super.test_genericFunctionTypeAsBound_parameterOfFunction();
  }

  @override
  @failingTest
  test_genericFunctionTypeAsBound_typedef() async {
    await super.test_genericFunctionTypeAsBound_typedef();
  }

  @override
  @failingTest
  test_genericFunctionTypedParameter() async {
    await super.test_genericFunctionTypedParameter();
  }

  @override
  @failingTest
  test_getterAndMethodWithSameName() async {
    return super.test_getterAndMethodWithSameName();
  }

  @override
  @failingTest
  test_implementsDeferredClass() async {
    await super.test_implementsDeferredClass();
  }

  @override
  @failingTest
  test_implementsDeferredClass_classTypeAlias() async {
    await super.test_implementsDeferredClass_classTypeAlias();
  }

  @override
  test_implementsDisallowedClass_class_Null() async {
    await super.test_implementsDisallowedClass_class_Null();
  }

  @override
  test_implementsDisallowedClass_classTypeAlias_Null() async {
    await super.test_implementsDisallowedClass_classTypeAlias_Null();
  }

  @override
  @failingTest
  test_implementsDynamic() async {
    await super.test_implementsDynamic();
  }

  @override
  @failingTest
  test_implementsEnum() async {
    await super.test_implementsEnum();
  }

  @override
  @failingTest
  test_implementsNonClass_class() async {
    await super.test_implementsNonClass_class();
  }

  @override
  @failingTest
  test_implementsNonClass_typeAlias() async {
    await super.test_implementsNonClass_typeAlias();
  }

  @override
  @failingTest
  test_implementsRepeated() async {
    await super.test_implementsRepeated();
  }

  @override
  @failingTest
  test_implementsRepeated_3times() async {
    await super.test_implementsRepeated_3times();
  }

  @override
  @failingTest
  test_implementsSuperClass() async {
    await super.test_implementsSuperClass();
  }

  @override
  @failingTest
  test_implementsSuperClass_Object() async {
    await super.test_implementsSuperClass_Object();
  }

  @override
  @failingTest
  test_implementsSuperClass_Object_typeAlias() async {
    await super.test_implementsSuperClass_Object_typeAlias();
  }

  @override
  @failingTest
  test_implementsSuperClass_typeAlias() async {
    await super.test_implementsSuperClass_typeAlias();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_field() async {
    await super.test_implicitThisReferenceInInitializer_field();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_invocation() async {
    await super.test_implicitThisReferenceInInitializer_invocation();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_invocationInStatic() async {
    await super.test_implicitThisReferenceInInitializer_invocationInStatic();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() async {
    await super
        .test_implicitThisReferenceInInitializer_redirectingConstructorInvocation();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_superConstructorInvocation() async {
    await super
        .test_implicitThisReferenceInInitializer_superConstructorInvocation();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  test_importOfNonLibrary() async {
    return super.test_importOfNonLibrary();
  }

  @override
  @failingTest
  test_initializerForNonExistent_const() async {
    await super.test_initializerForNonExistent_const();
  }

  @override
  @failingTest
  test_initializerForNonExistent_initializer() async {
    await super.test_initializerForNonExistent_initializer();
  }

  @override
  @failingTest
  test_initializerForStaticField() async {
    await super.test_initializerForStaticField();
  }

  @override
  @failingTest
  test_instantiateEnum_const() async {
    await super.test_instantiateEnum_const();
  }

  @override
  @failingTest
  test_instantiateEnum_new() async {
    await super.test_instantiateEnum_new();
  }

  @override
  @failingTest
  test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation() {
    return super
        .test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation();
  }

  @override
  @failingTest
  test_invalidAnnotation_notVariableOrConstructorInvocation() {
    return super.test_invalidAnnotation_notVariableOrConstructorInvocation();
  }

  @override
  @failingTest
  test_invalidAnnotation_staticMethodReference() async {
    await super.test_invalidAnnotation_staticMethodReference();
  }

  @override
  @failingTest
  test_invalidAnnotationFromDeferredLibrary() async {
    await super.test_invalidAnnotationFromDeferredLibrary();
  }

  @override
  @failingTest
  test_invalidAnnotationFromDeferredLibrary_constructor() async {
    await super.test_invalidAnnotationFromDeferredLibrary_constructor();
  }

  @override
  @failingTest
  test_invalidAnnotationFromDeferredLibrary_namedConstructor() async {
    await super.test_invalidAnnotationFromDeferredLibrary_namedConstructor();
  }

  @override
  @failingTest
  test_invalidAnnotationGetter_getter() async {
    await super.test_invalidAnnotationGetter_getter();
  }

  @override
  @failingTest
  test_invalidAnnotationGetter_importWithPrefix_getter() async {
    await super.test_invalidAnnotationGetter_importWithPrefix_getter();
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
  test_invalidReferenceToThis_instanceVariableInitializer_inConstructor() async {
    await super
        .test_invalidReferenceToThis_instanceVariableInitializer_inConstructor();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration() async {
    await super
        .test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_superInitializer() async {
    await super.test_invalidReferenceToThis_superInitializer();
  }

  @override
  @failingTest
  test_invalidUri_export() async {
    return super.test_invalidUri_export();
  }

  @override
  @failingTest
  test_invalidUri_import() async {
    return super.test_invalidUri_import();
  }

  @override
  @failingTest
  test_invalidUri_part() async {
    return super.test_invalidUri_part();
  }

  @override
  @failingTest
  test_isInConstInstanceCreation_restored() async {
    await super.test_isInConstInstanceCreation_restored();
  }

  @override
  @failingTest
  test_labelInOuterScope() async {
    await super.test_labelInOuterScope();
  }

  @override
  @failingTest
  test_labelUndefined_break() async {
    await super.test_labelUndefined_break();
  }

  @override
  @failingTest
  test_memberWithClassName_field() async {
    await super.test_memberWithClassName_field();
  }

  @override
  @failingTest
  test_memberWithClassName_field2() async {
    await super.test_memberWithClassName_field2();
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
  test_mixinDeferredClass() async {
    await super.test_mixinDeferredClass();
  }

  @override
  @failingTest
  test_mixinDeferredClass_classTypeAlias() async {
    await super.test_mixinDeferredClass_classTypeAlias();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinApp() async {
    await super.test_mixinHasNoConstructors_mixinApp();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass() async {
    await super.test_mixinHasNoConstructors_mixinClass();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass_explicitSuperCall() async {
    await super.test_mixinHasNoConstructors_mixinClass_explicitSuperCall();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass_implicitSuperCall() async {
    await super.test_mixinHasNoConstructors_mixinClass_implicitSuperCall();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass_namedSuperCall() async {
    await super.test_mixinHasNoConstructors_mixinClass_namedSuperCall();
  }

  @override
  @failingTest
  test_mixinInference_conflictingSubstitution() =>
      super.test_mixinInference_conflictingSubstitution();

  @override
  @failingTest
  test_mixinInference_impossibleSubstitution() =>
      super.test_mixinInference_impossibleSubstitution();

  @override
  @failingTest
  test_mixinInheritsFromNotObject_classDeclaration_extends() async {
    await super.test_mixinInheritsFromNotObject_classDeclaration_extends();
  }

  @override
  @failingTest
  test_mixinInheritsFromNotObject_classDeclaration_with() async {
    await super.test_mixinInheritsFromNotObject_classDeclaration_with();
  }

  @override
  @failingTest
  test_mixinInheritsFromNotObject_typeAlias_extends() async {
    await super.test_mixinInheritsFromNotObject_typeAlias_extends();
  }

  @override
  @failingTest
  test_mixinInheritsFromNotObject_typeAlias_with() async {
    await super.test_mixinInheritsFromNotObject_typeAlias_with();
  }

  @override
  test_mixinOfDisallowedClass_class_Null() async {
    await super.test_mixinOfDisallowedClass_class_Null();
  }

  @override
  test_mixinOfDisallowedClass_classTypeAlias_Null() async {
    await super.test_mixinOfDisallowedClass_classTypeAlias_Null();
  }

  @override
  @failingTest
  test_mixinOfEnum() async {
    await super.test_mixinOfEnum();
  }

  @override
  @failingTest
  test_mixinOfNonClass_class() async {
    await super.test_mixinOfNonClass_class();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31005')
  test_mixinOfNonClass_typeAlias() async {
    return super.test_mixinOfNonClass_typeAlias();
  }

  @override
  @failingTest
  test_mixinReferencesSuper() async {
    await super.test_mixinReferencesSuper();
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
  test_nativeClauseInNonSDKCode() async {
    await super.test_nativeClauseInNonSDKCode();
  }

  @override
  @failingTest
  test_nativeFunctionBodyInNonSDKCode_function() async {
    await super.test_nativeFunctionBodyInNonSDKCode_function();
  }

  @override
  @failingTest
  test_nativeFunctionBodyInNonSDKCode_method() async {
    await super.test_nativeFunctionBodyInNonSDKCode_method();
  }

  @override
  @failingTest
  test_noAnnotationConstructorArguments() {
    return super.test_noAnnotationConstructorArguments();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall() async {
    await super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam() async {
    await super.test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall() async {
    await super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam() async {
    await super
        .test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall() async {
    await super
        .test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinWithNamedParam() async {
    await super.test_noDefaultSuperConstructorExplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall() async {
    await super
        .test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam() async {
    await super.test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam() async {
    await super.test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam() async {
    await super
        .test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinWithNamedParam() async {
    await super.test_noDefaultSuperConstructorImplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam() async {
    await super.test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  test_nonConstantDefaultValueFromDeferredLibrary() async {
    await super.test_nonConstantDefaultValueFromDeferredLibrary();
  }

  @override
  @failingTest
  test_nonConstantDefaultValueFromDeferredLibrary_nested() async {
    await super.test_nonConstantDefaultValueFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_field() async {
    await super.test_nonConstValueInInitializerFromDeferredLibrary_field();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_field_nested() async {
    await super
        .test_nonConstValueInInitializerFromDeferredLibrary_field_nested();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_redirecting() async {
    await super
        .test_nonConstValueInInitializerFromDeferredLibrary_redirecting();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_super() async {
    await super.test_nonConstValueInInitializerFromDeferredLibrary_super();
  }

  @override
  @failingTest
  test_optionalParameterInOperator_named() async {
    await super.test_optionalParameterInOperator_named();
  }

  @override
  @failingTest
  test_optionalParameterInOperator_positional() async {
    await super.test_optionalParameterInOperator_positional();
  }

  @override
  @failingTest
  test_prefix_conditionalPropertyAccess_set() async {
    await super.test_prefix_conditionalPropertyAccess_set();
  }

  @override
  @failingTest
  test_prefix_conditionalPropertyAccess_set_loadLibrary() async {
    await super.test_prefix_conditionalPropertyAccess_set_loadLibrary();
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
  test_privateCollisionInClassTypeAlias_mixinAndMixin() async {
    await super.test_privateCollisionInClassTypeAlias_mixinAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInClassTypeAlias_mixinAndMixin_indirect() async {
    await super.test_privateCollisionInClassTypeAlias_mixinAndMixin_indirect();
  }

  @override
  @failingTest
  test_privateCollisionInClassTypeAlias_superclassAndMixin() async {
    await super.test_privateCollisionInClassTypeAlias_superclassAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInClassTypeAlias_superclassAndMixin_same() async {
    await super.test_privateCollisionInClassTypeAlias_superclassAndMixin_same();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_mixinAndMixin() async {
    await super.test_privateCollisionInMixinApplication_mixinAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_mixinAndMixin_indirect() async {
    await super
        .test_privateCollisionInMixinApplication_mixinAndMixin_indirect();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_superclassAndMixin() async {
    await super.test_privateCollisionInMixinApplication_superclassAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_superclassAndMixin_same() async {
    await super
        .test_privateCollisionInMixinApplication_superclassAndMixin_same();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect() async {
    await super.test_recursiveFactoryRedirect();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_directSelfReference() async {
    await super.test_recursiveFactoryRedirect_directSelfReference();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_generic() async {
    await super.test_recursiveFactoryRedirect_generic();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_named() async {
    await super.test_recursiveFactoryRedirect_named();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_outsideCycle() async {
    await super.test_recursiveFactoryRedirect_outsideCycle();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_extends() async {
    await super.test_recursiveInterfaceInheritance_extends();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_extends_implements() async {
    await super.test_recursiveInterfaceInheritance_extends_implements();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_implements() async {
    await super.test_recursiveInterfaceInheritance_implements();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_recursiveInterfaceInheritance_mixin() async {
    return super.test_recursiveInterfaceInheritance_mixin();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_mixin_superclass() async {
    await super.test_recursiveInterfaceInheritance_mixin_superclass();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_tail() async {
    await super.test_recursiveInterfaceInheritance_tail();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_tail2() async {
    await super.test_recursiveInterfaceInheritance_tail2();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_tail3() async {
    await super.test_recursiveInterfaceInheritance_tail3();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseExtends() async {
    await super.test_recursiveInterfaceInheritanceBaseCaseExtends();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseExtends_abstract() async {
    await super.test_recursiveInterfaceInheritanceBaseCaseExtends_abstract();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseImplements() async {
    await super.test_recursiveInterfaceInheritanceBaseCaseImplements();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseImplements_typeAlias() async {
    await super
        .test_recursiveInterfaceInheritanceBaseCaseImplements_typeAlias();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_recursiveInterfaceInheritanceBaseCaseWith() async {
    return super.test_recursiveInterfaceInheritanceBaseCaseWith();
  }

  @override
  @failingTest
  test_redirectGenerativeToMissingConstructor() async {
    await super.test_redirectGenerativeToMissingConstructor();
  }

  @override
  @failingTest
  test_redirectGenerativeToNonGenerativeConstructor() async {
    await super.test_redirectGenerativeToNonGenerativeConstructor();
  }

  @override
  @failingTest
  test_redirectToNonClass_notAType() async {
    await super.test_redirectToNonClass_notAType();
  }

  @override
  @failingTest
  test_redirectToNonClass_undefinedIdentifier() async {
    await super.test_redirectToNonClass_undefinedIdentifier();
  }

  @override
  @failingTest
  test_redirectToNonConstConstructor() async {
    await super.test_redirectToNonConstConstructor();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_inInitializer_closure() async {
    await super.test_referencedBeforeDeclaration_inInitializer_closure();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_inInitializer_directly() async {
    await super.test_referencedBeforeDeclaration_inInitializer_directly();
  }

  @override
  @failingTest
  test_returnInGenerativeConstructor() async {
    await super.test_returnInGenerativeConstructor();
  }

  @override
  @failingTest
  test_returnInGenerativeConstructor_expressionFunctionBody() async {
    await super.test_returnInGenerativeConstructor_expressionFunctionBody();
  }

  @override
  @failingTest
  test_superInInvalidContext_binaryExpression() async {
    await super.test_superInInvalidContext_binaryExpression();
  }

  @override
  @failingTest
  test_superInInvalidContext_constructorFieldInitializer() async {
    await super.test_superInInvalidContext_constructorFieldInitializer();
  }

  @override
  @failingTest
  test_superInInvalidContext_factoryConstructor() async {
    await super.test_superInInvalidContext_factoryConstructor();
  }

  @override
  @failingTest
  test_superInInvalidContext_instanceVariableInitializer() async {
    await super.test_superInInvalidContext_instanceVariableInitializer();
  }

  @override
  @failingTest
  test_superInInvalidContext_staticMethod() async {
    await super.test_superInInvalidContext_staticMethod();
  }

  @override
  @failingTest
  test_superInInvalidContext_staticVariableInitializer() async {
    await super.test_superInInvalidContext_staticVariableInitializer();
  }

  @override
  @failingTest
  test_superInInvalidContext_topLevelFunction() async {
    await super.test_superInInvalidContext_topLevelFunction();
  }

  @override
  @failingTest
  test_superInInvalidContext_topLevelVariableInitializer() async {
    await super.test_superInInvalidContext_topLevelVariableInitializer();
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
  test_typeArgumentNotMatchingBounds_const() async {
    await super.test_typeArgumentNotMatchingBounds_const();
  }

  @override
  @failingTest
  test_undefinedAnnotation_unresolved_identifier() {
    return super.test_undefinedAnnotation_unresolved_identifier();
  }

  @override
  @failingTest
  test_undefinedAnnotation_unresolved_invocation() async {
    await super.test_undefinedAnnotation_unresolved_invocation();
  }

  @override
  @failingTest
  test_undefinedAnnotation_unresolved_prefixedIdentifier() {
    return super.test_undefinedAnnotation_unresolved_prefixedIdentifier();
  }

  @override
  @failingTest
  test_undefinedAnnotation_useLibraryScope() {
    return super.test_undefinedAnnotation_useLibraryScope();
  }

  @override
  @failingTest
  test_uriDoesNotExist_export() async {
    await super.test_uriDoesNotExist_export();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import() async {
    await super.test_uriDoesNotExist_import();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import_appears_after_deleting_target() async {
    await super.test_uriDoesNotExist_import_appears_after_deleting_target();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import_disappears_when_fixed() async {
    await super.test_uriDoesNotExist_import_disappears_when_fixed();
  }

  @override
  @failingTest
  test_uriDoesNotExist_part() async {
    await super.test_uriDoesNotExist_part();
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

  @override
  @failingTest
  test_wrongNumberOfParametersForOperator_tilde() async {
    await super.test_wrongNumberOfParametersForOperator_tilde();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_function_named() async {
    return super.test_wrongNumberOfParametersForSetter_function_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_function_optional() async {
    return super.test_wrongNumberOfParametersForSetter_function_optional();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_function_tooFew() async {
    return super.test_wrongNumberOfParametersForSetter_function_tooFew();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_function_tooMany() async {
    return super.test_wrongNumberOfParametersForSetter_function_tooMany();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_method_named() async {
    return super.test_wrongNumberOfParametersForSetter_method_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_method_optional() async {
    return super.test_wrongNumberOfParametersForSetter_method_optional();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_method_tooFew() async {
    return super.test_wrongNumberOfParametersForSetter_method_tooFew();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31096')
  test_wrongNumberOfParametersForSetter_method_tooMany() async {
    return super.test_wrongNumberOfParametersForSetter_method_tooMany();
  }

  @override
  test_yieldInNonGenerator_async() async {
    // Test passes, even though if fails in the superclass
    await super.test_yieldInNonGenerator_async();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
