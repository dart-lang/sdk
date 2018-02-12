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
    List<TestDescriptor> descriptors = <TestDescriptor>[
      new TestDescriptor(
        'ampersand',
        '@',
        [ParserErrorCode.MISSING_IDENTIFIER],
        '@_s_',
        allFailing: true,
      ),
      new TestDescriptor(
        'leftParen',
        '@a(',
        [ParserErrorCode.EXPECTED_TOKEN],
        '@a()',
        allFailing: true,
      ),
    ];
    buildTests(
      'annotation_topLevel',
      expectErrors(descriptors, [ParserErrorCode.EXPECTED_EXECUTABLE]),
      [],
    );
    buildTests(
      'annotation_topLevel',
      descriptors,
      PartialCodeTest.declarationSuffixes,
      includeEof: false,
    );
    buildTests(
      'annotation_classMember',
      descriptors,
      PartialCodeTest.classMemberSuffixes,
      head: 'class C { ',
      tail: ' }',
    );
    buildTests(
      'annotation_local',
      expectErrors(descriptors, [
        ParserErrorCode.EXPECTED_TOKEN,
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.MISSING_IDENTIFIER,
      ]),
      [],
      head: 'f() { ',
      tail: ' }',
    );
    // TODO(brianwilkerson) Many of the combinations produced by the following
    // produce "valid" code that is not valid. Even when we recover the
    // annotation, the following statement is not allowed to have an annotation.
    buildTests(
      'annotation_local',
      descriptors,
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      includeEof: false,
      tail: ' }',
    );
  }

  /**
   * Return a list of descriptors just like the given [descriptors] except that
   * they have the given list of [errors] as the errors that are expected to be
   * in the valid code.
   */
  List<TestDescriptor> expectErrors(
          List<TestDescriptor> descriptors, List<ParserErrorCode> errors) =>
      descriptors
          .map((descriptor) => descriptor.withExpectedErrorsInValidCode(errors))
          .toList();
}
