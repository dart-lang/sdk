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
  test_constExpr_makeTypedList_functionType_withTypeParameters() {
    super.test_constExpr_makeTypedList_functionType_withTypeParameters();
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
  test_initializer_executable_with_unimported_return_type() {
    super.test_initializer_executable_with_unimported_return_type();
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
  test_variable_final_top_level_untyped() {
    super.test_variable_final_top_level_untyped();
  }
}
