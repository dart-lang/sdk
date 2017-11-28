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
        'method',
        [
          new TestDescriptor(
              'noTypeLeftParen', 'm(', [ParserErrorCode.EXPECTED_TOKEN], "m();",
              allFailing: true),
          new TestDescriptor('noTypeRightParen', 'm()',
              [ParserErrorCode.EXPECTED_TOKEN], "m();",
              allFailing: true),
          new TestDescriptor('typeLeftParen', 'A m(',
              [ParserErrorCode.EXPECTED_TOKEN], "A m();",
              allFailing: true),
          new TestDescriptor('typeRightParen', 'A m()',
              [ParserErrorCode.EXPECTED_TOKEN], "A m();",
              allFailing: true),
        ],
        PartialCodeTest.classMemberSuffixes,
        head: 'class C { ',
        tail: ' }');
  }
}
