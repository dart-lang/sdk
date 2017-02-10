// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/analyzer/token_utils.dart';
import 'package:front_end/src/fasta/scanner/error_token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/keyword.dart' as fasta;
import 'package:front_end/src/fasta/scanner/string_scanner.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/fasta/scanner/token_constants.dart' as fasta;
import 'package:front_end/src/scanner/errors.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ScannerTest_Fasta);
  });
}

@reflectiveTest
class ScannerTest_Fasta extends ScannerTestBase {
  @override
  Token scanWithListener(String source, ErrorListener listener,
      {bool genericMethodComments: false,
      bool lazyAssignmentOperators: false}) {
    if (genericMethodComments) {
      // Fasta doesn't support generic method comments.
      // TODO(paulberry): once the analyzer toolchain no longer needs generic
      // method comments, remove tests that exercise them.
      fail('No generic method comment support in Fasta');
    }
    // Note: Fasta always supports lazy assignment operators (`&&=` and `||=`),
    // so we can ignore the `lazyAssignmentOperators` flag.
    // TODO(paulberry): once lazyAssignmentOperators are fully supported by
    // Dart, remove this flag.
    var scanner = new fasta.StringScanner(source, includeComments: true);
    var token = scanner.tokenize();
    return toAnalyzerTokenStream(token,
        (ScannerErrorCode errorCode, int offset, List<Object> arguments) {
      listener.errors.add(new TestError(offset, errorCode, arguments));
    });
  }

  @override
  @failingTest
  void test_ampersand_ampersand_eq() {
    // TODO(paulberry,ahe): Fasta doesn't support `&&=` yet
    super.test_ampersand_ampersand_eq();
  }

  @override
  @failingTest
  void test_bar_bar_eq() {
    // TODO(paulberry,ahe): Fasta doesn't support `||=` yet
    super.test_bar_bar_eq();
  }

  @override
  @failingTest
  void test_comment_generic_method_type_assign() {
    // TODO(paulberry,ahe): Fasta doesn't support generic method comment syntax.
    super.test_comment_generic_method_type_assign();
  }

  @override
  @failingTest
  void test_comment_generic_method_type_list() {
    // TODO(paulberry,ahe): Fasta doesn't support generic method comment syntax.
    super.test_comment_generic_method_type_list();
  }

  @override
  @failingTest
  void test_index() {
    // TODO(paulberry,ahe): "[]" should be parsed as a single token.
    // See dartbug.com/28665.
    super.test_index();
  }

  @override
  @failingTest
  void test_index_eq() {
    // TODO(paulberry,ahe): "[]=" should be parsed as a single token.
    // See dartbug.com/28665.
    super.test_index_eq();
  }

  @override
  @failingTest
  void test_scriptTag_withArgs() {
    // TODO(paulberry,ahe): script tags are needed by analyzer.
    super.test_scriptTag_withArgs();
  }

  @override
  @failingTest
  void test_scriptTag_withoutSpace() {
    // TODO(paulberry,ahe): script tags are needed by analyzer.
    super.test_scriptTag_withoutSpace();
  }

  @override
  @failingTest
  void test_scriptTag_withSpace() {
    // TODO(paulberry,ahe): script tags are needed by analyzer.
    super.test_scriptTag_withSpace();
  }

  @override
  @failingTest
  void test_string_multi_unterminated() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_block() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_multi_unterminated_interpolation_identifier() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_multi_unterminated_interpolation_identifier();
  }

  @override
  @failingTest
  void test_string_raw_multi_unterminated() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_multi_unterminated();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eof() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_raw_simple_unterminated_eol() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_raw_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eof() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_eof();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_eol() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_eol();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_block() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_interpolation_block();
  }

  @override
  @failingTest
  void test_string_simple_unterminated_interpolation_identifier() {
    // TODO(paulberry,ahe): bad error recovery.
    super.test_string_simple_unterminated_interpolation_identifier();
  }
}
