// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summarize_ast_strong_test;

import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'summarize_ast_test.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LinkedSummarizeAstStrongTest);
}

/**
 * Override of [LinkedSummarizeAstTest] which uses strong mode.
 */
@reflectiveTest
class LinkedSummarizeAstStrongTest extends LinkedSummarizeAstTest {
  @override
  bool get strongMode => true;

  @override
  @failingTest
  test_bottom_reference_shared() {
    super.test_bottom_reference_shared();
  }

  @override
  @failingTest
  test_closure_executable_with_imported_return_type() {
    super.test_closure_executable_with_imported_return_type();
  }

  @override
  @failingTest
  test_closure_executable_with_return_type_from_closure() {
    super.test_closure_executable_with_return_type_from_closure();
  }

  @override
  @failingTest
  test_closure_executable_with_unimported_return_type() {
    super.test_closure_executable_with_unimported_return_type();
  }

  @override
  @failingTest
  test_field_propagated_type_final_immediate() {
    super.test_field_propagated_type_final_immediate();
  }

  @override
  @failingTest
  test_fully_linked_references_follow_other_references() {
    super.test_fully_linked_references_follow_other_references();
  }

  @override
  @failingTest
  test_implicit_dependencies_follow_other_dependencies() {
    super.test_implicit_dependencies_follow_other_dependencies();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_function_typed_param_of_typedef() {
    super.test_inferred_type_refers_to_function_typed_param_of_typedef();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_nested_function_typed_param() {
    super.test_inferred_type_refers_to_nested_function_typed_param();
  }

  @override
  @failingTest
  test_inferred_type_refers_to_nested_function_typed_param_named() {
    super.test_inferred_type_refers_to_nested_function_typed_param_named();
  }

  @override
  @failingTest
  test_initializer_executable_with_bottom_return_type() {
    super.test_initializer_executable_with_bottom_return_type();
  }

  @override
  @failingTest
  test_initializer_executable_with_imported_return_type() {
    super.test_initializer_executable_with_imported_return_type();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure() {
    super.test_initializer_executable_with_return_type_from_closure();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_field() {
    super.test_initializer_executable_with_return_type_from_closure_field();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_local() {
    super.test_initializer_executable_with_return_type_from_closure_local();
  }

  @override
  @failingTest
  test_initializer_executable_with_unimported_return_type() {
    super.test_initializer_executable_with_unimported_return_type();
  }

  @override
  @failingTest
  test_linked_reference_reuse() {
    super.test_linked_reference_reuse();
  }

  @override
  @failingTest
  test_linked_type_dependency_reuse() {
    super.test_linked_type_dependency_reuse();
  }

  @override
  @failingTest
  test_syntheticFunctionType_genericClosure() {
    super.test_syntheticFunctionType_genericClosure();
  }

  @override
  @failingTest
  test_syntheticFunctionType_genericClosure_inGenericFunction() {
    super.test_syntheticFunctionType_genericClosure_inGenericFunction();
  }

  @override
  @failingTest
  test_syntheticFunctionType_inGenericClass() {
    super.test_syntheticFunctionType_inGenericClass();
  }

  @override
  @failingTest
  test_syntheticFunctionType_inGenericFunction() {
    super.test_syntheticFunctionType_inGenericFunction();
  }

  @override
  @failingTest
  test_syntheticFunctionType_noArguments() {
    super.test_syntheticFunctionType_noArguments();
  }

  @override
  @failingTest
  test_syntheticFunctionType_withArguments() {
    super.test_syntheticFunctionType_withArguments();
  }

  @override
  @failingTest
  test_unused_type_parameter() {
    super.test_unused_type_parameter();
  }

  @override
  @failingTest
  test_variable_propagated_type_final_immediate() {
    super.test_variable_propagated_type_final_immediate();
  }

  @override
  @failingTest
  test_variable_propagated_type_new_reference() {
    super.test_variable_propagated_type_new_reference();
  }

  @override
  @failingTest
  test_variable_propagated_type_omit_dynamic() {
    super.test_variable_propagated_type_omit_dynamic();
  }
}
