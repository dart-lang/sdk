// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new TypedefTest().buildAll();
}

class TypedefTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'typedef',
        [
          new TestDescriptor(
              'keyword',
              'typedef',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_TYPEDEF_PARAMETERS,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "typedef _s_();",
              failing: ['functionVoid', 'functionNonVoid', 'getter']),
          new TestDescriptor(
              'name',
              'typedef T',
              [
                ParserErrorCode.MISSING_TYPEDEF_PARAMETERS,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "typedef T();",
              failing: ['functionNonVoid', 'getter', 'mixin', 'setter']),
          new TestDescriptor(
              'keywordEquals',
              'typedef =',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "typedef _s_ = _s_;",
              allFailing: true),
          new TestDescriptor(
              'equals',
              'typedef T =',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE
              ],
              "typedef T = _s_;",
              expectedErrorsInValidCode: [
                ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE
              ],
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}
