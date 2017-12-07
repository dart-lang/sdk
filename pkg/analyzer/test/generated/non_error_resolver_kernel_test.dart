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
  @potentialAnalyzerProblem
  test_abstractSuperMemberReference_superHasConcrete_mixinHasAbstract_method() async {
    return super
        .test_abstractSuperMemberReference_superHasConcrete_mixinHasAbstract_method();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_abstractSuperMemberReference_superHasNoSuchMethod() async {
    return super.test_abstractSuperMemberReference_superHasNoSuchMethod();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_abstractSuperMemberReference_superSuperHasConcrete_getter() async {
    return super
        .test_abstractSuperMemberReference_superSuperHasConcrete_getter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_abstractSuperMemberReference_superSuperHasConcrete_method() async {
    return super
        .test_abstractSuperMemberReference_superSuperHasConcrete_method();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_abstractSuperMemberReference_superSuperHasConcrete_setter() async {
    return super
        .test_abstractSuperMemberReference_superSuperHasConcrete_setter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_ambiguousImport_showCombinator() async {
    return super.test_ambiguousImport_showCombinator();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_argumentTypeNotAssignable_fieldFormalParameterElement_member() async {
    return super
        .test_argumentTypeNotAssignable_fieldFormalParameterElement_member();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_argumentTypeNotAssignable_invocation_typedef_generic() async {
    return super.test_argumentTypeNotAssignable_invocation_typedef_generic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_argumentTypeNotAssignable_typedef_local() async {
    return super.test_argumentTypeNotAssignable_typedef_local();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_argumentTypeNotAssignable_typedef_parameter() async {
    return super.test_argumentTypeNotAssignable_typedef_parameter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_assignability_function_expr_rettype_from_typedef_cls() async {
    return super.test_assignability_function_expr_rettype_from_typedef_cls();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_assignability_function_expr_rettype_from_typedef_typedef() async {
    return super
        .test_assignability_function_expr_rettype_from_typedef_typedef();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_assignmentToFinalNoSetter_propertyAccess() async {
    return super.test_assignmentToFinalNoSetter_propertyAccess();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_assignmentToFinals_importWithPrefix() async {
    return super.test_assignmentToFinals_importWithPrefix();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_async_expression_function_type() async {
    return super.test_async_expression_function_type();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_async_flattened() async {
    return super.test_async_flattened();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_awaitInWrongContext_async() async {
    return super.test_awaitInWrongContext_async();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_awaitInWrongContext_asyncStar() async {
    return super.test_awaitInWrongContext_asyncStar();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_bug_24539_getter() async {
    return super.test_bug_24539_getter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_bug_24539_setter() async {
    return super.test_bug_24539_setter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_caseExpressionTypeImplementsEquals() async {
    return super.test_caseExpressionTypeImplementsEquals();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_caseExpressionTypeImplementsEquals_Object() async {
    return super.test_caseExpressionTypeImplementsEquals_Object();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_class_type_alias_documentationComment() async {
    return super.test_class_type_alias_documentationComment();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeConstructor() async {
    return super.test_commentReference_beforeConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeEnum() async {
    return super.test_commentReference_beforeEnum();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeFunction_blockBody() async {
    return super.test_commentReference_beforeFunction_blockBody();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeFunction_expressionBody() async {
    return super.test_commentReference_beforeFunction_expressionBody();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeFunctionTypeAlias() async {
    return super.test_commentReference_beforeFunctionTypeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeGenericTypeAlias() async {
    return super.test_commentReference_beforeGenericTypeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeGetter() async {
    return super.test_commentReference_beforeGetter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_beforeMethod() async {
    return super.test_commentReference_beforeMethod();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_class() async {
    return super.test_commentReference_class();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_commentReference_setter() async {
    return super.test_commentReference_setter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_concreteClassWithAbstractMember_inherited() async {
    return super.test_concreteClassWithAbstractMember_inherited();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_conflictingInstanceGetterAndSuperclassMember_instance() async {
    return super.test_conflictingInstanceGetterAndSuperclassMember_instance();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_const_constructor_with_named_generic_parameter() async {
    return super.test_const_constructor_with_named_generic_parameter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_const_dynamic() async {
    return super.test_const_dynamic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constConstructorWithNonConstSuper_explicit() async {
    return super.test_constConstructorWithNonConstSuper_explicit();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constConstructorWithNonConstSuper_redirectingFactory() async {
    return super.test_constConstructorWithNonConstSuper_redirectingFactory();
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
  test_constConstructorWithNonFinalField_finalInstanceVar() async {
    return super.test_constConstructorWithNonFinalField_finalInstanceVar();
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
  test_constConstructorWithNonFinalField_static() async {
    return super.test_constConstructorWithNonFinalField_static();
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
  test_constEval_functionTypeLiteral() async {
    return super.test_constEval_functionTypeLiteral();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constEval_propertyExtraction_fieldStatic_targetType() async {
    return super.test_constEval_propertyExtraction_fieldStatic_targetType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constEval_propertyExtraction_methodStatic_targetType() async {
    return super.test_constEval_propertyExtraction_methodStatic_targetType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constEvelTypeNum_String() async {
    return super.test_constEvelTypeNum_String();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constMapKeyExpressionTypeImplementsEquals_abstract() async {
    return super.test_constMapKeyExpressionTypeImplementsEquals_abstract();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constNotInitialized_field() async {
    return super.test_constNotInitialized_field();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_constRedirectSkipsSupertype() async {
    return super.test_constRedirectSkipsSupertype();
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
  test_defaultValueInFunctionTypeAlias() async {
    return super.test_defaultValueInFunctionTypeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_deprecatedMemberUse_hide() async {
    return super.test_deprecatedMemberUse_hide();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_duplicateDefinition_emptyName() async {
    return super.test_duplicateDefinition_emptyName();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_dynamicIdentifier() async {
    return super.test_dynamicIdentifier();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_expectedTwoMapTypeArguments() async {
    return super.test_expectedTwoMapTypeArguments();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_extraPositionalArguments_implicitConstructor() async {
    return super.test_extraPositionalArguments_implicitConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_extraPositionalArguments_typedef_local() async {
    return super.test_extraPositionalArguments_typedef_local();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_extraPositionalArguments_typedef_parameter() async {
    return super.test_extraPositionalArguments_typedef_parameter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldFormalParameter_functionTyped_named() async {
    return super.test_fieldFormalParameter_functionTyped_named();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldFormalParameter_genericFunctionTyped() async {
    return super.test_fieldFormalParameter_genericFunctionTyped();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldFormalParameter_genericFunctionTyped_named() async {
    return super.test_fieldFormalParameter_genericFunctionTyped_named();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldInitializedByMultipleInitializers() async {
    return super.test_fieldInitializedByMultipleInitializers();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() async {
    return super
        .test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet() async {
    return super
        .test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldInitializerOutsideConstructor() async {
    return super.test_fieldInitializerOutsideConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldInitializerOutsideConstructor_defaultParameters() async {
    return super.test_fieldInitializerOutsideConstructor_defaultParameters();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_fieldInitializerRedirectingConstructor_super() async {
    return super.test_fieldInitializerRedirectingConstructor_super();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_atDeclaration() async {
    return super.test_finalNotInitialized_atDeclaration();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_fieldFormal() async {
    return super.test_finalNotInitialized_fieldFormal();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_functionTypedFieldFormal() async {
    return super.test_finalNotInitialized_functionTypedFieldFormal();
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
  test_finalNotInitialized_initializer() async {
    return super.test_finalNotInitialized_initializer();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_finalNotInitialized_redirectingConstructor() async {
    return super.test_finalNotInitialized_redirectingConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/28434')
  test_functionDeclaration_scope_signature() async {
    return super.test_functionDeclaration_scope_signature();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_functionTypeAlias_scope_returnType() async {
    return super.test_functionTypeAlias_scope_returnType();
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
  test_functionWithoutCall() async {
    return super.test_functionWithoutCall();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_functionWithoutCall_staticCallMethod() async {
    return super.test_functionWithoutCall_staticCallMethod();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_functionWithoutCall_withNoSuchMethod() async {
    return super.test_functionWithoutCall_withNoSuchMethod();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_functionWithoutCall_withNoSuchMethod_mixin() async {
    return super.test_functionWithoutCall_withNoSuchMethod_mixin();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_functionWithoutCall_withNoSuchMethod_superclass() async {
    return super.test_functionWithoutCall_withNoSuchMethod_superclass();
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
  test_implicitConstructorDependencies() async {
    return super.test_implicitConstructorDependencies();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_importOfNonLibrary_libraryDeclared() async {
    return super.test_importOfNonLibrary_libraryDeclared();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_importOfNonLibrary_libraryNotDeclared() async {
    return super.test_importOfNonLibrary_libraryNotDeclared();
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
  test_inconsistentMethodInheritance_accessors_typeParameter2() async {
    return super.test_inconsistentMethodInheritance_accessors_typeParameter2();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_inconsistentMethodInheritance_accessors_typeParameters1() async {
    return super.test_inconsistentMethodInheritance_accessors_typeParameters1();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_inconsistentMethodInheritance_accessors_typeParameters_diamond() async {
    return super
        .test_inconsistentMethodInheritance_accessors_typeParameters_diamond();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_inconsistentMethodInheritance_methods_typeParameter2() async {
    return super.test_inconsistentMethodInheritance_methods_typeParameter2();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_inconsistentMethodInheritance_methods_typeParameters1() async {
    return super.test_inconsistentMethodInheritance_methods_typeParameters1();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_inconsistentMethodInheritance_simple() async {
    return super.test_inconsistentMethodInheritance_simple();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_initializingFormalForNonExistentField() async {
    return super.test_initializingFormalForNonExistentField();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_instance_creation_inside_annotation() async {
    return super.test_instance_creation_inside_annotation();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_instanceMethodNameCollidesWithSuperclassStatic_field() async {
    return super.test_instanceMethodNameCollidesWithSuperclassStatic_field();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_instanceMethodNameCollidesWithSuperclassStatic_method() async {
    return super.test_instanceMethodNameCollidesWithSuperclassStatic_method();
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
  test_invalidAssignment_compoundAssignment() async {
    return super.test_invalidAssignment_compoundAssignment();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAssignment_implicitlyImplementFunctionViaCall_1() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_1();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAssignment_implicitlyImplementFunctionViaCall_2() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_2();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAssignment_implicitlyImplementFunctionViaCall_3() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_3();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidAssignment_implicitlyImplementFunctionViaCall_4() async {
    return super.test_invalidAssignment_implicitlyImplementFunctionViaCall_4();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidMethodOverrideNamedParamType() async {
    return super.test_invalidMethodOverrideNamedParamType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideDifferentDefaultValues_named() async {
    return super.test_invalidOverrideDifferentDefaultValues_named();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideDifferentDefaultValues_named_function() async {
    return super.test_invalidOverrideDifferentDefaultValues_named_function();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideDifferentDefaultValues_positional() async {
    return super.test_invalidOverrideDifferentDefaultValues_positional();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideDifferentDefaultValues_positional_changedOrder() async {
    return super
        .test_invalidOverrideDifferentDefaultValues_positional_changedOrder();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideDifferentDefaultValues_positional_function() async {
    return super
        .test_invalidOverrideDifferentDefaultValues_positional_function();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideNamed_unorderedNamedParameter() async {
    return super.test_invalidOverrideNamed_unorderedNamedParameter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideRequired_less() async {
    return super.test_invalidOverrideRequired_less();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideRequired_same() async {
    return super.test_invalidOverrideRequired_same();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_interface() async {
    return super.test_invalidOverrideReturnType_returnType_interface();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_interface2() async {
    return super.test_invalidOverrideReturnType_returnType_interface2();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_mixin() async {
    return super.test_invalidOverrideReturnType_returnType_mixin();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_parameterizedTypes() async {
    return super.test_invalidOverrideReturnType_returnType_parameterizedTypes();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_sameType() async {
    return super.test_invalidOverrideReturnType_returnType_sameType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_superclass() async {
    return super.test_invalidOverrideReturnType_returnType_superclass();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_superclass2() async {
    return super.test_invalidOverrideReturnType_returnType_superclass2();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidOverrideReturnType_returnType_void() async {
    return super.test_invalidOverrideReturnType_returnType_void();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invalidTypeArgumentInConstMap() async {
    return super.test_invalidTypeArgumentInConstMap();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_invocationOfNonFunction_dynamic() async {
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
  test_issue_24191() async {
    return super.test_issue_24191();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_loadLibraryDefined() async {
    return super.test_loadLibraryDefined();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mapKeyTypeNotAssignable() async {
    return super.test_mapKeyTypeNotAssignable();
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
  test_missingEnumConstantInSwitch_all() async {
    return super.test_missingEnumConstantInSwitch_all();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_missingEnumConstantInSwitch_default() async {
    return super.test_missingEnumConstantInSwitch_default();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinDeclaresConstructor() async {
    return super.test_mixinDeclaresConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinDeclaresConstructor_factory() async {
    return super.test_mixinDeclaresConstructor_factory();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinInheritsFromNotObject_classDeclaration_extends() async {
    return super.test_mixinInheritsFromNotObject_classDeclaration_extends();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinInheritsFromNotObject_classDeclaration_mixTypeAlias() async {
    return super
        .test_mixinInheritsFromNotObject_classDeclaration_mixTypeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinInheritsFromNotObject_classDeclaration_with() async {
    return super.test_mixinInheritsFromNotObject_classDeclaration_with();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinInheritsFromNotObject_typeAlias_extends() async {
    return super.test_mixinInheritsFromNotObject_typeAlias_extends();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinInheritsFromNotObject_typeAlias_with() async {
    return super.test_mixinInheritsFromNotObject_typeAlias_with();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinInheritsFromNotObject_typedef_mixTypeAlias() async {
    return super.test_mixinInheritsFromNotObject_typedef_mixTypeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_mixinReferencesSuper() async {
    return super.test_mixinReferencesSuper();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_multipleSuperInitializers_no() async {
    return super.test_multipleSuperInitializers_no();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_multipleSuperInitializers_single() async {
    return super.test_multipleSuperInitializers_single();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_newWithAbstractClass_factory() async {
    return super.test_newWithAbstractClass_factory();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_getter() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_getter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_method() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_method();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_setter() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_setter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_mixin_getter() async {
    return super.test_nonAbstractClassInheritsAbstractMemberOne_mixin_getter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_mixin_method() async {
    return super.test_nonAbstractClassInheritsAbstractMemberOne_mixin_method();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_mixin_setter() async {
    return super.test_nonAbstractClassInheritsAbstractMemberOne_mixin_setter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_accessor() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_accessor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_method() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_method();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_mixin() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_mixin();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_superclass() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_superclass();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonAbstractClassInheritsAbstractMemberOne_overridesMethodInObject() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_overridesMethodInObject();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstantDefaultValue_inConstructor_named() async {
    return super.test_nonConstantDefaultValue_inConstructor_named();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstantDefaultValue_inConstructor_positional() async {
    return super.test_nonConstantDefaultValue_inConstructor_positional();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstantDefaultValue_typedConstList() async {
    return super.test_nonConstantDefaultValue_typedConstList();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstantValueInInitializer_namedArgument() async {
    return super.test_nonConstantValueInInitializer_namedArgument();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstCaseExpression_constField() async {
    return super.test_nonConstCaseExpression_constField();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstCaseExpression_typeLiteral() async {
    return super.test_nonConstCaseExpression_typeLiteral();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstMapAsExpressionStatement_typeArguments() async {
    return super.test_nonConstMapAsExpressionStatement_typeArguments();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
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
  test_nonConstValueInInitializer_field() async {
    return super.test_nonConstValueInInitializer_field();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstValueInInitializer_redirecting() async {
    return super.test_nonConstValueInInitializer_redirecting();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonConstValueInInitializer_super() async {
    return super.test_nonConstValueInInitializer_super();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonGenerativeConstructor() async {
    return super.test_nonGenerativeConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonTypeInCatchClause_isClass() async {
    return super.test_nonTypeInCatchClause_isClass();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonTypeInCatchClause_isFunctionTypeAlias() async {
    return super.test_nonTypeInCatchClause_isFunctionTypeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonTypeInCatchClause_isTypeParameter() async {
    return super.test_nonTypeInCatchClause_isTypeParameter();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_nonTypeInCatchClause_noType() async {
    return super.test_nonTypeInCatchClause_noType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_null_callMethod() async {
    return super.test_null_callMethod();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_null_callOperator() async {
    return super.test_null_callOperator();
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
  test_propagateTypeArgs_intoBounds() async {
    return super.test_propagateTypeArgs_intoBounds();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_propagateTypeArgs_intoSupertype() async {
    return super.test_propagateTypeArgs_intoSupertype();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_recursiveConstructorRedirect() async {
    return super.test_recursiveConstructorRedirect();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_recursiveFactoryRedirect() async {
    return super.test_recursiveFactoryRedirect();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_redirectToInvalidFunctionType() async {
    return super.test_redirectToInvalidFunctionType();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_redirectToNonConstConstructor() async {
    return super.test_redirectToNonConstConstructor();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_referencedBeforeDeclaration_cascade() async {
    return super.test_referencedBeforeDeclaration_cascade();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_rethrowOutsideCatch() async {
    return super.test_rethrowOutsideCatch();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_returnOfInvalidType_dynamic() async {
    return super.test_returnOfInvalidType_dynamic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_returnOfInvalidType_subtype() async {
    return super.test_returnOfInvalidType_subtype();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_returnOfInvalidType_supertype() async {
    return super.test_returnOfInvalidType_supertype();
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
  test_reversedTypeArguments() async {
    return super.test_reversedTypeArguments();
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
  test_staticAccessToInstanceMember_method() async {
    return super.test_staticAccessToInstanceMember_method();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_superInInvalidContext() async {
    return super.test_superInInvalidContext();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeAliasCannotReferenceItself_returnClass_withTypeAlias() async {
    return super
        .test_typeAliasCannotReferenceItself_returnClass_withTypeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeArgumentNotMatchingBounds_const() async {
    return super.test_typeArgumentNotMatchingBounds_const();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeArgumentNotMatchingBounds_new() async {
    return super.test_typeArgumentNotMatchingBounds_new();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound() async {
    return super
        .test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound2() async {
    return super
        .test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound2();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_noBound() async {
    return super
        .test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_noBound();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typePromotion_conditional_issue14655() async {
    return super.test_typePromotion_conditional_issue14655();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typePromotion_functionType_arg_ignoreIfNotMoreSpecific() async {
    return super.test_typePromotion_functionType_arg_ignoreIfNotMoreSpecific();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typePromotion_functionType_return_ignoreIfNotMoreSpecific() async {
    return super
        .test_typePromotion_functionType_return_ignoreIfNotMoreSpecific();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typePromotion_functionType_return_voidToDynamic() async {
    return super.test_typePromotion_functionType_return_voidToDynamic();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typePromotion_if_extends_moreSpecific() async {
    return super.test_typePromotion_if_extends_moreSpecific();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typePromotion_if_implements_moreSpecific() async {
    return super.test_typePromotion_if_implements_moreSpecific();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typePromotion_if_is_and_subThenSuper() async {
    return super.test_typePromotion_if_is_and_subThenSuper();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_typeType_class() async {
    return super.test_typeType_class();
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
  test_typeType_functionTypeAlias() async {
    return super.test_typeType_functionTypeAlias();
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
  test_undefinedConstructorInInitializer_explicit_named() async {
    return super.test_undefinedConstructorInInitializer_explicit_named();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    return super.test_undefinedConstructorInInitializer_explicit_unnamed();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedConstructorInInitializer_hasOptionalParameters() async {
    return super.test_undefinedConstructorInInitializer_hasOptionalParameters();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedConstructorInInitializer_implicit() async {
    return super.test_undefinedConstructorInInitializer_implicit();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedConstructorInInitializer_implicit_typeAlias() async {
    return super.test_undefinedConstructorInInitializer_implicit_typeAlias();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedConstructorInInitializer_redirecting() async {
    return super.test_undefinedConstructorInInitializer_redirecting();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedGetter_static_conditionalAccess() async {
    return super.test_undefinedGetter_static_conditionalAccess();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedGetter_typeSubstitution() async {
    return super.test_undefinedGetter_typeSubstitution();
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
  test_undefinedMethod_static_conditionalAccess() async {
    return super.test_undefinedMethod_static_conditionalAccess();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedSetter_importWithPrefix() async {
    return super.test_undefinedSetter_importWithPrefix();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedSetter_static_conditionalAccess() async {
    return super.test_undefinedSetter_static_conditionalAccess();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedSuperMethod_field() async {
    return super.test_undefinedSuperMethod_field();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_undefinedSuperMethod_method() async {
    return super.test_undefinedSuperMethod_method();
  }
}
