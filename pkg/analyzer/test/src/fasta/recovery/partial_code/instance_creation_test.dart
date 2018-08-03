// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new InstanceCreationTest().buildAll();
}

class InstanceCreationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'instance_creation_expression',
        <TestDescriptor>[]
          ..addAll(forKeyword('const'))
          ..addAll(forKeyword('new')),
        <TestSuffix>[],
        head: 'f() => ',
        tail: ';');
  }

  List<TestDescriptor> forKeyword(String keyword) {
    return <TestDescriptor>[
      new TestDescriptor(
          '${keyword}_keyword',
          '$keyword',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword _s_()"),
      new TestDescriptor(
          '${keyword}_name_unnamed',
          '$keyword A',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A()"),
      new TestDescriptor(
          '${keyword}_name_named',
          '$keyword A.b',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A.b()"),
      new TestDescriptor(
          '${keyword}_name_dot',
          '$keyword A.',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A._s_()"),
      new TestDescriptor(
          '${keyword}_leftParen_unnamed',
          '$keyword A(',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A()",
          allFailing: true),
      new TestDescriptor(
          '${keyword}_leftParen_named',
          '$keyword A.b(',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A.b()",
          allFailing: true),
    ];
  }
}
