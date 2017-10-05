// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ClassDeclarationTest().buildAll();
}

class ClassDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'class_declaration',
        [
          new TestDescriptor(
              'keyword',
              'class',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'class _s_ {}',
              allFailing: true),
          new TestDescriptor('named', 'class A',
              [ParserErrorCode.MISSING_CLASS_BODY], 'class A {}',
              allFailing: true),
          new TestDescriptor(
              'extends',
              'class A extends',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'class A extends _s_ {}',
              allFailing: true),
          new TestDescriptor('extendsBody', 'class A extends {}',
              [ParserErrorCode.MISSING_IDENTIFIER], 'class A extends _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'extendsWithNameBody',
              'class A extends with B {}',
              [ParserErrorCode.MISSING_IDENTIFIER],
              'class A extends _s_ with B {}',
              allFailing: true),
          new TestDescriptor(
              'extendsImplementsNameBody',
              'class A extends implements B {}',
              [ParserErrorCode.MISSING_IDENTIFIER],
              'class A extends _s_ implements B {}',
              allFailing: true),
          new TestDescriptor(
              'extendsNameWith',
              'class A extends B with',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'class A extends B with _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'extendsNameWithBody',
              'class A extends B with {}',
              [ParserErrorCode.MISSING_IDENTIFIER],
              'class A extends B with _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'extendsNameImplements',
              'class A extends B implements',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'class A extends B implements _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'extendsNameImplementsBody',
              'class A extends B implements {}',
              [ParserErrorCode.MISSING_IDENTIFIER],
              'class A extends B implements _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'extendsNameWithNameImplements',
              'class A extends B with C implements',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'class A extends B with C implements _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'extendsNameWithNameImplementsBody',
              'class A extends B with C implements {}',
              [ParserErrorCode.MISSING_IDENTIFIER],
              'class A extends B with C implements _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'implements',
              'class A implements',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'class A implements _s_ {}',
              allFailing: true),
          new TestDescriptor('implementsBody', 'class A implements {}',
              [ParserErrorCode.MISSING_IDENTIFIER], 'class A implements _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'implementsNameComma',
              'class A implements B,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'class A implements B, _s_ {}',
              allFailing: true),
          new TestDescriptor(
              'implementsNameCommaBody',
              'class A implements B, {}',
              [ParserErrorCode.MISSING_IDENTIFIER],
              'class A implements B, _s_ {}',
              allFailing: true),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}
