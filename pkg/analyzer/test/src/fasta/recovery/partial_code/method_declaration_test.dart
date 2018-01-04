// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new MethodTest().buildAll();
}

class MethodTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'method_declaration',
        [
          new TestDescriptor('noType_leftParen', 'm(',
              [ParserErrorCode.EXPECTED_TOKEN], "m();",
              allFailing: true),
          new TestDescriptor('noType_paramName', 'm(B',
              [ParserErrorCode.EXPECTED_TOKEN], "m(B);",
              allFailing: true),
          new TestDescriptor('noType_paramTypeAndName', 'm(B b',
              [ParserErrorCode.EXPECTED_TOKEN], "m(B b);",
              allFailing: true),
          new TestDescriptor(
              'noType_paramAndComma',
              'm(B b,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "m(B b, _s_);",
              allFailing: true),
          new TestDescriptor('noType_noParams', 'm()',
              [ParserErrorCode.EXPECTED_TOKEN], "m();",
              allFailing: true),
          new TestDescriptor('noType_params', 'm(b, c)',
              [ParserErrorCode.EXPECTED_TOKEN], "m(b, c);",
              allFailing: true),
          new TestDescriptor(
              'noType_emptyOptional',
              'm(B b, [])',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_FUNCTION_BODY
              ],
              "m(B b, [_s_]){}",
              failing: ['fieldConst']),
          new TestDescriptor(
              'noType_emptyNamed',
              'm(B b, {})',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_FUNCTION_BODY
              ],
              "m(B b, {_s_}){}",
              failing: ['fieldConst']),
          new TestDescriptor('type_leftParen', 'A m(',
              [ParserErrorCode.EXPECTED_TOKEN], "A m();",
              allFailing: true),
          new TestDescriptor('type_paramName', 'A m(B',
              [ParserErrorCode.EXPECTED_TOKEN], "A m(B);",
              allFailing: true),
          new TestDescriptor('type_paramTypeAndName', 'A m(B b',
              [ParserErrorCode.EXPECTED_TOKEN], "A m(B b);",
              allFailing: true),
          new TestDescriptor(
              'noType_paramAndComma',
              'A m(B b,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "A m(B b, _s_);",
              allFailing: true),
          new TestDescriptor('type_noParams', 'A m()',
              [ParserErrorCode.EXPECTED_TOKEN], "A m();",
              allFailing: true),
          new TestDescriptor('type_params', 'A m(b, c)',
              [ParserErrorCode.EXPECTED_TOKEN], "A m(b, c);",
              allFailing: true),
        ],
        PartialCodeTest.classMemberSuffixes,
        head: 'class C { ',
        tail: ' }');
  }
}
