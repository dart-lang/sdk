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
  bool get useCFE => true;

  @override
  @failingTest
  test_accessPrivateEnumField() async {
    // 'package:analyzer/src/dart/analysis/library_analyzer.dart': Failed assertion: line 1082 pos 18: 'memberElement != null': is not true.
    await super.test_accessPrivateEnumField();
  }

  @override
  @failingTest
  test_annotationWithNotClass() async {
    // Bad state: No reference information for property at 117
    await super.test_annotationWithNotClass();
  }

  @override
  @failingTest
  test_annotationWithNotClass_prefixed() async {
    // Bad state: No reference information for pref at 36
    await super.test_annotationWithNotClass_prefixed();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_annotation() async {
    // 'package:analyzer/src/dart/constant/utilities.dart': Failed assertion: line 184 pos 14: 'node.parent is PartOfDirective ||
    await super.test_async_used_as_identifier_in_annotation();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_break_statement() async {
    // Bad state: No type information for true at 21
    await super.test_async_used_as_identifier_in_break_statement();
  }

  @override
  @failingTest
  test_async_used_as_identifier_in_continue_statement() async {
    // Bad state: No reference information for async at 42
    await super.test_async_used_as_identifier_in_continue_statement();
  }

  @override
  @failingTest
  test_bug_23176() async {
    // This test fails because the kernel driver element model produces a
    // different element model result than the regular parser produces. Once these
    // tests enable the faster parser (and not just the kernel driver), this
    // should be looked at again.
    return super.test_bug_23176();
  }

  @override
  @failingTest
  test_builtInIdentifierAsType_formalParameter_field() async {
    // Expected 1 errors of type CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, found 0;
    //          0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (23)
    await super.test_builtInIdentifierAsType_formalParameter_field();
  }

  @override
  @failingTest
  test_builtInIdentifierAsType_formalParameter_simple() async {
    // Expected 1 errors of type CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, found 0;
    //          0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (2)
    await super.test_builtInIdentifierAsType_formalParameter_simple();
  }

  @override
  @failingTest
  test_builtInIdentifierAsType_variableDeclaration() async {
    // Bad state: No reference information for typedef at 8
    await super.test_builtInIdentifierAsType_variableDeclaration();
  }

  @override
  @failingTest
  test_caseExpressionTypeImplementsEquals() async {
    // Expected 1 errors of type CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, found 0
    await super.test_caseExpressionTypeImplementsEquals();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_field() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, found 0
    await super.test_conflictingConstructorNameAndMember_field();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_getter() async {
    // Bad state: No type information for 42 at 25
    await super.test_conflictingConstructorNameAndMember_getter();
  }

  @override
  @failingTest
  test_conflictingConstructorNameAndMember_method() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, found 0
    await super.test_conflictingConstructorNameAndMember_method();
  }

  @override
  @failingTest
  test_conflictingGetterAndMethod_field_method() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD, found 0
    await super.test_conflictingGetterAndMethod_field_method();
  }

  @override
  @failingTest
  test_conflictingGetterAndMethod_getter_method() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD, found 0
    await super.test_conflictingGetterAndMethod_getter_method();
  }

  @override
  @failingTest
  test_conflictingGetterAndMethod_method_field() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER, found 0
    await super.test_conflictingGetterAndMethod_method_field();
  }

  @override
  @failingTest
  test_conflictingGetterAndMethod_method_getter() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER, found 0
    await super.test_conflictingGetterAndMethod_method_getter();
  }

  @override
  @failingTest
  test_conflictingTypeVariableAndClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS, found 0
    await super.test_conflictingTypeVariableAndClass();
  }

  @override
  @failingTest
  test_conflictingTypeVariableAndMember_field() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, found 0
    await super.test_conflictingTypeVariableAndMember_field();
  }

  @override
  @failingTest
  test_conflictingTypeVariableAndMember_getter() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, found 0
    await super.test_conflictingTypeVariableAndMember_getter();
  }

  @override
  @failingTest
  test_conflictingTypeVariableAndMember_method() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, found 0
    await super.test_conflictingTypeVariableAndMember_method();
  }

  @override
  @failingTest
  test_conflictingTypeVariableAndMember_method_static() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, found 0
    await super.test_conflictingTypeVariableAndMember_method_static();
  }

  @override
  @failingTest
  test_conflictingTypeVariableAndMember_setter() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, found 0
    await super.test_conflictingTypeVariableAndMember_setter();
  }

  @override
  @failingTest
  test_const_invalid_constructorFieldInitializer_fromLibrary() {
    return super.test_const_invalid_constructorFieldInitializer_fromLibrary();
  }

  @override
  @failingTest
  test_constConstructorWithFieldInitializedByNonConst() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST, found 0;
    //          1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_constConstructorWithFieldInitializedByNonConst();
  }

  @override
  @failingTest
  test_constConstructorWithMixin() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN, found 0
    await super.test_constConstructorWithMixin();
  }

  @override
  @failingTest
  test_constConstructorWithNonConstSuper_explicit() async {
    // UnimplementedError: For ShadowInvalidInitializer
    await super.test_constConstructorWithNonConstSuper_explicit();
  }

  @override
  @failingTest
  test_constConstructorWithNonConstSuper_implicit() async {
    // UnimplementedError: For ShadowInvalidInitializer
    await super.test_constConstructorWithNonConstSuper_implicit();
  }

  @override
  @failingTest
  test_constConstructorWithNonFinalField_mixin() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN, found 0;
    //          1 errors of type CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, found 0
    await super.test_constConstructorWithNonFinalField_mixin();
  }

  @override
  @failingTest
  test_constConstructorWithNonFinalField_super() async {
    // UnimplementedError: For ShadowInvalidInitializer
    await super.test_constConstructorWithNonFinalField_super();
  }

  @override
  @failingTest
  test_constConstructorWithNonFinalField_this() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, found 0
    await super.test_constConstructorWithNonFinalField_this();
  }

  @override
  @failingTest
  test_constDeferredClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_DEFERRED_CLASS, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    await super.test_constDeferredClass();
  }

  @override
  @failingTest
  test_constDeferredClass_namedConstructor() async {
    // 'package:analyzer/src/fasta/resolution_applier.dart': Failed assertion: line 632 pos 14: 'constructorName.name == null': is not true.
    await super.test_constDeferredClass_namedConstructor();
  }

  @override
  @failingTest
  test_constEval_newInstance_constConstructor() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_constEval_newInstance_constConstructor();
  }

  @override
  @failingTest
  test_constEval_nonStaticField_inGenericClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_constEval_nonStaticField_inGenericClass();
  }

  @override
  @failingTest
  test_constEval_propertyExtraction_targetNotConst() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_constEval_propertyExtraction_targetNotConst();
  }

  @override
  @failingTest
  test_constEvalThrowsException_binaryMinus_null() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t2 = null in let ...
    await super.test_constEvalThrowsException_binaryMinus_null();
  }

  @override
  @failingTest
  test_constEvalThrowsException_binaryPlus_null() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t3 = null in let ...
    await super.test_constEvalThrowsException_binaryPlus_null();
  }

  @override
  @failingTest
  test_constEvalThrowsException_divisionByZero() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE, found 0
    await super.test_constEvalThrowsException_divisionByZero();
  }

  @override
  @failingTest
  test_constEvalThrowsException_finalAlreadySet_initializer() async {
    // Bad state: No reference information for = at 41
    await super.test_constEvalThrowsException_finalAlreadySet_initializer();
  }

  @override
  @failingTest
  test_constEvalThrowsException_finalAlreadySet_initializing_formal() async {
    // UnimplementedError: For ShadowInvalidInitializer
    await super
        .test_constEvalThrowsException_finalAlreadySet_initializing_formal();
  }

  @override
  @failingTest
  test_constEvalThrowsException_unaryBitNot_null() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t4 = null in let ...
    await super.test_constEvalThrowsException_unaryBitNot_null();
  }

  @override
  @failingTest
  test_constEvalThrowsException_unaryNegated_null() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t5 = null in let ...
    await super.test_constEvalThrowsException_unaryNegated_null();
  }

  @override
  @failingTest
  test_constEvalThrowsException_unaryNot_null() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, found 0
    await super.test_constEvalThrowsException_unaryNot_null();
  }

  @override
  @failingTest
  test_constEvalTypeBool_binary() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t6 = "" in let ...
    await super.test_constEvalTypeBool_binary();
  }

  @override
  @failingTest
  test_constEvalTypeBool_binary_leftTrue() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t7 = 0 in let ...
    await super.test_constEvalTypeBool_binary_leftTrue();
  }

  @override
  @failingTest
  test_constEvalTypeBoolNumString_equal() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, found 0
    await super.test_constEvalTypeBoolNumString_equal();
  }

  @override
  @failingTest
  test_constEvalTypeBoolNumString_notEqual() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, found 0
    await super.test_constEvalTypeBoolNumString_notEqual();
  }

  @override
  @failingTest
  test_constEvalTypeInt_binary() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t8 = "" in let ...
    await super.test_constEvalTypeInt_binary();
  }

  @override
  @failingTest
  test_constEvalTypeNum_binary() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t9 = "" in let ...
    await super.test_constEvalTypeNum_binary();
  }

  @override
  @failingTest
  test_constFormalParameter_fieldFormalParameter() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_FORMAL_PARAMETER, found 0;
    //          0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (23)
    await super.test_constFormalParameter_fieldFormalParameter();
  }

  @override
  @failingTest
  test_constFormalParameter_simpleFormalParameter() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_FORMAL_PARAMETER, found 0;
    //          0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (2)
    await super.test_constFormalParameter_simpleFormalParameter();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValue() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super.test_constInitializedWithNonConstValue();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValue_finalField() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, found 0
    await super.test_constInitializedWithNonConstValue_finalField();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValue_missingConstInListLiteral() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super
        .test_constInitializedWithNonConstValue_missingConstInListLiteral();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValue_missingConstInMapLiteral() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, found 0
    await super
        .test_constInitializedWithNonConstValue_missingConstInMapLiteral();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValueFromDeferredClass() async {
    // Bad state: Expected element reference for analyzer offset 58; got one for kernel offset 60
    await super.test_constInitializedWithNonConstValueFromDeferredClass();
  }

  @override
  @failingTest
  test_constInitializedWithNonConstValueFromDeferredClass_nested() async {
    // Bad state: Expected element reference for analyzer offset 58; got one for kernel offset 60
    await super
        .test_constInitializedWithNonConstValueFromDeferredClass_nested();
  }

  @override
  @failingTest
  test_constInstanceField() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_INSTANCE_FIELD, found 0
    await super.test_constInstanceField();
  }

  @override
  @failingTest
  test_constMapKeyTypeImplementsEquals_direct() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, found 0
    await super.test_constMapKeyTypeImplementsEquals_direct();
  }

  @override
  @failingTest
  test_constMapKeyTypeImplementsEquals_dynamic() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, found 0
    await super.test_constMapKeyTypeImplementsEquals_dynamic();
  }

  @override
  @failingTest
  test_constMapKeyTypeImplementsEquals_factory() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, found 0
    await super.test_constMapKeyTypeImplementsEquals_factory();
  }

  @override
  @failingTest
  test_constMapKeyTypeImplementsEquals_super() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, found 0
    await super.test_constMapKeyTypeImplementsEquals_super();
  }

  @override
  @failingTest
  test_constWithInvalidTypeParameters() async {
    // Bad state: Found 0 argument types for 1 type arguments
    await super.test_constWithInvalidTypeParameters();
  }

  @override
  @failingTest
  test_constWithInvalidTypeParameters_tooFew() async {
    // Bad state: Found 2 argument types for 1 type arguments
    await super.test_constWithInvalidTypeParameters_tooFew();
  }

  @override
  @failingTest
  test_constWithInvalidTypeParameters_tooMany() async {
    // Bad state: Found 1 argument types for 2 type arguments
    await super.test_constWithInvalidTypeParameters_tooMany();
  }

  @override
  @failingTest
  test_constWithNonConst() async {
    // Bad state: No type information for T at 52
    await super.test_constWithNonConst();
  }

  @override
  @failingTest
  test_constWithNonConst_with() async {
    // Bad state: No type information for C at 72
    await super.test_constWithNonConst_with();
  }

  @override
  @failingTest
  test_constWithNonConstantArgument_annotation() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, found 0
    await super.test_constWithNonConstantArgument_annotation();
  }

  @override
  @failingTest
  test_constWithNonConstantArgument_instanceCreation() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, found 0;
    //          1 errors of type CompileTimeErrorCode.INVALID_CONSTANT, found 0
    await super.test_constWithNonConstantArgument_instanceCreation();
  }

  @override
  @failingTest
  test_constWithNonType() async {
    // Bad state: No type information for A at 28
    await super.test_constWithNonType();
  }

  @override
  @failingTest
  test_constWithNonType_fromLibrary() async {
    // Bad state: No type information for lib.A at 45
    await super.test_constWithNonType_fromLibrary();
  }

  @override
  @failingTest
  test_constWithUndefinedConstructor() async {
    // Bad state: No type information for A.noSuchConstructor at 46
    await super.test_constWithUndefinedConstructor();
  }

  @override
  @failingTest
  test_constWithUndefinedConstructorDefault() async {
    // Bad state: No type information for A at 51
    await super.test_constWithUndefinedConstructorDefault();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_new_named() async {
    // Bad state: (GenericTypeAliasImpl) typedef F = int Function({Map<String, String> m : const {}})
    await super.test_defaultValueInFunctionTypeAlias_new_named();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_new_positional() async {
    // Bad state: (GenericTypeAliasImpl) typedef F = int Function([Map<String, String> m = const {}])
    await super.test_defaultValueInFunctionTypeAlias_new_positional();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_old_named() async {
    // Expected 1 errors of type CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, found 0;
    //          0 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 1 (13)
    await super.test_defaultValueInFunctionTypeAlias_old_named();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypeAlias_old_positional() async {
    // Expected 1 errors of type CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, found 0;
    //          0 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 1 (13)
    await super.test_defaultValueInFunctionTypeAlias_old_positional();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypedParameter_named() async {
    // Expected 1 errors of type CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, found 0;
    //          0 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 1 (6)
    await super.test_defaultValueInFunctionTypedParameter_named();
  }

  @override
  @failingTest
  test_defaultValueInFunctionTypedParameter_optional() async {
    // Expected 1 errors of type CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, found 0;
    //          0 errors of type ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, found 1 (7)
    await super.test_defaultValueInFunctionTypedParameter_optional();
  }

  @override
  @failingTest
  test_defaultValueInRedirectingFactoryConstructor() async {
    // Expected 1 errors of type CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR, found 0
    await super.test_defaultValueInRedirectingFactoryConstructor();
  }

  @override
  @failingTest
  test_deferredImportWithInvalidUri() async {
    // Bad state: No reference information for p at 49
    await super.test_deferredImportWithInvalidUri();
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
  test_duplicateDefinition_catch() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0
    await super.test_duplicateDefinition_catch();
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
  test_duplicateDefinition_locals_inCase() async {
    // Bad state: No type information for a at 58
    await super.test_duplicateDefinition_locals_inCase();
  }

  @override
  @failingTest
  test_duplicateDefinition_locals_inFunctionBlock() async {
    // Bad state: No declaration information for m(a) {} at 24
    await super.test_duplicateDefinition_locals_inFunctionBlock();
  }

  @override
  @failingTest
  test_duplicateDefinition_locals_inIf() async {
    // Bad state: No type information for a at 49
    await super.test_duplicateDefinition_locals_inIf();
  }

  @override
  @failingTest
  test_duplicateDefinition_locals_inMethodBlock() async {
    // Bad state: No type information for a at 37
    await super.test_duplicateDefinition_locals_inMethodBlock();
  }

  @override
  @failingTest
  test_duplicateDefinition_parameters_inConstructor() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0
    await super.test_duplicateDefinition_parameters_inConstructor();
  }

  @override
  @failingTest
  test_duplicateDefinition_parameters_inFunctionTypeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0
    await super.test_duplicateDefinition_parameters_inFunctionTypeAlias();
  }

  @override
  @failingTest
  test_duplicateDefinition_parameters_inLocalFunction() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0
    await super.test_duplicateDefinition_parameters_inLocalFunction();
  }

  @override
  @failingTest
  test_duplicateDefinition_parameters_inMethod() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0
    await super.test_duplicateDefinition_parameters_inMethod();
  }

  @override
  @failingTest
  test_duplicateDefinition_parameters_inTopLevelFunction() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0
    await super.test_duplicateDefinition_parameters_inTopLevelFunction();
  }

  @override
  @failingTest
  test_duplicateDefinition_typeParameters() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0
    await super.test_duplicateDefinition_typeParameters();
  }

  @override
  @failingTest
  test_duplicateDefinitionInheritance_instanceGetter_staticGetter() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, found 0
    await super
        .test_duplicateDefinitionInheritance_instanceGetter_staticGetter();
  }

  @override
  @failingTest
  test_duplicateDefinitionInheritance_instanceGetterAbstract_staticGetter() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, found 0
    await super
        .test_duplicateDefinitionInheritance_instanceGetterAbstract_staticGetter();
  }

  @override
  @failingTest
  test_duplicateDefinitionInheritance_instanceMethod_staticMethod() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, found 0
    await super
        .test_duplicateDefinitionInheritance_instanceMethod_staticMethod();
  }

  @override
  @failingTest
  test_duplicateDefinitionInheritance_instanceMethodAbstract_staticMethod() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, found 0
    await super
        .test_duplicateDefinitionInheritance_instanceMethodAbstract_staticMethod();
  }

  @override
  @failingTest
  test_duplicateDefinitionInheritance_instanceSetter_staticSetter() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, found 0
    await super
        .test_duplicateDefinitionInheritance_instanceSetter_staticSetter();
  }

  @override
  @failingTest
  test_duplicateDefinitionInheritance_instanceSetterAbstract_staticSetter() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE, found 0
    await super
        .test_duplicateDefinitionInheritance_instanceSetterAbstract_staticSetter();
  }

  @override
  @failingTest
  test_duplicateNamedArgument() async {
    // Bad state: No type information for 1 at 29
    await super.test_duplicateNamedArgument();
  }

  @override
  @failingTest
  test_exportInternalLibrary() async {
    // Expected 1 errors of type CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY, found 0
    await super.test_exportInternalLibrary();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30960')
  test_exportOfNonLibrary() async {
    return super.test_exportOfNonLibrary();
  }

  @override
  @failingTest
  test_extendsDeferredClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    await super.test_extendsDeferredClass();
  }

  @override
  @failingTest
  test_extendsDeferredClass_classTypeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    await super.test_extendsDeferredClass_classTypeAlias();
  }

  @override
  test_extendsDisallowedClass_class_Null() async {
    await super.test_extendsDisallowedClass_class_Null();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31817')
  test_extendsDisallowedClass_classTypeAlias_Null() async {
    // Expected 1 errors of type CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, found 0
    await super.test_extendsDisallowedClass_classTypeAlias_Null();
  }

  @override
  @failingTest
  test_extendsEnum() async {
    // Expected 1 errors of type CompileTimeErrorCode.EXTENDS_ENUM, found 0
    await super.test_extendsEnum();
  }

  @override
  @failingTest
  test_extendsNonClass_class() async {
    // Expected 1 errors of type CompileTimeErrorCode.EXTENDS_NON_CLASS, found 0
    await super.test_extendsNonClass_class();
  }

  @override
  @failingTest
  test_extendsNonClass_dynamic() async {
    // Expected 1 errors of type CompileTimeErrorCode.EXTENDS_NON_CLASS, found 0
    await super.test_extendsNonClass_dynamic();
  }

  @override
  @failingTest
  test_extraPositionalArguments_const() async {
    // Bad state: No type information for A at 42
    await super.test_extraPositionalArguments_const();
  }

  @override
  @failingTest
  test_extraPositionalArguments_const_super() async {
    // Bad state: No type information for 0 at 65
    await super.test_extraPositionalArguments_const_super();
  }

  @override
  @failingTest
  test_extraPositionalArgumentsCouldBeNamed_const() async {
    // Bad state: No type information for A at 49
    await super.test_extraPositionalArgumentsCouldBeNamed_const();
  }

  @override
  @failingTest
  test_extraPositionalArgumentsCouldBeNamed_const_super() async {
    // Bad state: No type information for 0 at 72
    await super.test_extraPositionalArgumentsCouldBeNamed_const_super();
  }

  @override
  @failingTest
  test_fieldFormalParameter_assignedInInitializer() async {
    // Bad state: No reference information for = at 35
    await super.test_fieldFormalParameter_assignedInInitializer();
  }

  @override
  @failingTest
  test_fieldInitializedByMultipleInitializers() async {
    // Bad state: No reference information for = at 36
    await super.test_fieldInitializedByMultipleInitializers();
  }

  @override
  @failingTest
  test_fieldInitializedByMultipleInitializers_multipleInits() async {
    // Bad state: No reference information for = at 36
    await super.test_fieldInitializedByMultipleInitializers_multipleInits();
  }

  @override
  @failingTest
  test_fieldInitializedByMultipleInitializers_multipleNames() async {
    // Bad state: Expected element reference for analyzer offset 45; got one for kernel offset 52
    await super.test_fieldInitializedByMultipleInitializers_multipleNames();
  }

  @override
  @failingTest
  test_fieldInitializedInParameterAndInitializer() async {
    // Bad state: No reference information for = at 35
    await super.test_fieldInitializedInParameterAndInitializer();
  }

  @override
  @failingTest
  test_fieldInitializerFactoryConstructor() async {
    // Expected 1 errors of type CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, found 0
    await super.test_fieldInitializerFactoryConstructor();
  }

  @override
  @failingTest
  test_fieldInitializerOutsideConstructor() async {
    // Expected 1 errors of type ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, found 0;
    //          1 errors of type CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, found 0
    await super.test_fieldInitializerOutsideConstructor();
  }

  @override
  @failingTest
  test_fieldInitializerOutsideConstructor_defaultParameter() async {
    // Expected 1 errors of type CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, found 0
    await super.test_fieldInitializerOutsideConstructor_defaultParameter();
  }

  @override
  @failingTest
  test_fieldInitializerOutsideConstructor_inFunctionTypeParameter() async {
    // Expected 1 errors of type CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, found 0
    await super
        .test_fieldInitializerOutsideConstructor_inFunctionTypeParameter();
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
  test_finalInitializedMultipleTimes_initializers() async {
    // Bad state: No reference information for = at 38
    await super.test_finalInitializedMultipleTimes_initializers();
  }

  @override
  @failingTest
  test_finalInitializedMultipleTimes_initializingFormal_initializer() async {
    // Bad state: No reference information for = at 37
    await super
        .test_finalInitializedMultipleTimes_initializingFormal_initializer();
  }

  @override
  @failingTest
  test_finalInitializedMultipleTimes_initializingFormals() async {
    // Expected 1 errors of type CompileTimeErrorCode.DUPLICATE_DEFINITION, found 0;
    //          1 errors of type CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, found 0
    await super.test_finalInitializedMultipleTimes_initializingFormals();
  }

  @override
  @failingTest
  test_finalNotInitialized_instanceField_const_static() async {
    // Bad state: Some types were not consumed, starting at offset 26
    await super.test_finalNotInitialized_instanceField_const_static();
  }

  @override
  @failingTest
  test_finalNotInitialized_library_const() async {
    // Bad state: Some types were not consumed, starting at offset 7
    await super.test_finalNotInitialized_library_const();
  }

  @override
  @failingTest
  test_finalNotInitialized_local_const() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_NOT_INITIALIZED, found 0
    await super.test_finalNotInitialized_local_const();
  }

  @override
  @failingTest
  test_fromEnvironment_bool_badArgs() async {
    // Expected 2 errors of type CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, found 0;
    //          2 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_fromEnvironment_bool_badArgs();
  }

  @override
  @failingTest
  test_fromEnvironment_bool_badDefault_whenDefined() async {
    // Expected 1 errors of type CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, found 0;
    //          1 errors of type StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    await super.test_fromEnvironment_bool_badDefault_whenDefined();
  }

  @override
  @failingTest
  test_genericFunctionTypedParameter() async {
    // Expected 1 errors of type CompileTimeErrorCode.GENERIC_FUNCTION_TYPED_PARAM_UNSUPPORTED, found 0
    await super.test_genericFunctionTypedParameter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30857')
  test_getterAndMethodWithSameName() async {
    return super.test_getterAndMethodWithSameName();
  }

  @override
  @failingTest
  test_implementsDeferredClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    await super.test_implementsDeferredClass();
  }

  @override
  @failingTest
  test_implementsDeferredClass_classTypeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    await super.test_implementsDeferredClass_classTypeAlias();
  }

  @override
  test_implementsDisallowedClass_class_Null() async {
    await super.test_implementsDisallowedClass_class_Null();
  }

  @override
  @failingTest
  test_implementsDisallowedClass_class_String_num() async {
    await super.test_implementsDisallowedClass_class_String_num();
  }

  @override
  test_implementsDisallowedClass_classTypeAlias_Null() async {
    await super.test_implementsDisallowedClass_classTypeAlias_Null();
  }

  @override
  @failingTest
  test_implementsDisallowedClass_classTypeAlias_String_num() async {
    await super.test_implementsDisallowedClass_classTypeAlias_String_num();
  }

  @override
  @failingTest
  test_implementsDynamic() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_implementsDynamic();
  }

  @override
  @failingTest
  test_implementsEnum() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_implementsEnum();
  }

  @override
  @failingTest
  test_implementsNonClass_class() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_implementsNonClass_class();
  }

  @override
  @failingTest
  test_implementsNonClass_typeAlias() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_implementsNonClass_typeAlias();
  }

  @override
  @failingTest
  test_implementsRepeated() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLEMENTS_REPEATED, found 0
    await super.test_implementsRepeated();
  }

  @override
  @failingTest
  test_implementsRepeated_3times() async {
    // Expected 3 errors of type CompileTimeErrorCode.IMPLEMENTS_REPEATED, found 0
    await super.test_implementsRepeated_3times();
  }

  @override
  @failingTest
  test_implementsSuperClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, found 0
    await super.test_implementsSuperClass();
  }

  @override
  @failingTest
  test_implementsSuperClass_Object() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, found 0
    await super.test_implementsSuperClass_Object();
  }

  @override
  @failingTest
  test_implementsSuperClass_Object_typeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, found 0
    await super.test_implementsSuperClass_Object_typeAlias();
  }

  @override
  @failingTest
  test_implementsSuperClass_typeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, found 0
    await super.test_implementsSuperClass_typeAlias();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_field() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, found 0
    await super.test_implicitThisReferenceInInitializer_field();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_field2() async {
    // Bad state: No reference information for x at 37
    await super.test_implicitThisReferenceInInitializer_field2();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_invocation() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, found 0
    await super.test_implicitThisReferenceInInitializer_invocation();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_invocationInStatic() async {
    // Bad state: No reference information for m at 27
    await super.test_implicitThisReferenceInInitializer_invocationInStatic();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, found 0
    await super
        .test_implicitThisReferenceInInitializer_redirectingConstructorInvocation();
  }

  @override
  @failingTest
  test_implicitThisReferenceInInitializer_superConstructorInvocation() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, found 0
    await super
        .test_implicitThisReferenceInInitializer_superConstructorInvocation();
  }

  @override
  @failingTest
  test_importInternalLibrary() async {
    // Expected 1 errors of type CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, found 0
    await super.test_importInternalLibrary();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  test_importOfNonLibrary() async {
    return super.test_importOfNonLibrary();
  }

  @override
  @failingTest
  test_inconsistentCaseExpressionTypes() async {
    // Expected 1 errors of type CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, found 0
    await super.test_inconsistentCaseExpressionTypes();
  }

  @override
  @failingTest
  test_inconsistentCaseExpressionTypes_dynamic() async {
    // Expected 2 errors of type CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, found 0
    await super.test_inconsistentCaseExpressionTypes_dynamic();
  }

  @override
  @failingTest
  test_inconsistentCaseExpressionTypes_repeated() async {
    // Expected 2 errors of type CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, found 0
    await super.test_inconsistentCaseExpressionTypes_repeated();
  }

  @override
  @failingTest
  test_initializerForNonExistent_const() async {
    // Bad state: No reference information for = at 26
    await super.test_initializerForNonExistent_const();
  }

  @override
  @failingTest
  test_initializerForNonExistent_initializer() async {
    // Bad state: No reference information for = at 20
    await super.test_initializerForNonExistent_initializer();
  }

  @override
  @failingTest
  test_initializerForStaticField() async {
    // Bad state: No reference information for = at 36
    await super.test_initializerForStaticField();
  }

  @override
  @failingTest
  test_initializingFormalForNonExistentField() async {
    // Expected 1 errors of type CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, found 0
    await super.test_initializingFormalForNonExistentField();
  }

  @override
  @failingTest
  test_initializingFormalForNonExistentField_notInEnclosingClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, found 0
    await super
        .test_initializingFormalForNonExistentField_notInEnclosingClass();
  }

  @override
  @failingTest
  test_initializingFormalForNonExistentField_optional() async {
    // Expected 1 errors of type CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, found 0
    await super.test_initializingFormalForNonExistentField_optional();
  }

  @override
  @failingTest
  test_initializingFormalForNonExistentField_synthetic() async {
    // Expected 1 errors of type CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, found 0
    await super.test_initializingFormalForNonExistentField_synthetic();
  }

  @override
  @failingTest
  test_initializingFormalForStaticField() async {
    // Expected 1 errors of type CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, found 0
    await super.test_initializingFormalForStaticField();
  }

  @override
  @failingTest
  test_instanceMemberAccessFromFactory_named() async {
    // Bad state: Expected element reference for analyzer offset 51; got one for kernel offset 71
    await super.test_instanceMemberAccessFromFactory_named();
  }

  @override
  @failingTest
  test_instanceMemberAccessFromFactory_unnamed() async {
    // Bad state: Expected element reference for analyzer offset 48; got one for kernel offset 68
    await super.test_instanceMemberAccessFromFactory_unnamed();
  }

  @override
  @failingTest
  test_instanceMemberAccessFromStatic_field() async {
    // Bad state: No reference information for f at 40
    await super.test_instanceMemberAccessFromStatic_field();
  }

  @override
  @failingTest
  test_instanceMemberAccessFromStatic_getter() async {
    // Bad state: No reference information for g at 48
    await super.test_instanceMemberAccessFromStatic_getter();
  }

  @override
  @failingTest
  test_instanceMemberAccessFromStatic_method() async {
    // Bad state: No reference information for m at 40
    await super.test_instanceMemberAccessFromStatic_method();
  }

  @override
  @failingTest
  test_instantiateEnum_const() async {
    // Bad state: No type information for E at 49
    await super.test_instantiateEnum_const();
  }

  @override
  @failingTest
  test_instantiateEnum_new() async {
    // Bad state: No type information for E at 47
    await super.test_instantiateEnum_new();
  }

  @override
  @failingTest
  test_integerLiteralOutOfRange_negative() async {
    // Expected 1 errors of type CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE, found 0
    await super.test_integerLiteralOutOfRange_negative();
  }

  @override
  @failingTest
  test_integerLiteralOutOfRange_positive() async {
    // Expected 1 errors of type CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE, found 0
    await super.test_integerLiteralOutOfRange_positive();
  }

  @override
  @failingTest
  test_invalidAnnotation_getter() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_ANNOTATION, found 0
    await super.test_invalidAnnotation_getter();
  }

  @override
  @failingTest
  test_invalidAnnotation_importWithPrefix_getter() async {
    // Bad state: No reference information for V at 27
    await super.test_invalidAnnotation_importWithPrefix_getter();
  }

  @override
  @failingTest
  test_invalidAnnotation_importWithPrefix_notConstantVariable() async {
    // Bad state: No reference information for V at 27
    await super.test_invalidAnnotation_importWithPrefix_notConstantVariable();
  }

  @override
  @failingTest
  test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation() {
    return super
        .test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation();
  }

  @override
  @failingTest
  test_invalidAnnotation_notConstantVariable() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_ANNOTATION, found 0
    await super.test_invalidAnnotation_notConstantVariable();
  }

  @override
  @failingTest
  test_invalidAnnotation_notVariableOrConstructorInvocation() {
    return super.test_invalidAnnotation_notVariableOrConstructorInvocation();
  }

  @override
  @failingTest
  test_invalidAnnotation_staticMethodReference() async {
    // Bad state: Expected element reference for analyzer offset 31; got one for kernel offset 30
    await super.test_invalidAnnotation_staticMethodReference();
  }

  @override
  @failingTest
  test_invalidAnnotation_unresolved_identifier() {
    return super.test_invalidAnnotation_unresolved_identifier();
  }

  @override
  @failingTest
  test_invalidAnnotation_unresolved_invocation() async {
    // Bad state: No reference information for Unresolved at 1
    await super.test_invalidAnnotation_unresolved_invocation();
  }

  @override
  @failingTest
  test_invalidAnnotation_unresolved_prefixedIdentifier() {
    return super.test_invalidAnnotation_unresolved_prefixedIdentifier();
  }

  @override
  @failingTest
  test_invalidAnnotation_useLibraryScope() {
    return super.test_invalidAnnotation_useLibraryScope();
  }

  @override
  @failingTest
  test_invalidAnnotationFromDeferredLibrary() async {
    // Bad state: No reference information for v at 51
    await super.test_invalidAnnotationFromDeferredLibrary();
  }

  @override
  @failingTest
  test_invalidAnnotationFromDeferredLibrary_constructor() async {
    // Bad state: No reference information for C at 51
    await super.test_invalidAnnotationFromDeferredLibrary_constructor();
  }

  @override
  @failingTest
  test_invalidAnnotationFromDeferredLibrary_namedConstructor() async {
    // Bad state: No reference information for C at 51
    await super.test_invalidAnnotationFromDeferredLibrary_namedConstructor();
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
  test_invalidModifierOnConstructor_async() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, found 0
    await super.test_invalidModifierOnConstructor_async();
  }

  @override
  @failingTest
  test_invalidModifierOnConstructor_asyncStar() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, found 0
    await super.test_invalidModifierOnConstructor_asyncStar();
  }

  @override
  @failingTest
  test_invalidModifierOnConstructor_syncStar() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, found 0
    await super.test_invalidModifierOnConstructor_syncStar();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_factoryConstructor() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super.test_invalidReferenceToThis_factoryConstructor();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_instanceVariableInitializer_inConstructor() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super
        .test_invalidReferenceToThis_instanceVariableInitializer_inConstructor();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super
        .test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_staticMethod() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super.test_invalidReferenceToThis_staticMethod();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_staticVariableInitializer() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super.test_invalidReferenceToThis_staticVariableInitializer();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_superInitializer() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super.test_invalidReferenceToThis_superInitializer();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_topLevelFunction() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super.test_invalidReferenceToThis_topLevelFunction();
  }

  @override
  @failingTest
  test_invalidReferenceToThis_variableInitializer() async {
    // Expected 1 errors of type CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, found 0
    await super.test_invalidReferenceToThis_variableInitializer();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31801')
  test_invalidUri_export() async {
    return super.test_invalidUri_export();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31801')
  test_invalidUri_import() async {
    return super.test_invalidUri_import();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31801')
  test_invalidUri_part() async {
    return super.test_invalidUri_part();
  }

  @override
  @failingTest
  test_isInConstInstanceCreation_restored() async {
    // Expected 1 errors of type CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_isInConstInstanceCreation_restored();
  }

  @override
  @failingTest
  test_isInInstanceVariableInitializer_restored() async {
    // Bad state: No reference information for _foo at 89
    await super.test_isInInstanceVariableInitializer_restored();
  }

  @override
  @failingTest
  test_labelInOuterScope() async {
    // Bad state: No reference information for l at 32
    await super.test_labelInOuterScope();
  }

  @override
  @failingTest
  test_labelUndefined_break() async {
    // Bad state: No reference information for x at 8
    await super.test_labelUndefined_break();
  }

  @override
  @failingTest
  test_labelUndefined_continue() async {
    // Bad state: No reference information for x at 8
    await super.test_labelUndefined_continue();
  }

  @override
  @failingTest
  test_length_of_erroneous_constant() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t15 = 1 in let ...
    await super.test_length_of_erroneous_constant();
  }

  @override
  @failingTest
  test_memberWithClassName_field() async {
    // Expected 1 errors of type CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, found 0
    await super.test_memberWithClassName_field();
  }

  @override
  @failingTest
  test_memberWithClassName_field2() async {
    // UnimplementedError: Multiple field
    await super.test_memberWithClassName_field2();
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
  test_mixinDeclaresConstructor_classDeclaration() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR, found 0
    await super.test_mixinDeclaresConstructor_classDeclaration();
  }

  @override
  @failingTest
  test_mixinDeclaresConstructor_typeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR, found 0
    await super.test_mixinDeclaresConstructor_typeAlias();
  }

  @override
  @failingTest
  test_mixinDeferredClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_DEFERRED_CLASS, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    await super.test_mixinDeferredClass();
  }

  @override
  @failingTest
  test_mixinDeferredClass_classTypeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_DEFERRED_CLASS, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    await super.test_mixinDeferredClass_classTypeAlias();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinApp() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS, found 0
    await super.test_mixinHasNoConstructors_mixinApp();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS, found 0
    await super.test_mixinHasNoConstructors_mixinClass();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass_explicitSuperCall() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS, found 0
    await super.test_mixinHasNoConstructors_mixinClass_explicitSuperCall();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass_implicitSuperCall() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS, found 0
    await super.test_mixinHasNoConstructors_mixinClass_implicitSuperCall();
  }

  @override
  @failingTest
  test_mixinHasNoConstructors_mixinClass_namedSuperCall() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS, found 0
    await super.test_mixinHasNoConstructors_mixinClass_namedSuperCall();
  }

  @override
  @failingTest
  test_mixinInference_noMatchingClass() =>
      super.test_mixinInference_noMatchingClass();

  @override
  @failingTest
  test_mixinInference_noMatchingClass_constraintSatisfiedByImplementsClause() =>
      super
          .test_mixinInference_noMatchingClass_constraintSatisfiedByImplementsClause();

  @override
  @failingTest
  test_mixinInference_noMatchingClass_namedMixinApplication() =>
      super.test_mixinInference_noMatchingClass_namedMixinApplication();

  @override
  @failingTest
  test_mixinInheritsFromNotObject_classDeclaration_extends() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, found 0
    await super.test_mixinInheritsFromNotObject_classDeclaration_extends();
  }

  @override
  @failingTest
  test_mixinInheritsFromNotObject_classDeclaration_with() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, found 0
    await super.test_mixinInheritsFromNotObject_classDeclaration_with();
  }

  @override
  @failingTest
  test_mixinInheritsFromNotObject_typeAlias_extends() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, found 0
    await super.test_mixinInheritsFromNotObject_typeAlias_extends();
  }

  @override
  @failingTest
  test_mixinInheritsFromNotObject_typeAlias_with() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, found 0
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
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_mixinOfEnum();
  }

  @override
  @failingTest
  test_mixinOfNonClass_class() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
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
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_REFERENCES_SUPER, found 0
    await super.test_mixinReferencesSuper();
  }

  @override
  @failingTest
  test_mixinWithNonClassSuperclass_class() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS, found 0
    await super.test_mixinWithNonClassSuperclass_class();
  }

  @override
  @failingTest
  test_mixinWithNonClassSuperclass_typeAlias() async {
    // Expected 1 errors of type CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS, found 0
    await super.test_mixinWithNonClassSuperclass_typeAlias();
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
  test_nativeClauseInNonSDKCode() async {
    // Expected 1 errors of type ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, found 0
    await super.test_nativeClauseInNonSDKCode();
  }

  @override
  @failingTest
  test_nativeFunctionBodyInNonSDKCode_function() async {
    // Expected 1 errors of type ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, found 0
    await super.test_nativeFunctionBodyInNonSDKCode_function();
  }

  @override
  @failingTest
  test_nativeFunctionBodyInNonSDKCode_method() async {
    // Expected 1 errors of type ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, found 0
    await super.test_nativeFunctionBodyInNonSDKCode_method();
  }

  @override
  @failingTest
  test_noAnnotationConstructorArguments() {
    return super.test_noAnnotationConstructorArguments();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit() async {
    // Expected 1 errors of type CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, found 0
    await super.test_noDefaultSuperConstructorExplicit();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, found 0
    await super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, found 0
    await super.test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, found 0
    await super
        .test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, found 0
    await super
        .test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, found 0
    await super
        .test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinWithNamedParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, found 0
    await super.test_noDefaultSuperConstructorExplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, found 0
    await super
        .test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, found 0
    await super.test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, found 0
    await super.test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, found 0
    await super
        .test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinWithNamedParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, found 0
    await super.test_noDefaultSuperConstructorImplicit_mixinWithNamedParam();
  }

  @override
  @failingTest
  test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam() async {
    // Expected 1 errors of type CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, found 0
    await super.test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam();
  }

  @override
  @failingTest
  test_nonConstantAnnotationConstructor_named() async {
    // Bad state: No reference information for A at 30
    await super.test_nonConstantAnnotationConstructor_named();
  }

  @override
  @failingTest
  test_nonConstantAnnotationConstructor_unnamed() async {
    // Bad state: No reference information for A at 22
    await super.test_nonConstantAnnotationConstructor_unnamed();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_function_named() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, found 0
    await super.test_nonConstantDefaultValue_function_named();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_function_positional() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, found 0
    await super.test_nonConstantDefaultValue_function_positional();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_inConstructor_named() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, found 0
    await super.test_nonConstantDefaultValue_inConstructor_named();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_inConstructor_positional() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, found 0
    await super.test_nonConstantDefaultValue_inConstructor_positional();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_method_named() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, found 0
    await super.test_nonConstantDefaultValue_method_named();
  }

  @override
  @failingTest
  test_nonConstantDefaultValue_method_positional() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, found 0
    await super.test_nonConstantDefaultValue_method_positional();
  }

  @override
  @failingTest
  test_nonConstantDefaultValueFromDeferredLibrary() async {
    // Bad state: Expected element reference for analyzer offset 55; got one for kernel offset 57
    await super.test_nonConstantDefaultValueFromDeferredLibrary();
  }

  @override
  @failingTest
  test_nonConstantDefaultValueFromDeferredLibrary_nested() async {
    // Bad state: Expected element reference for analyzer offset 55; got one for kernel offset 57
    await super.test_nonConstantDefaultValueFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  test_nonConstCaseExpression() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION, found 0
    await super.test_nonConstCaseExpression();
  }

  @override
  @failingTest
  test_nonConstCaseExpressionFromDeferredLibrary() async {
    // Bad state: Expected element reference for analyzer offset 87; got one for kernel offset 89
    await super.test_nonConstCaseExpressionFromDeferredLibrary();
  }

  @override
  @failingTest
  test_nonConstCaseExpressionFromDeferredLibrary_nested() async {
    // Bad state: Expected element reference for analyzer offset 87; got one for kernel offset 89
    await super.test_nonConstCaseExpressionFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  test_nonConstListElement() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, found 0
    await super.test_nonConstListElement();
  }

  @override
  @failingTest
  test_nonConstListElementFromDeferredLibrary() async {
    // Bad state: Expected element reference for analyzer offset 70; got one for kernel offset 72
    await super.test_nonConstListElementFromDeferredLibrary();
  }

  @override
  @failingTest
  test_nonConstListElementFromDeferredLibrary_nested() async {
    // Bad state: Expected element reference for analyzer offset 70; got one for kernel offset 72
    await super.test_nonConstListElementFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  test_nonConstMapAsExpressionStatement_begin() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_nonConstMapAsExpressionStatement_begin();
  }

  @override
  @failingTest
  test_nonConstMapAsExpressionStatement_only() async {
    // Bad state: No reference information for  at 13
    await super.test_nonConstMapAsExpressionStatement_only();
  }

  @override
  @failingTest
  test_nonConstMapKey() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, found 0
    await super.test_nonConstMapKey();
  }

  @override
  @failingTest
  test_nonConstMapKeyFromDeferredLibrary() async {
    // Bad state: Expected element reference for analyzer offset 70; got one for kernel offset 72
    await super.test_nonConstMapKeyFromDeferredLibrary();
  }

  @override
  @failingTest
  test_nonConstMapKeyFromDeferredLibrary_nested() async {
    // Bad state: Expected element reference for analyzer offset 70; got one for kernel offset 72
    await super.test_nonConstMapKeyFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  test_nonConstMapValue() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, found 0
    await super.test_nonConstMapValue();
  }

  @override
  @failingTest
  test_nonConstMapValueFromDeferredLibrary() async {
    // Bad state: Expected element reference for analyzer offset 76; got one for kernel offset 78
    await super.test_nonConstMapValueFromDeferredLibrary();
  }

  @override
  @failingTest
  test_nonConstMapValueFromDeferredLibrary_nested() async {
    // Bad state: Expected element reference for analyzer offset 76; got one for kernel offset 78
    await super.test_nonConstMapValueFromDeferredLibrary_nested();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_assert_condition() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, found 0
    await super.test_nonConstValueInInitializer_assert_condition();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_assert_message() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, found 0
    await super.test_nonConstValueInInitializer_assert_message();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_notBool_left() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t17 = p in let ...
    await super.test_nonConstValueInInitializer_binary_notBool_left();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_notBool_right() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t18 = p in let ...
    await super.test_nonConstValueInInitializer_binary_notBool_right();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_notInt() async {
    // UnimplementedError: kernel: (Let) let final dynamic #t19 = p in let ...
    await super.test_nonConstValueInInitializer_binary_notInt();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_binary_notNum() async {
    // UnimplementedError: kernel: (AsExpression) 5.{dart.core::num::+}(let ...
    await super.test_nonConstValueInInitializer_binary_notNum();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_field() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, found 0
    await super.test_nonConstValueInInitializer_field();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_instanceCreation() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, found 0;
    //          1 errors of type CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, found 0
    await super.test_nonConstValueInInitializer_instanceCreation();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_instanceCreation_inDifferentFile() {
    return super
        .test_nonConstValueInInitializer_instanceCreation_inDifferentFile();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_redirecting() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, found 0
    await super.test_nonConstValueInInitializer_redirecting();
  }

  @override
  @failingTest
  test_nonConstValueInInitializer_super() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, found 0
    await super.test_nonConstValueInInitializer_super();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_field() async {
    // Bad state: Expected element reference for analyzer offset 91; got one for kernel offset 93
    await super.test_nonConstValueInInitializerFromDeferredLibrary_field();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_field_nested() async {
    // Bad state: Expected element reference for analyzer offset 91; got one for kernel offset 93
    await super
        .test_nonConstValueInInitializerFromDeferredLibrary_field_nested();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_redirecting() async {
    // Bad state: Expected element reference for analyzer offset 103; got one for kernel offset 105
    await super
        .test_nonConstValueInInitializerFromDeferredLibrary_redirecting();
  }

  @override
  @failingTest
  test_nonConstValueInInitializerFromDeferredLibrary_super() async {
    // Bad state: Expected element reference for analyzer offset 114; got one for kernel offset 116
    await super.test_nonConstValueInInitializerFromDeferredLibrary_super();
  }

  @override
  @failingTest
  test_nonGenerativeConstructor_explicit() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, found 0
    await super.test_nonGenerativeConstructor_explicit();
  }

  @override
  @failingTest
  test_nonGenerativeConstructor_implicit() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, found 0
    await super.test_nonGenerativeConstructor_implicit();
  }

  @override
  @failingTest
  test_nonGenerativeConstructor_implicit2() async {
    // Expected 1 errors of type CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, found 0
    await super.test_nonGenerativeConstructor_implicit2();
  }

  @override
  @failingTest
  test_notEnoughRequiredArguments_const() async {
    // Bad state: No type information for A at 47
    await super.test_notEnoughRequiredArguments_const();
  }

  @override
  @failingTest
  test_notEnoughRequiredArguments_const_super() async {
    // UnimplementedError: For ShadowInvalidInitializer
    await super.test_notEnoughRequiredArguments_const_super();
  }

  @override
  @failingTest
  test_optionalParameterInOperator_named() async {
    // Expected 1 errors of type CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, found 0
    await super.test_optionalParameterInOperator_named();
  }

  @override
  @failingTest
  test_optionalParameterInOperator_positional() async {
    // Expected 1 errors of type CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, found 0
    await super.test_optionalParameterInOperator_positional();
  }

  @override
  @failingTest
  test_prefix_assignment_compound_in_method() async {
    // Bad state: No reference information for p at 46
    await super.test_prefix_assignment_compound_in_method();
  }

  @override
  @failingTest
  test_prefix_assignment_compound_not_in_method() async {
    // Bad state: No reference information for p at 32
    await super.test_prefix_assignment_compound_not_in_method();
  }

  @override
  @failingTest
  test_prefix_assignment_in_method() async {
    // Bad state: No reference information for p at 46
    await super.test_prefix_assignment_in_method();
  }

  @override
  @failingTest
  test_prefix_assignment_not_in_method() async {
    // Bad state: No reference information for p at 32
    await super.test_prefix_assignment_not_in_method();
  }

  @override
  @failingTest
  test_prefix_conditionalPropertyAccess_call() async {
    // Bad state: Expected element reference for analyzer offset 32; got one for kernel offset 35
    await super.test_prefix_conditionalPropertyAccess_call();
  }

  @override
  @failingTest
  test_prefix_conditionalPropertyAccess_call_loadLibrary() async {
    // Bad state: No reference information for p at 41
    await super.test_prefix_conditionalPropertyAccess_call_loadLibrary();
  }

  @override
  @failingTest
  test_prefix_conditionalPropertyAccess_get() async {
    // Bad state: Expected element reference for analyzer offset 39; got one for kernel offset 42
    await super.test_prefix_conditionalPropertyAccess_get();
  }

  @override
  @failingTest
  @potentialAnalyzerProblem
  test_prefix_conditionalPropertyAccess_get_loadLibrary() async {
    return super.test_prefix_conditionalPropertyAccess_get_loadLibrary();
  }

  @override
  @failingTest
  test_prefix_conditionalPropertyAccess_set() async {
    // Bad state: Expected element reference for analyzer offset 32; got one for kernel offset 35
    await super.test_prefix_conditionalPropertyAccess_set();
  }

  @override
  @failingTest
  test_prefix_conditionalPropertyAccess_set_loadLibrary() async {
    // Bad state: No reference information for p at 41
    await super.test_prefix_conditionalPropertyAccess_set_loadLibrary();
  }

  @override
  @failingTest
  test_prefix_unqualified_invocation_in_method() async {
    // Bad state: No reference information for p at 46
    await super.test_prefix_unqualified_invocation_in_method();
  }

  @override
  @failingTest
  test_prefix_unqualified_invocation_not_in_method() async {
    // Bad state: No reference information for p at 32
    await super.test_prefix_unqualified_invocation_not_in_method();
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
  test_prefixNotFollowedByDot() async {
    // Bad state: No reference information for p at 39
    await super.test_prefixNotFollowedByDot();
  }

  @override
  @failingTest
  test_prefixNotFollowedByDot_compoundAssignment() async {
    // Bad state: No reference information for p at 32
    await super.test_prefixNotFollowedByDot_compoundAssignment();
  }

  @override
  @failingTest
  test_prefixNotFollowedByDot_conditionalMethodInvocation() async {
    // Bad state: Expected element reference for analyzer offset 32; got one for kernel offset 35
    await super.test_prefixNotFollowedByDot_conditionalMethodInvocation();
  }

  @override
  @failingTest
  test_privateCollisionInClassTypeAlias_mixinAndMixin() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super.test_privateCollisionInClassTypeAlias_mixinAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInClassTypeAlias_mixinAndMixin_indirect() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super.test_privateCollisionInClassTypeAlias_mixinAndMixin_indirect();
  }

  @override
  @failingTest
  test_privateCollisionInClassTypeAlias_superclassAndMixin() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super.test_privateCollisionInClassTypeAlias_superclassAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInClassTypeAlias_superclassAndMixin_same() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super.test_privateCollisionInClassTypeAlias_superclassAndMixin_same();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_mixinAndMixin() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super.test_privateCollisionInMixinApplication_mixinAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_mixinAndMixin_indirect() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super
        .test_privateCollisionInMixinApplication_mixinAndMixin_indirect();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_superclassAndMixin() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super.test_privateCollisionInMixinApplication_superclassAndMixin();
  }

  @override
  @failingTest
  test_privateCollisionInMixinApplication_superclassAndMixin_same() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, found 0
    await super
        .test_privateCollisionInMixinApplication_superclassAndMixin_same();
  }

  @override
  @failingTest
  test_privateOptionalParameter() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, found 0
    await super.test_privateOptionalParameter();
  }

  @override
  @failingTest
  test_privateOptionalParameter_fieldFormal() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, found 0
    await super.test_privateOptionalParameter_fieldFormal();
  }

  @override
  @failingTest
  test_privateOptionalParameter_withDefaultValue() async {
    // Expected 1 errors of type CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, found 0
    await super.test_privateOptionalParameter_withDefaultValue();
  }

  @override
  @failingTest
  test_recursiveCompileTimeConstant() async {
    // Expected 1 errors of type CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, found 0
    await super.test_recursiveCompileTimeConstant();
  }

  @override
  @failingTest
  test_recursiveCompileTimeConstant_cycle() async {
    // UnimplementedError: kernel: (ShadowMethodInvocation) #lib4::y.+(1)
    await super.test_recursiveCompileTimeConstant_cycle();
  }

  @override
  @failingTest
  test_recursiveCompileTimeConstant_initializer_after_toplevel_var() async {
    // Expected 1 errors of type CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, found 0
    await super
        .test_recursiveCompileTimeConstant_initializer_after_toplevel_var();
  }

  @override
  @failingTest
  test_recursiveCompileTimeConstant_singleVariable() async {
    // Expected 1 errors of type CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, found 0
    await super.test_recursiveCompileTimeConstant_singleVariable();
  }

  @override
  @failingTest
  test_recursiveConstructorRedirect() async {
    // Expected 2 errors of type CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, found 0
    await super.test_recursiveConstructorRedirect();
  }

  @override
  @failingTest
  test_recursiveConstructorRedirect_directSelfReference() async {
    // Expected 1 errors of type CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, found 0
    await super.test_recursiveConstructorRedirect_directSelfReference();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveFactoryRedirect();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_directSelfReference() async {
    // Expected 1 errors of type CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, found 0
    await super.test_recursiveFactoryRedirect_directSelfReference();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_diverging() async {
    // Bad state: Attempting to apply a non-parameterized type (TypeParameterTypeImpl) to type arguments
    await super.test_recursiveFactoryRedirect_diverging();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_generic() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveFactoryRedirect_generic();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_named() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveFactoryRedirect_named();
  }

  @override
  @failingTest
  test_recursiveFactoryRedirect_outsideCycle() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveFactoryRedirect_outsideCycle();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_extends() async {
    // Expected 2 errors of type CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, found 0
    await super.test_recursiveInterfaceInheritance_extends();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_extends_implements() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveInterfaceInheritance_extends_implements();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_implements() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
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
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveInterfaceInheritance_mixin_superclass();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_tail() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveInterfaceInheritance_tail();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_tail2() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveInterfaceInheritance_tail2();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritance_tail3() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveInterfaceInheritance_tail3();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseExtends() async {
    // Expected 1 errors of type CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS, found 0
    await super.test_recursiveInterfaceInheritanceBaseCaseExtends();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseExtends_abstract() async {
    // Expected 1 errors of type CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS, found 0;
    //          1 errors of type StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, found 0;
    //          1 errors of type StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE, found 0
    await super.test_recursiveInterfaceInheritanceBaseCaseExtends_abstract();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseImplements() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_recursiveInterfaceInheritanceBaseCaseImplements();
  }

  @override
  @failingTest
  test_recursiveInterfaceInheritanceBaseCaseImplements_typeAlias() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
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
    // Bad state: No reference information for noSuchConstructor at 23
    await super.test_redirectGenerativeToMissingConstructor();
  }

  @override
  @failingTest
  test_redirectGenerativeToNonGenerativeConstructor() async {
    // Bad state: No reference information for x at 23
    await super.test_redirectGenerativeToNonGenerativeConstructor();
  }

  @override
  @failingTest
  test_redirectToMissingConstructor_named() async {
    // NoSuchMethodError: The getter 'returnType' was called on null.
    await super.test_redirectToMissingConstructor_named();
  }

  @override
  @failingTest
  test_redirectToMissingConstructor_unnamed() async {
    // NoSuchMethodError: The getter 'returnType' was called on null.
    await super.test_redirectToMissingConstructor_unnamed();
  }

  @override
  @failingTest
  test_redirectToNonClass_notAType() async {
    // NoSuchMethodError: The getter 'returnType' was called on null.
    await super.test_redirectToNonClass_notAType();
  }

  @override
  @failingTest
  test_redirectToNonClass_undefinedIdentifier() async {
    // NoSuchMethodError: The getter 'returnType' was called on null.
    await super.test_redirectToNonClass_undefinedIdentifier();
  }

  @override
  @failingTest
  test_redirectToNonConstConstructor() async {
    // Expected 1 errors of type CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR, found 0
    await super.test_redirectToNonConstConstructor();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_hideInBlock_function() async {
    // Bad state: No declaration information for v() {} at 34
    await super.test_referencedBeforeDeclaration_hideInBlock_function();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_hideInBlock_local() async {
    // Bad state: No type information for v at 38
    await super.test_referencedBeforeDeclaration_hideInBlock_local();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_hideInBlock_subBlock() async {
    // Bad state: No type information for v at 48
    await super.test_referencedBeforeDeclaration_hideInBlock_subBlock();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_inInitializer_closure() async {
    // Bad state: No type information for v at 15
    await super.test_referencedBeforeDeclaration_inInitializer_closure();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_inInitializer_directly() async {
    // Bad state: No type information for v at 15
    await super.test_referencedBeforeDeclaration_inInitializer_directly();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_type_localFunction() async {
    // Bad state: No declaration information for int String(int x) => x + 1; at 40
    await super.test_referencedBeforeDeclaration_type_localFunction();
  }

  @override
  @failingTest
  test_referencedBeforeDeclaration_type_localVariable() async {
    // Bad state: No type information for String at 44
    await super.test_referencedBeforeDeclaration_type_localVariable();
  }

  @override
  @failingTest
  test_rethrowOutsideCatch() async {
    // Bad state: No type information for rethrow at 8
    await super.test_rethrowOutsideCatch();
  }

  @override
  @failingTest
  test_returnInGenerativeConstructor() async {
    // Bad state: No type information for 0 at 25
    await super.test_returnInGenerativeConstructor();
  }

  @override
  @failingTest
  test_returnInGenerativeConstructor_expressionFunctionBody() async {
    // Bad state: No type information for null at 19
    await super.test_returnInGenerativeConstructor_expressionFunctionBody();
  }

  @override
  @failingTest
  test_returnInGenerator_asyncStar() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_returnInGenerator_asyncStar();
  }

  @override
  @failingTest
  test_returnInGenerator_syncStar() async {
    // AnalysisException: Element mismatch in /test.dart at /test.dart
    await super.test_returnInGenerator_syncStar();
  }

  @override
  @failingTest
  test_sharedDeferredPrefix() async {
    // Bad state: Expected element reference for analyzer offset 86; got one for kernel offset 90
    await super.test_sharedDeferredPrefix();
  }

  @override
  @failingTest
  test_superInInvalidContext_binaryExpression() async {
    // Expected 1 errors of type CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, found 0
    await super.test_superInInvalidContext_binaryExpression();
  }

  @override
  @failingTest
  test_superInInvalidContext_constructorFieldInitializer() async {
    // Expected 1 errors of type CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, found 0
    await super.test_superInInvalidContext_constructorFieldInitializer();
  }

  @override
  @failingTest
  test_superInInvalidContext_factoryConstructor() async {
    // Bad state: No reference information for m at 67
    await super.test_superInInvalidContext_factoryConstructor();
  }

  @override
  @failingTest
  test_superInInvalidContext_instanceVariableInitializer() async {
    // Expected 1 errors of type CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, found 0
    await super.test_superInInvalidContext_instanceVariableInitializer();
  }

  @override
  @failingTest
  test_superInInvalidContext_staticMethod() async {
    // Bad state: No reference information for m at 76
    await super.test_superInInvalidContext_staticMethod();
  }

  @override
  @failingTest
  test_superInInvalidContext_staticVariableInitializer() async {
    // Bad state: No reference information for a at 75
    await super.test_superInInvalidContext_staticVariableInitializer();
  }

  @override
  @failingTest
  test_superInInvalidContext_topLevelFunction() async {
    // Bad state: No reference information for f at 14
    await super.test_superInInvalidContext_topLevelFunction();
  }

  @override
  @failingTest
  test_superInInvalidContext_topLevelVariableInitializer() async {
    // Bad state: No reference information for y at 14
    await super.test_superInInvalidContext_topLevelVariableInitializer();
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
  test_symbol_constructor_badArgs() async {
    // Bad state: No type information for Symbol at 69
    await super.test_symbol_constructor_badArgs();
  }

  @override
  @failingTest
  test_test_fieldInitializerOutsideConstructor_topLevelFunction() async {
    // Expected 1 errors of type ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, found 0;
    //          1 errors of type CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, found 0
    await super.test_test_fieldInitializerOutsideConstructor_topLevelFunction();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_11987() async {
    return super.test_typeAliasCannotReferenceItself_11987();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_functionTypedParameter_returnType() async {
    // Expected 1 errors of type CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, found 0
    await super
        .test_typeAliasCannotReferenceItself_functionTypedParameter_returnType();
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
  test_typeAliasCannotReferenceItself_returnType() async {
    // Expected 1 errors of type CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, found 0
    await super.test_typeAliasCannotReferenceItself_returnType();
  }

  @override
  @failingTest
  test_typeAliasCannotReferenceItself_returnType_indirect() async {
    // Expected 2 errors of type CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, found 0
    await super.test_typeAliasCannotReferenceItself_returnType_indirect();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31007')
  test_typeAliasCannotReferenceItself_typeVariableBounds() async {
    return super.test_typeAliasCannotReferenceItself_typeVariableBounds();
  }

  @override
  @failingTest
  test_typeArgumentNotMatchingBounds_const() async {
    // Expected 1 errors of type CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, found 0
    await super.test_typeArgumentNotMatchingBounds_const();
  }

  @override
  @failingTest
  test_undefinedClass_const() async {
    // Bad state: No type information for A at 21
    await super.test_undefinedClass_const();
  }

  @override
  @failingTest
  test_undefinedConstructorInInitializer_explicit_named() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, found 0
    await super.test_undefinedConstructorInInitializer_explicit_named();
  }

  @override
  @failingTest
  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, found 0
    await super.test_undefinedConstructorInInitializer_explicit_unnamed();
  }

  @override
  @failingTest
  test_undefinedConstructorInInitializer_implicit() async {
    // Expected 1 errors of type CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, found 0
    await super.test_undefinedConstructorInInitializer_implicit();
  }

  @override
  @failingTest
  test_undefinedNamedParameter() async {
    // Bad state: No type information for A at 42
    await super.test_undefinedNamedParameter();
  }

  @override
  @failingTest
  test_uriDoesNotExist_export() async {
    // Expected 1 errors of type CompileTimeErrorCode.URI_DOES_NOT_EXIST, found 0
    await super.test_uriDoesNotExist_export();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import() async {
    // Expected 1 errors of type CompileTimeErrorCode.URI_DOES_NOT_EXIST, found 0
    await super.test_uriDoesNotExist_import();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import_appears_after_deleting_target() async {
    // Expected 1 errors of type CompileTimeErrorCode.URI_DOES_NOT_EXIST, found 0
    await super.test_uriDoesNotExist_import_appears_after_deleting_target();
  }

  @override
  @failingTest
  test_uriDoesNotExist_import_disappears_when_fixed() async {
    // Expected 1 errors of type CompileTimeErrorCode.URI_DOES_NOT_EXIST, found 0
    await super.test_uriDoesNotExist_import_disappears_when_fixed();
  }

  @override
  @failingTest
  test_uriDoesNotExist_part() async {
    // Expected 1 errors of type CompileTimeErrorCode.URI_DOES_NOT_EXIST, found 0
    await super.test_uriDoesNotExist_part();
  }

  @override
  @failingTest
  test_uriWithInterpolation_constant() async {
    // Expected 1 errors of type StaticWarningCode.UNDEFINED_IDENTIFIER, found 0
    await super.test_uriWithInterpolation_constant();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30984')
  test_uriWithInterpolation_nonConstant() async {
    return super.test_uriWithInterpolation_nonConstant();
  }

  @override
  @failingTest
  test_wrongNumberOfParametersForOperator1() async {
    // Expected 1 errors of type CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, found 0
    await super.test_wrongNumberOfParametersForOperator1();
  }

  @override
  @failingTest
  test_wrongNumberOfParametersForOperator_minus() async {
    // Expected 1 errors of type CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS, found 0
    await super.test_wrongNumberOfParametersForOperator_minus();
  }

  @override
  @failingTest
  test_wrongNumberOfParametersForOperator_tilde() async {
    // Expected 1 errors of type CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, found 0
    await super.test_wrongNumberOfParametersForOperator_tilde();
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
