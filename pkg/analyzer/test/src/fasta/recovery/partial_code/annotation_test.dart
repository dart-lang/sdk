// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

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
        [diag.missingIdentifier, diag.expectedExecutable],
        '@_s_',
        expectedDiagnosticsInValidCode: [diag.expectedExecutable],
      ),
      TestDescriptor(
        'leftParen',
        '@a(',
        [diag.expectedToken, diag.expectedExecutable],
        '@a()',
        expectedDiagnosticsInValidCode: [diag.expectedExecutable],
      ),
    ], []);
    buildTests(
      'annotation_topLevel',
      [
        TestDescriptor(
          'ampersand',
          '@',
          [diag.missingIdentifier],
          '@_s_',
          failing: ['typedef', 'functionNonVoid', 'getter', 'mixin', 'setter'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [diag.expectedToken],
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
          [diag.missingIdentifier, diag.expectedClassMember],
          '@_s_',
          expectedDiagnosticsInValidCode: [diag.expectedClassMember],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [diag.expectedToken, diag.expectedClassMember],
          '@a()',
          expectedDiagnosticsInValidCode: [diag.expectedClassMember],
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
          [diag.missingIdentifier],
          '@_s_',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [diag.expectedToken],
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
          [diag.missingIdentifier, diag.expectedToken, diag.missingIdentifier],
          '@_s_',
          expectedDiagnosticsInValidCode: [
            diag.missingIdentifier,
            diag.expectedToken,
          ],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [diag.expectedToken, diag.expectedToken, diag.missingIdentifier],
          '@a()',
          expectedDiagnosticsInValidCode: [
            diag.missingIdentifier,
            diag.expectedToken,
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
          [diag.missingIdentifier],
          '@_s_',
          failing: ['localFunctionNonVoid'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [diag.missingIdentifier],
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
          [diag.missingIdentifier, diag.expectedToken, diag.missingIdentifier],
          '@_s_',
          expectedDiagnosticsInValidCode: [
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          failing: ['labeled'],
        ),
        TestDescriptor(
          'leftParen',
          '@a(',
          [diag.expectedToken, diag.expectedToken, diag.missingIdentifier],
          '@a()',
          expectedDiagnosticsInValidCode: [
            diag.missingIdentifier,
            diag.expectedToken,
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
