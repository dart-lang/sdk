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
          'ampersand', '@', [ParserErrorCode.MISSING_IDENTIFIER], '@_s_',
          allFailing: true),
      new TestDescriptor(
          'leftParen', '@a(', [ParserErrorCode.EXPECTED_TOKEN], '@a()',
          allFailing: true),
    ];
    buildTests('annotation_topLevel', descriptors,
        PartialCodeTest.declarationSuffixes);
    buildTests('annotation_classMember', descriptors,
        PartialCodeTest.classMemberSuffixes,
        head: 'class C { ', tail: ' }');
    buildTests(
        'annotation_local', descriptors, PartialCodeTest.statementSuffixes,
        head: 'f() { ', tail: ' }');
  }
}
