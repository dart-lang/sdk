// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ImportDirectivesTest().buildAll();
}

class ImportDirectivesTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'import_directive',
        [
          new TestDescriptor(
              'keyword',
              'import',
              [
                // TODO(danrubel): Consider an improved error message
                // ParserErrorCode.MISSING_URI,
                ParserErrorCode.EXPECTED_STRING_LITERAL,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "import '';"),
          new TestDescriptor('emptyUri', "import ''",
              [ParserErrorCode.EXPECTED_TOKEN], "import '';"),
          new TestDescriptor('fullUri', "import 'a.dart'",
              [ParserErrorCode.EXPECTED_TOKEN], "import 'a.dart';"),
          new TestDescriptor(
              'if',
              "import 'a.dart' if",
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_STRING_LITERAL
              ],
              "import 'a.dart' if (_s_) '';"),
          new TestDescriptor(
              'ifParen',
              "import 'a.dart' if (",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_STRING_LITERAL,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "import 'a.dart' if (_s_) '';",
              failing: ['functionNonVoid', 'getter', 'setter']),
          new TestDescriptor(
              'ifId',
              "import 'a.dart' if (b",
              [
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_STRING_LITERAL
              ],
              "import 'a.dart' if (b) '';"),
          new TestDescriptor(
              'ifEquals',
              "import 'a.dart' if (b ==",
              [
                ParserErrorCode.EXPECTED_STRING_LITERAL,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_STRING_LITERAL
              ],
              "import 'a.dart' if (b == '') '';"),
          new TestDescriptor(
              'ifCondition',
              "import 'a.dart' if (b)",
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_STRING_LITERAL
              ],
              "import 'a.dart' if (b) '';"),
          new TestDescriptor(
              'as',
              "import 'a.dart' as",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "import 'a.dart' as _s_;",
              failing: ['functionNonVoid', 'getter']),
          new TestDescriptor(
              'show',
              "import 'a.dart' show",
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER
              ],
              "import 'a.dart' show _s_;",
              failing: ['functionNonVoid', 'getter']),
        ],
        PartialCodeTest.prePartSuffixes);
  }
}
