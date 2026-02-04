// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

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
        diag.expectedStringLiteral,
        diag.expectedToken,
      ], "import '';"),
      TestDescriptor('emptyUri', "import ''", [
        diag.expectedToken,
      ], "import '';"),
      TestDescriptor('fullUri', "import 'a.dart'", [
        diag.expectedToken,
      ], "import 'a.dart';"),
      TestDescriptor('if', "import 'a.dart' if", [
        diag.expectedToken,
        diag.expectedToken,
        diag.expectedStringLiteral,
      ], "import 'a.dart' if (_s_) '';"),
      TestDescriptor(
        'ifParen',
        "import 'a.dart' if (",
        [
          diag.missingIdentifier,
          diag.expectedToken,
          diag.expectedStringLiteral,
          diag.expectedToken,
        ],
        "import 'a.dart' if (_s_) '';",
        failing: ['functionNonVoid', 'getter', 'setter'],
      ),
      TestDescriptor('ifId', "import 'a.dart' if (b", [
        diag.expectedToken,
        diag.expectedToken,
        diag.expectedStringLiteral,
      ], "import 'a.dart' if (b) '';"),
      TestDescriptor('ifEquals', "import 'a.dart' if (b ==", [
        diag.expectedStringLiteral,
        diag.expectedToken,
        diag.expectedToken,
        diag.expectedStringLiteral,
      ], "import 'a.dart' if (b == '') '';"),
      TestDescriptor('ifCondition', "import 'a.dart' if (b)", [
        diag.expectedToken,
        diag.expectedStringLiteral,
      ], "import 'a.dart' if (b) '';"),
      TestDescriptor(
        'as',
        "import 'a.dart' as",
        [diag.missingIdentifier, diag.expectedToken],
        "import 'a.dart' as _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'show',
        "import 'a.dart' show",
        [diag.expectedToken, diag.missingIdentifier],
        "import 'a.dart' show _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
    ], PartialCodeTest.prePartSuffixes);
  }
}
