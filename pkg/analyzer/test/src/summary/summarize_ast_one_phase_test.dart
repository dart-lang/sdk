// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'summary_common.dart';
import 'test_strategies.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SummarizeAstOnePhaseTest);
  });
}

@reflectiveTest
class SummarizeAstOnePhaseTest extends SummaryBlackBoxTestStrategyOnePhase
    with SummaryTestCases {
  @override
  @failingTest
  test_bottom_reference_shared() {
    super.test_bottom_reference_shared();
  }

  @override
  @failingTest
  test_closure_executable_with_bottom_return_type() {
    super.test_closure_executable_with_bottom_return_type();
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
  test_field_inferred_type_nonstatic_implicit_initialized() {
    super.test_field_inferred_type_nonstatic_implicit_initialized();
  }

  @override
  @failingTest
  test_field_inferred_type_static_implicit_initialized() {
    super.test_field_inferred_type_static_implicit_initialized();
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
  test_inferred_type_reference_shared_prefixed() {
    super.test_inferred_type_reference_shared_prefixed();
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
  test_inferred_type_undefined() {
    super.test_inferred_type_undefined();
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
  test_syntheticFunctionType_inGenericClass() {
    super.test_syntheticFunctionType_inGenericClass();
  }

  @override
  @failingTest
  test_unused_type_parameter() {
    super.test_unused_type_parameter();
  }

  @override
  @failingTest
  test_variable_final_top_level_untyped() {
    super.test_variable_final_top_level_untyped();
  }

  @override
  @failingTest
  test_variable_inferred_type_implicit_initialized() {
    super.test_variable_inferred_type_implicit_initialized();
  }
}
