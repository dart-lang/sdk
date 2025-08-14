// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ImportDirectivesTest().buildAll();
}

class ImportDirectivesTest extends PartialCodeTest {
  buildAll() {
    buildTests('import_directive', [
      TestDescriptor('keyword', 'import', [
        // TODO(danrubel): Consider an improved error message
        // ParserErrorCode.MISSING_URI,
        ParserErrorCode.expectedStringLiteral,
        ParserErrorCode.expectedToken,
      ], "import '';"),
      TestDescriptor('emptyUri', "import ''", [
        ParserErrorCode.expectedToken,
      ], "import '';"),
      TestDescriptor('fullUri', "import 'a.dart'", [
        ParserErrorCode.expectedToken,
      ], "import 'a.dart';"),
      TestDescriptor('if', "import 'a.dart' if", [
        ParserErrorCode.expectedToken,
        ParserErrorCode.expectedToken,
        ParserErrorCode.expectedStringLiteral,
      ], "import 'a.dart' if (_s_) '';"),
      TestDescriptor(
        'ifParen',
        "import 'a.dart' if (",
        [
          ParserErrorCode.missingIdentifier,
          ScannerErrorCode.expectedToken,
          ParserErrorCode.expectedStringLiteral,
          ParserErrorCode.expectedToken,
        ],
        "import 'a.dart' if (_s_) '';",
        failing: ['functionNonVoid', 'getter', 'setter'],
      ),
      TestDescriptor('ifId', "import 'a.dart' if (b", [
        ScannerErrorCode.expectedToken,
        ParserErrorCode.expectedToken,
        ParserErrorCode.expectedStringLiteral,
      ], "import 'a.dart' if (b) '';"),
      TestDescriptor('ifEquals', "import 'a.dart' if (b ==", [
        ParserErrorCode.expectedStringLiteral,
        ParserErrorCode.expectedToken,
        ScannerErrorCode.expectedToken,
        ParserErrorCode.expectedStringLiteral,
      ], "import 'a.dart' if (b == '') '';"),
      TestDescriptor('ifCondition', "import 'a.dart' if (b)", [
        ParserErrorCode.expectedToken,
        ParserErrorCode.expectedStringLiteral,
      ], "import 'a.dart' if (b) '';"),
      TestDescriptor(
        'as',
        "import 'a.dart' as",
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
        "import 'a.dart' as _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'show',
        "import 'a.dart' show",
        [ParserErrorCode.expectedToken, ParserErrorCode.missingIdentifier],
        "import 'a.dart' show _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
    ], PartialCodeTest.prePartSuffixes);
  }
}
