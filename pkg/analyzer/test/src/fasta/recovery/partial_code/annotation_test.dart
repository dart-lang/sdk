// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new AnnotationTest().buildAll();
}

class AnnotationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'annotation_topLevel',
      [
        new TestDescriptor(
            'ampersand',
            '@',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_EXECUTABLE
            ],
            '@_s_',
            expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_EXECUTABLE]),
        new TestDescriptor(
            'leftParen',
            '@a(',
            [
              ScannerErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.EXPECTED_EXECUTABLE
            ],
            '@a()',
            expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_EXECUTABLE]),
      ],
      [],
    );
    buildTests(
      'annotation_topLevel',
      [
        new TestDescriptor(
            'ampersand', '@', [ParserErrorCode.MISSING_IDENTIFIER], '@_s_',
            failing: ['typedef', 'functionNonVoid', 'getter', 'setter']),
        new TestDescriptor(
            'leftParen', '@a(', [ScannerErrorCode.EXPECTED_TOKEN], '@a()',
            allFailing: true),
      ],
      PartialCodeTest.declarationSuffixes,
      includeEof: false,
    );

    buildTests(
      'annotation_classMember',
      [
        new TestDescriptor(
            'ampersand',
            '@',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_CLASS_MEMBER
            ],
            '@_s_',
            expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_CLASS_MEMBER]),
        new TestDescriptor(
            'leftParen',
            '@a(',
            [
              ScannerErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.EXPECTED_CLASS_MEMBER
            ],
            '@a()',
            expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_CLASS_MEMBER]),
      ],
      [],
      head: 'class C { ',
      tail: ' }',
    );
    buildTests(
      'annotation_classMember',
      [
        new TestDescriptor(
            'ampersand', '@', [ParserErrorCode.MISSING_IDENTIFIER], '@_s_',
            failing: ['methodNonVoid', 'getter', 'setter']),
        new TestDescriptor(
            'leftParen', '@a(', [ScannerErrorCode.EXPECTED_TOKEN], '@a()',
            allFailing: true),
      ],
      PartialCodeTest.classMemberSuffixes,
      includeEof: false,
      head: 'class C { ',
      tail: ' }',
    );

    buildTests(
      'annotation_local',
      [
        new TestDescriptor(
            'ampersand',
            '@',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_IDENTIFIER
            ],
            '@_s_',
            expectedErrorsInValidCode: [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN
            ]),
        new TestDescriptor(
            'leftParen',
            '@a(',
            [
              ScannerErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_IDENTIFIER
            ],
            '@a()',
            expectedErrorsInValidCode: [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN
            ]),
      ],
      [],
      head: 'f() { ',
      tail: ' }',
    );
    // TODO(brianwilkerson) Many of the combinations produced by the following
    // produce "valid" code that is not valid. Even when we recover the
    // annotation, the following statement is not allowed to have an annotation.
    const localAllowed = const [
      'localVariable',
      'localFunctionNonVoid',
      'localFunctionVoid'
    ];
    List<TestSuffix> localAnnotationAllowedSuffixes = PartialCodeTest
        .statementSuffixes
        .where((t) => localAllowed.contains(t.name))
        .toList();
    List<TestSuffix> localAnnotationNotAllowedSuffixes = PartialCodeTest
        .statementSuffixes
        .where((t) => !localAllowed.contains(t.name))
        .toList();

    buildTests(
      'annotation_local',
      [
        new TestDescriptor(
            'ampersand', '@', [ParserErrorCode.MISSING_IDENTIFIER], '@_s_',
            failing: ['localFunctionNonVoid']),
        new TestDescriptor(
            'leftParen', '@a(', [ParserErrorCode.MISSING_IDENTIFIER], '@a()',
            allFailing: true),
      ],
      localAnnotationAllowedSuffixes,
      includeEof: false,
      head: 'f() { ',
      tail: ' }',
    );
    buildTests(
      'annotation_local',
      [
        new TestDescriptor(
            'ampersand',
            '@',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_IDENTIFIER
            ],
            '@_s_',
            expectedErrorsInValidCode: [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN
            ],
            failing: ['labeled']),
        new TestDescriptor(
            'leftParen',
            '@a(',
            [
              ScannerErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_IDENTIFIER
            ],
            '@a()',
            expectedErrorsInValidCode: [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN
            ],
            allFailing: true),
      ],
      localAnnotationNotAllowedSuffixes,
      includeEof: false,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
