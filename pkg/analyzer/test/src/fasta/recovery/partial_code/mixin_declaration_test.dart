// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new MixinDeclarationTest().buildAll();
}

class MixinDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'mixin_declaration',
        [
          new TestDescriptor(
              'keyword',
              'mixin',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin _s_ {}',
              failing: ['functionNonVoid', 'getter']),
          new TestDescriptor('named', 'mixin A',
              [ParserErrorCode.MISSING_CLASS_BODY], 'mixin A {}'),
          new TestDescriptor(
              'on',
              'mixin A on',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin A on _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          new TestDescriptor(
              'extend',
              'mixin A extend',
              [
                ParserErrorCode.EXPECTED_INSTEAD,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin A extend _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_INSTEAD],
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          new TestDescriptor(
              'extends',
              'mixin A extends',
              [
                ParserErrorCode.EXPECTED_INSTEAD,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin A extends _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_INSTEAD],
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          new TestDescriptor('onBody', 'mixin A on {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME], 'mixin A on _s_ {}'),
          new TestDescriptor(
              'onNameComma',
              'mixin A on B,',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin A on B, _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          new TestDescriptor('onNameCommaBody', 'mixin A on B, {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME], 'mixin A on B, _s_ {}'),
          new TestDescriptor(
              'onImplementsNameBody',
              'mixin A on implements B {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'mixin A on _s_ implements B {}',
              allFailing: true),
          new TestDescriptor(
              'onNameImplements',
              'mixin A on B implements',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin A on B implements _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          new TestDescriptor(
              'onNameImplementsBody',
              'mixin A on B implements {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'mixin A on B implements _s_ {}'),
          new TestDescriptor(
              'implements',
              'mixin A implements',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin A implements _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          new TestDescriptor(
              'implementsBody',
              'mixin A implements {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'mixin A implements _s_ {}'),
          new TestDescriptor(
              'implementsNameComma',
              'mixin A implements B,',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.MISSING_CLASS_BODY
              ],
              'mixin A implements B, _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          new TestDescriptor(
              'implementsNameCommaBody',
              'mixin A implements B, {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'mixin A implements B, _s_ {}'),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}
