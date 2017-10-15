// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ImportDirectivesTest().buildAll();
}

class ImportDirectivesTest extends PartialCodeTest {
  buildAll() {
    List<bool> onlyConstAndFinal = <bool>[
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      true,
      true,
      false,
      false
    ];
    buildTests(
        'import_directive',
        [
          new TestDescriptor(
              'keyword',
              'import',
              [/*ParserErrorCode.MISSING_URI,*/ ParserErrorCode.EXPECTED_TOKEN],
              "import '';",
              allFailing: true),
          new TestDescriptor('emptyUri', "import ''",
              [ParserErrorCode.EXPECTED_TOKEN], "import '';",
              failing: onlyConstAndFinal),
          new TestDescriptor('fullUri', "import 'a.dart'",
              [ParserErrorCode.EXPECTED_TOKEN], "import 'a.dart';",
              failing: onlyConstAndFinal),
        ],
        PartialCodeTest.prePartSuffixes);
  }
}
