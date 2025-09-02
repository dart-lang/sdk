// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  AnnotationTest().buildAll();
}

class AnnotationTest extends PartialCodeTest {
  buildAll() {
    buildTests('annotation_topLevel', [
      TestDescriptor(
        'ampersand',
        '@',
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedExecutable],
        '@_s_',
        expectedDiagnosticsInValidCode: [ParserErrorCode.expectedExecutable],
      ),
      TestDescriptor(
        'leftParen',
        '@a(',
        [ScannerErrorCode.expectedToken, ParserErrorCode.expectedExecutable],
        '@a()',
        expectedDiagnosticsInValidCode: [ParserErrorCode.expectedExecutable],
      ),
    ], []);
    buildTests(
      'annotation_topLevel',
      [
        TestDescriptor(
          'ampersand',
          '@',
          [ParserErrorCode.missingIdentifier],
          '@_s_',
          failing: ['typedef', 'functionNonVoid', 'getter', 'mixin', 'setter'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [ScannerErrorCode.expectedToken],
          '@a()',
          allFailing: true,
        ),
      ],
      PartialCodeTest.declarationSuffixes,
      includeEof: false,
    );

    buildTests(
      'annotation_classMember',
      [
        TestDescriptor(
          'ampersand',
          '@',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedClassMember,
          ],
          '@_s_',
          expectedDiagnosticsInValidCode: [ParserErrorCode.expectedClassMember],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [ScannerErrorCode.expectedToken, ParserErrorCode.expectedClassMember],
          '@a()',
          expectedDiagnosticsInValidCode: [ParserErrorCode.expectedClassMember],
        ),
      ],
      [],
      head: 'class C { ',
      tail: ' }',
    );
    buildTests(
      'annotation_classMember',
      [
        TestDescriptor(
          'ampersand',
          '@',
          [ParserErrorCode.missingIdentifier],
          '@_s_',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [ScannerErrorCode.expectedToken],
          '@a()',
          allFailing: true,
        ),
      ],
      PartialCodeTest.classMemberSuffixes,
      includeEof: false,
      head: 'class C { ',
      tail: ' }',
    );

    buildTests(
      'annotation_local',
      [
        TestDescriptor(
          'ampersand',
          '@',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
          ],
          '@_s_',
          expectedDiagnosticsInValidCode: [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [
            ScannerErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
          ],
          '@a()',
          expectedDiagnosticsInValidCode: [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
        ),
      ],
      [],
      head: 'f() { ',
      tail: ' }',
    );
    // TODO(brianwilkerson): Many of the combinations produced by the following
    // produce "valid" code that is not valid. Even when we recover the
    // annotation, the following statement is not allowed to have an annotation.
    const localAllowed = [
      'localVariable',
      'localFunctionNonVoid',
      'localFunctionVoid',
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
        TestDescriptor(
          'ampersand',
          '@',
          [ParserErrorCode.missingIdentifier],
          '@_s_',
          failing: ['localFunctionNonVoid'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [ParserErrorCode.missingIdentifier],
          '@a()',
          allFailing: true,
        ),
      ],
      localAnnotationAllowedSuffixes,
      includeEof: false,
      head: 'f() { ',
      tail: ' }',
    );
    buildTests(
      'annotation_local',
      [
        TestDescriptor(
          'ampersand',
          '@',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
          ],
          '@_s_',
          expectedDiagnosticsInValidCode: [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          failing: ['labeled'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [
            ScannerErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
          ],
          '@a()',
          expectedDiagnosticsInValidCode: [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          allFailing: true,
        ),
      ],
      localAnnotationNotAllowedSuffixes,
      includeEof: false,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
