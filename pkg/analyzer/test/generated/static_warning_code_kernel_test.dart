// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'static_warning_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticWarningCodeTest_Kernel);
  });
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class StaticWarningCodeTest_Kernel extends StaticWarningCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @override
  bool get usingFastaParser => true;

  @override
  @failingTest
  test_ambiguousImport_as() async {
    return super.test_ambiguousImport_as();
  }

  @override
  @failingTest
  test_ambiguousImport_extends() async {
    return super.test_ambiguousImport_extends();
  }

  @override
  @failingTest
  test_ambiguousImport_implements() async {
    return super.test_ambiguousImport_implements();
  }

  @override
  @failingTest
  test_ambiguousImport_inPart() async {
    return super.test_ambiguousImport_inPart();
  }

  @override
  @failingTest
  test_ambiguousImport_instanceCreation() async {
    return super.test_ambiguousImport_instanceCreation();
  }

  @override
  @failingTest
  test_ambiguousImport_is() async {
    return super.test_ambiguousImport_is();
  }

  @override
  @failingTest
  test_ambiguousImport_qualifier() async {
    return super.test_ambiguousImport_qualifier();
  }

  @override
  @failingTest
  test_ambiguousImport_typeAnnotation() async {
    return super.test_ambiguousImport_typeAnnotation();
  }

  @override
  @failingTest
  test_ambiguousImport_typeArgument_annotation() async {
    return super.test_ambiguousImport_typeArgument_annotation();
  }

  @override
  @failingTest
  test_ambiguousImport_typeArgument_instanceCreation() async {
    return super.test_ambiguousImport_typeArgument_instanceCreation();
  }

  @override
  @failingTest
  test_ambiguousImport_varRead() async {
    return super.test_ambiguousImport_varRead();
  }

  @override
  @failingTest
  test_ambiguousImport_varWrite() async {
    return super.test_ambiguousImport_varWrite();
  }

  @override
  @failingTest
  test_ambiguousImport_withPrefix() async {
    return super.test_ambiguousImport_withPrefix();
  }

  @override
  @failingTest
  test_argumentTypeNotAssignable_const_super() async {
    return super.test_argumentTypeNotAssignable_const_super();
  }

  @override
  @failingTest
  test_assignmentToClass() async {
    return super.test_assignmentToClass();
  }

  @override
  @failingTest
  test_assignmentToConst_instanceVariable() async {
    return super.test_assignmentToConst_instanceVariable();
  }

  @override
  @failingTest
  test_assignmentToConst_instanceVariable_plusEq() async {
    return super.test_assignmentToConst_instanceVariable_plusEq();
  }

  @override
  @failingTest
  test_assignmentToConst_localVariable() async {
    return super.test_assignmentToConst_localVariable();
  }

  @override
  @failingTest
  test_assignmentToConst_localVariable_plusEq() async {
    return super.test_assignmentToConst_localVariable_plusEq();
  }

  @override
  @failingTest
  test_assignmentToEnumType() async {
    return super.test_assignmentToEnumType();
  }

  @override
  @failingTest
  test_assignmentToFinal_instanceVariable() async {
    return super.test_assignmentToFinal_instanceVariable();
  }

  @override
  @failingTest
  test_assignmentToFinal_instanceVariable_plusEq() async {
    return super.test_assignmentToFinal_instanceVariable_plusEq();
  }

  @override
  @failingTest
  test_assignmentToFinalNoSetter_prefixedIdentifier() async {
    return super.test_assignmentToFinalNoSetter_prefixedIdentifier();
  }

  @override
  @failingTest
  test_assignmentToMethod() async {
    return super.test_assignmentToMethod();
  }

  @override
  @failingTest
  test_assignmentToTypedef() async {
    return super.test_assignmentToTypedef();
  }

  @override
  @failingTest
  test_assignmentToTypeParameter() async {
    return super.test_assignmentToTypeParameter();
  }

  @override
  @failingTest
  test_castToNonType() async {
    return super.test_castToNonType();
  }

  @override
  @failingTest
  test_conflictingDartImport() async {
    return super.test_conflictingDartImport();
  }

  @override
  @failingTest
  test_conflictingInstanceGetterAndSuperclassMember_declField_direct_setter() async {
    return super
        .test_conflictingInstanceGetterAndSuperclassMember_declField_direct_setter();
  }

  @override
  @failingTest
  test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_getter() async {
    return super
        .test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_getter();
  }

  @override
  @failingTest
  test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_method() async {
    return super
        .test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_method();
  }

  @override
  @failingTest
  test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_setter() async {
    return super
        .test_conflictingInstanceGetterAndSuperclassMember_declGetter_direct_setter();
  }

  @override
  @failingTest
  test_conflictingInstanceGetterAndSuperclassMember_declGetter_indirect() async {
    return super
        .test_conflictingInstanceGetterAndSuperclassMember_declGetter_indirect();
  }

  @override
  @failingTest
  test_conflictingInstanceGetterAndSuperclassMember_declGetter_mixin() async {
    return super
        .test_conflictingInstanceGetterAndSuperclassMember_declGetter_mixin();
  }

  @override
  @failingTest
  test_conflictingInstanceGetterAndSuperclassMember_direct_field() async {
    return super
        .test_conflictingInstanceGetterAndSuperclassMember_direct_field();
  }

  @override
  @failingTest
  test_conflictingInstanceSetterAndSuperclassMember() async {
    return super.test_conflictingInstanceSetterAndSuperclassMember();
  }

  @override
  @failingTest
  test_exportDuplicatedLibraryNamed() async {
    return super.test_exportDuplicatedLibraryNamed();
  }

  @override
  @failingTest
  test_fieldInitializingFormalNotAssignable() async {
    return super.test_fieldInitializingFormalNotAssignable();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31073')
  test_finalNotInitialized_inConstructor_1() async {
    return super.test_finalNotInitialized_inConstructor_1();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31073')
  test_finalNotInitialized_inConstructor_2() async {
    return super.test_finalNotInitialized_inConstructor_2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31073')
  test_finalNotInitialized_inConstructor_3() async {
    return super.test_finalNotInitialized_inConstructor_3();
  }

  @override
  @failingTest
  test_generalizedVoid_invocationOfVoidFieldError() async {
    return super.test_generalizedVoid_invocationOfVoidFieldError();
  }

  @override
  @failingTest
  test_generalizedVoid_useOfVoidInConditionalLhsError() async {
    return super.test_generalizedVoid_useOfVoidInConditionalLhsError();
  }

  @override
  @failingTest
  test_generalizedVoid_useOfVoidInConditionalRhsError() async {
    return super.test_generalizedVoid_useOfVoidInConditionalRhsError();
  }

  @override
  @failingTest
  test_generalizedVoid_useOfVoidInForeachVariableError() async {
    return super.test_generalizedVoid_useOfVoidInForeachVariableError();
  }

  @override
  @failingTest
  test_generalizedVoid_useOfVoidReturnInNonVoidFunctionError() async {
    return super.test_generalizedVoid_useOfVoidReturnInNonVoidFunctionError();
  }

  @override
  @failingTest
  test_importDuplicatedLibraryNamed() async {
    return super.test_importDuplicatedLibraryNamed();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  test_importOfNonLibrary() async {
    return super.test_importOfNonLibrary();
  }

  @override
  @failingTest
  test_mismatchedAccessorTypes_class() async {
    return super.test_mismatchedAccessorTypes_class();
  }

  @override
  @failingTest
  test_mismatchedAccessorTypes_getterAndSuperSetter() async {
    return super.test_mismatchedAccessorTypes_getterAndSuperSetter();
  }

  @override
  @failingTest
  test_mismatchedAccessorTypes_setterAndSuperGetter() async {
    return super.test_mismatchedAccessorTypes_setterAndSuperGetter();
  }

  @override
  @failingTest
  test_mismatchedAccessorTypes_topLevel() async {
    return super.test_mismatchedAccessorTypes_topLevel();
  }

  @override
  @failingTest
  test_missingEnumConstantInSwitch() async {
    return super.test_missingEnumConstantInSwitch();
  }

  @override
  @failingTest
  test_mixedReturnTypes_localFunction() async {
    return super.test_mixedReturnTypes_localFunction();
  }

  @override
  @failingTest
  test_mixedReturnTypes_method() async {
    return super.test_mixedReturnTypes_method();
  }

  @override
  @failingTest
  test_mixedReturnTypes_topLevelFunction() async {
    return super.test_mixedReturnTypes_topLevelFunction();
  }

  @override
  @failingTest
  test_newWithInvalidTypeParameters() async {
    return super.test_newWithInvalidTypeParameters();
  }

  @override
  @failingTest
  test_newWithInvalidTypeParameters_tooFew() async {
    return super.test_newWithInvalidTypeParameters_tooFew();
  }

  @override
  @failingTest
  test_newWithInvalidTypeParameters_tooMany() async {
    return super.test_newWithInvalidTypeParameters_tooMany();
  }

  @override
  @failingTest
  test_newWithNonType() async {
    return super.test_newWithNonType();
  }

  @override
  @failingTest
  test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_ensureCorrectFunctionSubtypeIsUsedInImplementation();
  }

  @override
  @failingTest
  test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount() async {
    return super
        .test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount();
  }

  @override
  @failingTest
  test_nonTypeInCatchClause_notType() async {
    return super.test_nonTypeInCatchClause_notType();
  }

  @override
  @failingTest
  test_nonVoidReturnForOperator() async {
    return super.test_nonVoidReturnForOperator();
  }

  @override
  @failingTest
  test_nonVoidReturnForSetter_function() async {
    return super.test_nonVoidReturnForSetter_function();
  }

  @override
  @failingTest
  test_nonVoidReturnForSetter_method() async {
    return super.test_nonVoidReturnForSetter_method();
  }

  @override
  @failingTest
  test_redirectToInvalidFunctionType() async {
    return super.test_redirectToInvalidFunctionType();
  }

  @override
  @failingTest
  test_redirectToInvalidReturnType() async {
    return super.test_redirectToInvalidReturnType();
  }

  @override
  @failingTest
  test_redirectToMissingConstructor_named() async {
    return super.test_redirectToMissingConstructor_named();
  }

  @override
  @failingTest
  test_redirectToMissingConstructor_unnamed() async {
    return super.test_redirectToMissingConstructor_unnamed();
  }

  @override
  @failingTest
  test_redirectToNonClass_notAType() async {
    return super.test_redirectToNonClass_notAType();
  }

  @override
  @failingTest
  test_redirectToNonClass_undefinedIdentifier() async {
    return super.test_redirectToNonClass_undefinedIdentifier();
  }

  @override
  @failingTest
  test_returnWithoutValue_async() async {
    return super.test_returnWithoutValue_async();
  }

  @override
  @failingTest
  test_returnWithoutValue_async_future_object_with_return() {
    return super.test_returnWithoutValue_async_future_object_with_return();
  }

  @override
  @failingTest
  test_returnWithoutValue_factoryConstructor() async {
    return super.test_returnWithoutValue_factoryConstructor();
  }

  @override
  @failingTest
  test_returnWithoutValue_function() async {
    return super.test_returnWithoutValue_function();
  }

  @override
  @failingTest
  test_returnWithoutValue_method() async {
    return super.test_returnWithoutValue_method();
  }

  @override
  @failingTest
  test_returnWithoutValue_mixedReturnTypes_function() async {
    return super.test_returnWithoutValue_mixedReturnTypes_function();
  }

  @override
  @failingTest
  test_staticAccessToInstanceMember_method_reference() async {
    return super.test_staticAccessToInstanceMember_method_reference();
  }

  @override
  @failingTest
  test_staticAccessToInstanceMember_propertyAccess_field() async {
    return super.test_staticAccessToInstanceMember_propertyAccess_field();
  }

  @override
  @failingTest
  test_staticAccessToInstanceMember_propertyAccess_getter() async {
    return super.test_staticAccessToInstanceMember_propertyAccess_getter();
  }

  @override
  @failingTest
  test_staticAccessToInstanceMember_propertyAccess_setter() async {
    return super.test_staticAccessToInstanceMember_propertyAccess_setter();
  }

  @override
  @failingTest
  test_switchExpressionNotAssignable() async {
    return super.test_switchExpressionNotAssignable();
  }

  @override
  @failingTest
  test_typeAnnotationDeferredClass_functionDeclaration_returnType() async {
    return super
        .test_typeAnnotationDeferredClass_functionDeclaration_returnType();
  }

  @override
  @failingTest
  test_typeAnnotationDeferredClass_methodDeclaration_returnType() async {
    return super
        .test_typeAnnotationDeferredClass_methodDeclaration_returnType();
  }

  @override
  @failingTest
  test_typeAnnotationDeferredClass_typeParameter_bound() async {
    return super.test_typeAnnotationDeferredClass_typeParameter_bound();
  }

  @override
  @failingTest
  test_typeTestNonType() async {
    return super.test_typeTestNonType();
  }

  @override
  @failingTest
  test_undefinedIdentifier_for() async {
    return super.test_undefinedIdentifier_for();
  }

  @override
  @failingTest
  test_undefinedIdentifier_function() async {
    return super.test_undefinedIdentifier_function();
  }
}
