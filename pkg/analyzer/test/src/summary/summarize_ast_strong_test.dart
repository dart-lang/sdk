// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summarize_ast_test;

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
  test_bottom_reference_shared() {
    // TODO(paulberry): fix.
  }

  @override
  test_closure_executable_with_imported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_closure_executable_with_return_type_from_closure() {
    // TODO(paulberry): fix.
  }

  @override
  test_closure_executable_with_unimported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_field_formal_param_inferred_type_explicit() {
    // TODO(paulberry): fix.
  }

  @override
  test_field_formal_param_inferred_type_implicit() {
    // TODO(paulberry): fix.
  }

  @override
  test_field_inferred_type_nonstatic_implicit_initialized() {
    // TODO(paulberry): fix.
  }

  @override
  test_field_inferred_type_static_implicit_initialized() {
    // TODO(paulberry): fix.
  }

  @override
  test_field_propagated_type_final_immediate() {
    // TODO(paulberry): fix.
  }

  @override
  test_fully_linked_references_follow_other_references() {
    // TODO(paulberry): fix.
  }

  @override
  test_implicit_dependencies_follow_other_dependencies() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_bottom_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_imported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_return_type_from_closure() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_return_type_from_closure_field() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_return_type_from_closure_local() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_unimported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_linked_reference_reuse() {
    // TODO(paulberry): fix.
  }

  @override
  test_linked_type_dependency_reuse() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_genericClosure() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_genericClosure_inGenericFunction() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_inGenericClass() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_inGenericFunction() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_noArguments() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_withArguments() {
    // TODO(paulberry): fix.
  }

  @override
  test_variable_inferred_type_implicit_initialized() {
    // TODO(paulberry): fix.
  }

  @override
  test_variable_propagated_type_final_immediate() {
    // TODO(paulberry): fix.
  }

  @override
  test_variable_propagated_type_new_reference() {
    // TODO(paulberry): fix.
  }

  @override
  test_variable_propagated_type_omit_dynamic() {
    // TODO(paulberry): fix.
  }
}
