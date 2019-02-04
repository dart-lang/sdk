// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new PartOfDirectivesTest().buildAll();
}

class PartOfDirectivesTest extends PartialCodeTest {
  buildAll() {
    List<String> identifiers = const [
      'typedef',
      'functionNonVoid',
      'getter',
      'setter'
    ];
    List<TestSuffix> identifierSuffixes = PartialCodeTest.declarationSuffixes
        .where((t) => identifiers.contains(t.name))
        .toList();
    List<TestSuffix> nonIdentifierSuffixes = PartialCodeTest.declarationSuffixes
        .where((t) => !identifiers.contains(t.name))
        .toList();
    buildTests(
        'part_of_directive',
        [
          new TestDescriptor(
              'keyword',
              'part of',
              [
                ParserErrorCode.EXPECTED_STRING_LITERAL,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'part of "";',
              failing: ['mixin']),
        ],
        nonIdentifierSuffixes);
    buildTests(
        'part_of_directive',
        [
          new TestDescriptor(
              'keyword',
              'part of',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'part of _s_;',
              failing: ['functionNonVoid', 'getter']),
        ],
        identifierSuffixes,
        includeEof: false);
    buildTests(
        'part_of_directive',
        [
          new TestDescriptor('name', 'part of lib',
              [ParserErrorCode.EXPECTED_TOKEN], 'library lib;',
              allFailing: true),
          new TestDescriptor(
              'nameDot',
              'part of lib.',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'part of lib._s_;',
              failing: ['functionNonVoid', 'getter']),
          new TestDescriptor('nameDotName', 'part of lib.a',
              [ParserErrorCode.EXPECTED_TOKEN], 'part of lib.a;'),
          new TestDescriptor('emptyUri', "part of ''",
              [ParserErrorCode.EXPECTED_TOKEN], "part of '';"),
          new TestDescriptor('uri', "part of 'a.dart'",
              [ParserErrorCode.EXPECTED_TOKEN], "part of 'a.dart';"),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}
