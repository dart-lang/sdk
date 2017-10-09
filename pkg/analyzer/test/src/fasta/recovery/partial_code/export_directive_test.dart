// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ExportDirectivesTest().buildAll();
}

class ExportDirectivesTest extends PartialCodeTest {
  buildAll() {
    List<bool> allExceptEof = <bool>[
      false,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true
    ];
    buildTests(
        'export_directive',
        [
          new TestDescriptor(
              'keyword',
              'export',
              [/*ParserErrorCode.MISSING_URI,*/ ParserErrorCode.EXPECTED_TOKEN],
              "export '';",
              allFailing: true),
          new TestDescriptor('emptyUri', "export ''",
              [ParserErrorCode.EXPECTED_TOKEN], "export '';"),
          new TestDescriptor('uri', "export 'a.dart'",
              [ParserErrorCode.EXPECTED_TOKEN], "export 'a.dart';"),
          new TestDescriptor(
              'hide',
              "export 'a.dart' hide",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "export 'a.dart' hide _s_;",
              failing: allExceptEof),
          new TestDescriptor('hideName', "export 'a.dart' hide A",
              [ParserErrorCode.EXPECTED_TOKEN], "export 'a.dart' hide A;"),
          new TestDescriptor(
              'hideComma',
              "export 'a.dart' hide A,",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "export 'a.dart' hide A, _s_;",
              failing: allExceptEof),
          new TestDescriptor('hideCommaName', "export 'a.dart' hide A, B",
              [ParserErrorCode.EXPECTED_TOKEN], "export 'a.dart' hide A, B;"),
          new TestDescriptor(
              'hideShow',
              "export 'a.dart' hide A show",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "export 'a.dart' hide A show _s_;",
              failing: allExceptEof),
          new TestDescriptor(
              'show',
              "export 'a.dart' show",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "export 'a.dart' show _s_;",
              failing: allExceptEof),
          new TestDescriptor('showName', "export 'a.dart' show A",
              [ParserErrorCode.EXPECTED_TOKEN], "export 'a.dart' show A;"),
          new TestDescriptor(
              'showComma',
              "export 'a.dart' show A,",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "export 'a.dart' show A, _s_;",
              failing: allExceptEof),
          new TestDescriptor('showCommaName', "export 'a.dart' show A, B",
              [ParserErrorCode.EXPECTED_TOKEN], "export 'a.dart' show A, B;"),
          new TestDescriptor(
              'showHide',
              "export 'a.dart' show A hide",
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "export 'a.dart' show A hide _s_;",
              failing: allExceptEof),
        ],
        PartialCodeTest.prePartSuffixes);
  }
}
