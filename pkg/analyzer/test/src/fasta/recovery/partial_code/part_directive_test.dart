// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new PartDirectivesTest().buildAll();
}

class PartDirectivesTest extends PartialCodeTest {
  buildAll() {
    List<String> onlyConstAndFinal = <String>['const', 'final'];
    buildTests(
        'part_directive',
        [
          new TestDescriptor(
              'keyword',
              'part',
              [/*ParserErrorCode.MISSING_URI,*/ ParserErrorCode.EXPECTED_TOKEN],
              "part '';",
              allFailing: true),
          new TestDescriptor('emptyUri', "part ''",
              [ParserErrorCode.EXPECTED_TOKEN], "part '';",
              failing: onlyConstAndFinal),
          new TestDescriptor('uri', "part 'a.dart'",
              [ParserErrorCode.EXPECTED_TOKEN], "part 'a.dart';",
              failing: onlyConstAndFinal),
        ],
        PartialCodeTest.postPartSuffixes);
  }
}
