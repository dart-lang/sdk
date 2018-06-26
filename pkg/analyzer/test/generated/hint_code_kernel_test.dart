// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'hint_code_driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HintCodeTest_Kernel);
  });
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}

@reflectiveTest
class HintCodeTest_Kernel extends HintCodeTest_Driver {
  @override
  bool get enableKernelDriver => true;

  @override
  bool get useCFE => true;

  @failingTest
  @override
  test_abstractSuperMemberReference_getter() async {
    // Expected 1 errors of type HintCode.ABSTRACT_SUPER_MEMBER_REFERENCE, found 0
    return super.test_abstractSuperMemberReference_getter();
  }

  @failingTest
  @override
  test_abstractSuperMemberReference_method_invocation() async {
    // Expected 1 errors of type HintCode.ABSTRACT_SUPER_MEMBER_REFERENCE, found 0
    return super.test_abstractSuperMemberReference_method_invocation();
  }

  @failingTest
  @override
  test_abstractSuperMemberReference_method_reference() async {
    // Expected 1 errors of type HintCode.ABSTRACT_SUPER_MEMBER_REFERENCE, found 0
    return super.test_abstractSuperMemberReference_method_reference();
  }

  @failingTest
  @override
  test_abstractSuperMemberReference_superHasNoSuchMethod() async {
    // Expected 1 errors of type HintCode.ABSTRACT_SUPER_MEMBER_REFERENCE, found 0
    return super.test_abstractSuperMemberReference_superHasNoSuchMethod();
  }

  @failingTest
  @override
  test_argumentTypeNotAssignable_functionType() async {
    // Expected 1 errors of type HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    return super.test_argumentTypeNotAssignable_functionType();
  }

  @failingTest
  @override
  test_argumentTypeNotAssignable_type() async {
    // Expected 1 errors of type HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, found 0
    return super.test_argumentTypeNotAssignable_type();
  }

  @failingTest
  @override
  test_deadCode_deadFinalStatementInCase() async {
    // Expected 1 errors of type StaticWarningCode.CASE_BLOCK_NOT_TERMINATED, found 0
    return super.test_deadCode_deadFinalStatementInCase();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deadCode_statementAfterAlwaysThrowsFunction() async {
    await super.test_deadCode_statementAfterAlwaysThrowsFunction();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deadCode_statementAfterAlwaysThrowsMethod() async {
    await super.test_deadCode_statementAfterAlwaysThrowsMethod();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_assignment() async {
    await super.test_deprecatedAnnotationUse_assignment();
  }

  @failingTest
  @override
  test_deprecatedAnnotationUse_call() async {
    // Expected 1 errors of type HintCode.DEPRECATED_MEMBER_USE, found 0
    return super.test_deprecatedAnnotationUse_call();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_deprecated() async {
    await super.test_deprecatedAnnotationUse_deprecated();
  }

  @failingTest
  @override
  test_deprecatedAnnotationUse_Deprecated() async {
    // Expected 1 errors of type HintCode.DEPRECATED_MEMBER_USE, found 0
    return super.test_deprecatedAnnotationUse_Deprecated();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_export() async {
    await super.test_deprecatedAnnotationUse_export();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_field() async {
    await super.test_deprecatedAnnotationUse_field();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_getter() async {
    await super.test_deprecatedAnnotationUse_getter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_import() async {
    await super.test_deprecatedAnnotationUse_import();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_indexExpression() async {
    await super.test_deprecatedAnnotationUse_indexExpression();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_instanceCreation() async {
    await super.test_deprecatedAnnotationUse_instanceCreation();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_instanceCreation_namedConstructor() async {
    await super
        .test_deprecatedAnnotationUse_instanceCreation_namedConstructor();
  }

  @override
  @failingTest
  test_deprecatedAnnotationUse_named() async {
    return super.test_deprecatedAnnotationUse_named();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_operator() async {
    await super.test_deprecatedAnnotationUse_operator();
  }

  @failingTest
  @override
  test_deprecatedAnnotationUse_positional() async {
    return super.test_deprecatedAnnotationUse_positional();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_setter() async {
    await super.test_deprecatedAnnotationUse_setter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_superConstructor() async {
    await super.test_deprecatedAnnotationUse_superConstructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_deprecatedAnnotationUse_superConstructor_namedConstructor() async {
    await super
        .test_deprecatedAnnotationUse_superConstructor_namedConstructor();
  }

  @failingTest
  @override
  test_deprecatedFunction_class() async {
    // Expected 1 errors of type HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION, found 0
    return super.test_deprecatedFunction_class();
  }

  @failingTest
  @override
  test_deprecatedFunction_extends() async {
    // Expected 1 errors of type HintCode.DEPRECATED_EXTENDS_FUNCTION, found 0;
    //          1 errors of type StaticWarningCode.FUNCTION_WITHOUT_CALL, found 0
    return super.test_deprecatedFunction_extends();
  }

  @failingTest
  @override
  test_deprecatedFunction_extends2() async {
    // Expected 1 errors of type HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION, found 0;
    //          1 errors of type HintCode.DEPRECATED_EXTENDS_FUNCTION, found 0
    return super.test_deprecatedFunction_extends2();
  }

  @failingTest
  @override
  test_deprecatedFunction_mixin() async {
    // Expected 1 errors of type HintCode.DEPRECATED_MIXIN_FUNCTION, found 0;
    //          1 errors of type StaticWarningCode.FUNCTION_WITHOUT_CALL, found 0
    return super.test_deprecatedFunction_mixin();
  }

  @failingTest
  @override
  test_deprecatedFunction_mixin2() async {
    // Expected 1 errors of type HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION, found 0;
    //          1 errors of type HintCode.DEPRECATED_MIXIN_FUNCTION, found 0
    return super.test_deprecatedFunction_mixin2();
  }

  @failingTest
  @override
  test_duplicateShownHiddenName_hidden() {
    // Expected 1 errors of type HintCode.DUPLICATE_HIDDEN_NAME, found 0
    return super.test_duplicateShownHiddenName_hidden();
  }

  @failingTest
  @override
  test_duplicateShownHiddenName_shown() {
    // Expected 1 errors of type HintCode.DUPLICATE_SHOWN_NAME, found 0
    return super.test_duplicateShownHiddenName_shown();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory__expr_return_null_OK() async {
    await super.test_factory__expr_return_null_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_abstract_OK() async {
    await super.test_factory_abstract_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_bad_return() async {
    await super.test_factory_bad_return();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_block_OK() async {
    await super.test_factory_block_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_block_return_null_OK() async {
    await super.test_factory_block_return_null_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_expr_OK() async {
    await super.test_factory_expr_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_misplaced_annotation() async {
    await super.test_factory_misplaced_annotation();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_no_return_type_OK() async {
    await super.test_factory_no_return_type_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_subclass_OK() async {
    await super.test_factory_subclass_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_factory_void_return() async {
    await super.test_factory_void_return();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidImmutableAnnotation_method() async {
    await super.test_invalidImmutableAnnotation_method();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_named_parameter_with_default() async {
    return super.test_invalidRequiredParam_on_named_parameter_with_default();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_positional_parameter() async {
    return super.test_invalidRequiredParam_on_positional_parameter();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_positional_parameter_with_default() async {
    return super
        .test_invalidRequiredParam_on_positional_parameter_with_default();
  }

  @override
  @failingTest
  test_invalidRequiredParam_on_required_parameter() async {
    return super.test_invalidRequiredParam_on_required_parameter();
  }

  @override
  @failingTest
  test_invalidRequiredParam_valid() async {
    return super.test_invalidRequiredParam_valid();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_closure() async {
    await super.test_invalidUseOfProtectedMember_closure();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_field() async {
    await super.test_invalidUseOfProtectedMember_field();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_field_OK() async {
    await super.test_invalidUseOfProtectedMember_field_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_function() async {
    await super.test_invalidUseOfProtectedMember_function();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_function_OK() async {
    await super.test_invalidUseOfProtectedMember_function_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_function_OK2() async {
    await super.test_invalidUseOfProtectedMember_function_OK2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_getter() async {
    await super.test_invalidUseOfProtectedMember_getter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_getter_OK() async {
    await super.test_invalidUseOfProtectedMember_getter_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_in_docs_OK() async {
    await super.test_invalidUseOfProtectedMember_in_docs_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_message() async {
    await super.test_invalidUseOfProtectedMember_message();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_method_1() async {
    await super.test_invalidUseOfProtectedMember_method_1();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_method_OK() async {
    await super.test_invalidUseOfProtectedMember_method_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_1() async {
    await super.test_invalidUseOfProtectedMember_OK_1();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_2() async {
    await super.test_invalidUseOfProtectedMember_OK_2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_3() async {
    await super.test_invalidUseOfProtectedMember_OK_3();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_4() async {
    await super.test_invalidUseOfProtectedMember_OK_4();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_field() async {
    await super.test_invalidUseOfProtectedMember_OK_field();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_getter() async {
    await super.test_invalidUseOfProtectedMember_OK_getter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_setter() async {
    await super.test_invalidUseOfProtectedMember_OK_setter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_OK_setter_2() async {
    await super.test_invalidUseOfProtectedMember_OK_setter_2();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_setter() async {
    await super.test_invalidUseOfProtectedMember_setter();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_setter_OK() async {
    await super.test_invalidUseOfProtectedMember_setter_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfProtectedMember_topLevelVariable() async {
    await super.test_invalidUseOfProtectedMember_topLevelVariable();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfVisibleForTestingMember_constructor() async {
    await super.test_invalidUseOfVisibleForTestingMember_constructor();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfVisibleForTestingMember_method() async {
    await super.test_invalidUseOfVisibleForTestingMember_method();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfVisibleForTestingMember_method_OK() async {
    await super.test_invalidUseOfVisibleForTestingMember_method_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfVisibleForTestingMember_OK_export() async {
    await super.test_invalidUseOfVisibleForTestingMember_OK_export();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfVisibleForTestingMember_propertyAccess() async {
    await super.test_invalidUseOfVisibleForTestingMember_propertyAccess();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseOfVisibleForTestingMember_topLevelFunction() async {
    await super.test_invalidUseOfVisibleForTestingMember_topLevelFunction();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseProtectedAndForTesting_asProtected_OK() async {
    await super.test_invalidUseProtectedAndForTesting_asProtected_OK();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_invalidUseProtectedAndForTesting_asTesting_OK() async {
    await super.test_invalidUseProtectedAndForTesting_asTesting_OK();
  }

  @override
  @failingTest
  test_isNotDouble() {
    // Bad state: No data for is at 10
    return super.test_isNotDouble();
  }

  @failingTest
  @override
  test_js_lib_OK() async {
    // Bad state: Expected element reference for analyzer offset 51; got one for kernel offset 1
    return super.test_js_lib_OK();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_class() async {
    // Expected 1 errors of type HintCode.MISSING_JS_LIB_ANNOTATION, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    return super.test_missingJsLibAnnotation_class();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_externalField() async {
    // Expected 1 errors of type ParserErrorCode.EXTERNAL_FIELD, found 0;
    //          1 errors of type HintCode.MISSING_JS_LIB_ANNOTATION, found 0;
    //          0 errors of type ParserErrorCode.EXTRANEOUS_MODIFIER, found 1 (36);
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (7)
    return super.test_missingJsLibAnnotation_externalField();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_function() async {
    // Expected 1 errors of type HintCode.MISSING_JS_LIB_ANNOTATION, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    return super.test_missingJsLibAnnotation_function();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_method() async {
    // Expected 1 errors of type HintCode.MISSING_JS_LIB_ANNOTATION, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (21)
    return super.test_missingJsLibAnnotation_method();
  }

  @failingTest
  @override
  test_missingJsLibAnnotation_variable() async {
    // Expected 1 errors of type HintCode.MISSING_JS_LIB_ANNOTATION, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (7)
    return super.test_missingJsLibAnnotation_variable();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustBeImmutable_direct() async {
    await super.test_mustBeImmutable_direct();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustBeImmutable_extends() async {
    await super.test_mustBeImmutable_extends();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustBeImmutable_fromMixin() async {
    await super.test_mustBeImmutable_fromMixin();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustBeImmutable_instance() async {
    await super.test_mustBeImmutable_instance();
  }

  @failingTest
  @override
  test_mustCallSuper() async {
    // Expected 1 errors of type HintCode.MUST_CALL_SUPER, found 0
    return super.test_mustCallSuper();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustCallSuper_fromInterface() async {
    await super.test_mustCallSuper_fromInterface();
  }

  @failingTest
  @override
  test_mustCallSuper_indirect() async {
    // Expected 1 errors of type HintCode.MUST_CALL_SUPER, found 0
    return super.test_mustCallSuper_indirect();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustCallSuper_overridden() async {
    await super.test_mustCallSuper_overridden();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustCallSuper_overridden_w_future() async {
    await super.test_mustCallSuper_overridden_w_future();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_mustCallSuper_overridden_w_future2() async {
    await super.test_mustCallSuper_overridden_w_future2();
  }

  @failingTest
  @override
  test_nullAwareBeforeOperator_ok_is_not() {
    // Bad state: No data for is at 14
    return super.test_nullAwareBeforeOperator_ok_is_not();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_overrideOnNonOverridingField_invalid() async {
    await super.test_overrideOnNonOverridingField_invalid();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_overrideOnNonOverridingGetter_invalid() async {
    await super.test_overrideOnNonOverridingGetter_invalid();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_overrideOnNonOverridingMethod_invalid() async {
    await super.test_overrideOnNonOverridingMethod_invalid();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33567')
  test_overrideOnNonOverridingSetter_invalid() async {
    await super.test_overrideOnNonOverridingSetter_invalid();
  }

  @override
  @failingTest
  test_required_constructor_param() async {
    return super.test_required_constructor_param();
  }

  @override
  @failingTest
  test_required_constructor_param_no_reason() async {
    return super.test_required_constructor_param_no_reason();
  }

  @override
  @failingTest
  test_required_constructor_param_null_reason() async {
    return super.test_required_constructor_param_null_reason();
  }

  @override
  @failingTest
  test_required_constructor_param_OK() async {
    return super.test_required_constructor_param_OK();
  }

  @override
  @failingTest
  test_required_constructor_param_redirecting_cons_call() async {
    return super.test_required_constructor_param_redirecting_cons_call();
  }

  @override
  @failingTest
  test_required_constructor_param_super_call() async {
    return super.test_required_constructor_param_super_call();
  }

  @override
  @failingTest
  test_required_function_param() async {
    return super.test_required_function_param();
  }

  @override
  @failingTest
  test_required_method_param() async {
    return super.test_required_method_param();
  }

  @override
  @failingTest
  test_required_method_param_in_other_lib() async {
    return super.test_required_method_param_in_other_lib();
  }

  @override
  @failingTest
  test_required_typedef_function_param() async {
    return super.test_required_typedef_function_param();
  }

  @failingTest
  @override
  test_strongMode_downCastCompositeHint() async {
    // Expected 1 errors of type StrongModeCode.STRONG_MODE_DOWN_CAST_COMPOSITE, found 0
    return super.test_strongMode_downCastCompositeHint();
  }

  @failingTest
  @override
  test_strongMode_downCastCompositeWarn() async {
    // Expected 1 errors of type StrongModeCode.STRONG_MODE_DOWN_CAST_COMPOSITE, found 0
    return super.test_strongMode_downCastCompositeWarn();
  }

  @failingTest
  @override
  test_strongMode_topLevelInstanceGetter_implicitlyTyped_field_call() {
    // NoSuchMethodError: The setter 'enclosingElement=' was called on null.
    return super
        .test_strongMode_topLevelInstanceGetter_implicitlyTyped_field_call();
  }

  @override
  @failingTest
  test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke() {
    return super
        .test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke();
  }

  @override
  @failingTest
  test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke_explicit_type_params() {
    return super
        .test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke_explicit_type_params();
  }

  @failingTest
  @override
  test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke_not_generic() {
    // NoSuchMethodError: The setter 'enclosingElement=' was called on null.
    return super
        .test_strongMode_topLevelInstanceGetter_implicitlyTyped_invoke_not_generic();
  }

  @failingTest
  @override
  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_explicit_type_params_prefixed() {
    // NoSuchMethodError: The setter 'enclosingElement=' was called on null.
    return super
        .test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_explicit_type_params_prefixed();
  }

  @failingTest
  @override
  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_not_generic_prefixed() {
    // NoSuchMethodError: The getter 'element' was called on null.
    return super
        .test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_not_generic_prefixed();
  }

  @failingTest
  @override
  test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_prefixed() {
    // NoSuchMethodError: The getter 'element' was called on null.
    return super
        .test_strongMode_topLevelInstanceGetter_implicitlyTyped_new_prefixed();
  }

  @failingTest
  @override
  test_typeCheck_type_not_Null() {
    // Bad state: No data for is at 20
    return super.test_typeCheck_type_not_Null();
  }

  @failingTest
  @override
  test_undefinedOperator_binaryExpression() async {
    // Expected 1 errors of type HintCode.UNDEFINED_OPERATOR, found 0
    return super.test_undefinedOperator_binaryExpression();
  }

  @failingTest
  @override
  test_undefinedOperator_indexBoth() async {
    // Expected 1 errors of type HintCode.UNDEFINED_OPERATOR, found 0
    return super.test_undefinedOperator_indexBoth();
  }

  @failingTest
  @override
  test_undefinedOperator_indexGetter() async {
    // Expected 1 errors of type HintCode.UNDEFINED_OPERATOR, found 0
    return super.test_undefinedOperator_indexGetter();
  }

  @failingTest
  @override
  test_undefinedOperator_indexSetter() async {
    // Expected 1 errors of type HintCode.UNDEFINED_OPERATOR, found 0
    return super.test_undefinedOperator_indexSetter();
  }

  @failingTest
  @override
  test_unnecessaryTypeCheck_null_not_Null() {
    // Bad state: No data for is at 14
    return super.test_unnecessaryTypeCheck_null_not_Null();
  }

  @failingTest
  @override
  test_unnecessaryTypeCheck_type_not_dynamic() {
    // Bad state: No data for is at 20
    return super.test_unnecessaryTypeCheck_type_not_dynamic();
  }

  @failingTest
  @override
  test_unnecessaryTypeCheck_type_not_object() {
    // Bad state: No data for is at 20
    return super.test_unnecessaryTypeCheck_type_not_object();
  }

  @failingTest
  @override
  test_unusedImport_inComment_libraryDirective() async {
    // Expected 0 errors of type HintCode.UNUSED_IMPORT, found 1 (42)
    return super.test_unusedImport_inComment_libraryDirective();
  }

  @failingTest
  @override
  test_unusedShownName() async {
    // Expected 1 errors of type HintCode.UNUSED_SHOWN_NAME, found 0
    return super.test_unusedShownName();
  }

  @failingTest
  @override
  test_unusedShownName_as() async {
    // Expected 1 errors of type HintCode.UNUSED_SHOWN_NAME, found 0;
    //          0 errors of type HintCode.UNUSED_IMPORT, found 1 (18)
    return super.test_unusedShownName_as();
  }

  @failingTest
  @override
  test_unusedShownName_duplicates() async {
    // Expected 2 errors of type HintCode.UNUSED_SHOWN_NAME, found 0
    return super.test_unusedShownName_duplicates();
  }

  @failingTest
  @override
  test_unusedShownName_topLevelVariable() async {
    // Expected 1 errors of type HintCode.UNUSED_SHOWN_NAME, found 0
    return super.test_unusedShownName_topLevelVariable();
  }
}
