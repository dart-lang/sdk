// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/fasta/summary_builder.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:front_end/src/fasta/parser/class_member_parser.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart' as fasta;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'summarize_ast_strong_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinkedSummarizeAstFastaTest);
  });
}

@reflectiveTest
class LinkedSummarizeAstFastaTest extends LinkedSummarizeAstStrongTest {
  @override
  UnlinkedUnitBuilder createUnlinkedSummary(Uri uri, String text) {
    var scanner = new fasta.StringScanner(text);
    var startingToken = scanner.tokenize();
    var listener = new SummaryBuilder(uri);
    var parser = new fasta.ClassMemberParser(listener);
    parser.parseUnit(startingToken);
    return listener.topScope.unit;
  }

  @failingTest
  @override
  void test_class_alias_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_class_alias_documented();
  }

  @failingTest
  @override
  void test_class_codeRange() {
    // TODO(paulberry): implement codeRange.
    super.test_class_codeRange();
  }

  @failingTest
  @override
  void test_class_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_class_documented();
  }

  @failingTest
  @override
  void test_class_documented_tripleSlash() {
    // TODO(paulberry): handle doc comments.
    super.test_class_documented_tripleSlash();
  }

  @failingTest
  @override
  void test_class_documented_with_references() {
    // TODO(paulberry): handle doc comments.
    super.test_class_documented_with_references();
  }

  @failingTest
  @override
  void test_class_documented_with_with_windows_line_endings() {
    // TODO(paulberry): handle doc comments.
    super.test_class_documented_with_with_windows_line_endings();
  }

  @failingTest
  @override
  void test_class_name() {
    // TODO(paulberry): implement nameOffset.
    super.test_class_name();
  }

  @failingTest
  @override
  void test_class_type_param_no_bound() {
    // TODO(paulberry): implement nameOffset.
    super.test_class_type_param_no_bound();
  }

  @failingTest
  @override
  void test_constructor() {
    // TODO(paulberry): implement nameOffset.
    super.test_constructor();
  }

  @failingTest
  @override
  void test_constructor_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_constructor_documented();
  }

  @failingTest
  @override
  void test_constructor_initializing_formal_named_withDefault() {
    // TODO(paulberry): implement codeRange.
    super.test_constructor_initializing_formal_named_withDefault();
  }

  @failingTest
  @override
  void test_constructor_initializing_formal_positional_withDefault() {
    // TODO(paulberry): implement codeRange.
    super.test_constructor_initializing_formal_positional_withDefault();
  }

  @failingTest
  @override
  void test_constructor_named() {
    // TODO(paulberry): implement codeRange.
    super.test_constructor_named();
  }

  @failingTest
  @override
  void test_enum() {
    // TODO(paulberry): implement codeRange.
    super.test_enum();
  }

  @failingTest
  @override
  void test_enum_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_enum_documented();
  }

  @failingTest
  @override
  void test_enum_value_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_enum_value_documented();
  }

  @failingTest
  @override
  void test_executable_function() {
    // TODO(paulberry): implement nameOffset.
    super.test_executable_function();
  }

  @failingTest
  @override
  void test_executable_getter() {
    // TODO(paulberry): implement nameOffset.
    super.test_executable_getter();
  }

  @failingTest
  @override
  void test_executable_member_function() {
    // TODO(paulberry): implement codeRange.
    super.test_executable_member_function();
  }

  @failingTest
  @override
  void test_executable_member_getter() {
    // TODO(paulberry): implement codeRange.
    super.test_executable_member_getter();
  }

  @failingTest
  @override
  void test_executable_member_setter() {
    // TODO(paulberry): implement codeRange.
    super.test_executable_member_setter();
  }

  @failingTest
  @override
  void test_executable_param_codeRange() {
    // TODO(paulberry): implement codeRange.
    super.test_executable_param_codeRange();
  }

  @failingTest
  @override
  void test_executable_param_kind_named_withDefault() {
    // TODO(paulberry): implement codeRange.
    super.test_executable_param_kind_named_withDefault();
  }

  @failingTest
  @override
  void test_executable_param_kind_positional_withDefault() {
    // TODO(paulberry): implement codeRange.
    super.test_executable_param_kind_positional_withDefault();
  }

  @failingTest
  @override
  void test_executable_param_name() {
    // TODO(paulberry): implement nameOffset.
    super.test_executable_param_name();
  }

  @failingTest
  @override
  void test_executable_setter() {
    // TODO(paulberry): implement nameOffset.
    super.test_executable_setter();
  }

  @failingTest
  @override
  void test_field_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_field_documented();
  }

  @failingTest
  @override
  void test_function_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_function_documented();
  }

  @failingTest
  @override
  void test_getter_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_getter_documented();
  }

  @failingTest
  @override
  void test_method_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_method_documented();
  }

  @failingTest
  @override
  void test_setter_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_setter_documented();
  }

  @failingTest
  @override
  void test_type_param_codeRange() {
    // TODO(paulberry): implement codeRange.
    super.test_type_param_codeRange();
  }

  @failingTest
  @override
  void test_typedef_codeRange() {
    // TODO(paulberry): implement codeRange.
    super.test_typedef_codeRange();
  }

  @failingTest
  @override
  void test_typedef_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_typedef_documented();
  }

  @failingTest
  @override
  void test_typedef_name() {
    // TODO(paulberry): implement nameOffset.
    super.test_typedef_name();
  }

  @failingTest
  @override
  void test_unit_codeRange() {
    // TODO(paulberry): implement codeRange.
    super.test_unit_codeRange();
  }

  @failingTest
  @override
  void test_variable() {
    // TODO(paulberry): implement nameOffset.
    super.test_variable();
  }

  @failingTest
  @override
  void test_variable_codeRange() {
    // TODO(paulberry): implement codeRange.
    super.test_variable_codeRange();
  }

  @failingTest
  @override
  void test_variable_documented() {
    // TODO(paulberry): handle doc comments.
    super.test_variable_documented();
  }

  @failingTest
  @override
  void test_variable_initializer_literal() {
    // TODO(paulberry): implement nameOffset.
    super.test_variable_initializer_literal();
  }

  @failingTest
  @override
  void test_variable_initializer_withLocals() {
    // TODO(paulberry): implement nameOffset.
    super.test_variable_initializer_withLocals();
  }
}
