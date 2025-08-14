// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  MixinDeclarationTest().buildAll();
}

class MixinDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests('mixin_declaration', [
      TestDescriptor(
        'keyword',
        'mixin',
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedMixinBody],
        'mixin _s_ {}',
        failing: ['class', 'functionNonVoid', 'getter'],
      ),
      TestDescriptor('named', 'mixin A', [
        ParserErrorCode.expectedMixinBody,
      ], 'mixin A {}'),
      TestDescriptor(
        'on',
        'mixin A on',
        [ParserErrorCode.expectedTypeName, ParserErrorCode.expectedMixinBody],
        'mixin A on _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'extend',
        'mixin A extend',
        [
          ParserErrorCode.expectedInstead,
          ParserErrorCode.expectedTypeName,
          ParserErrorCode.expectedMixinBody,
        ],
        'mixin A extend _s_ {}',
        expectedDiagnosticsInValidCode: [ParserErrorCode.expectedInstead],
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'extends',
        'mixin A extends',
        [
          ParserErrorCode.expectedInstead,
          ParserErrorCode.expectedTypeName,
          ParserErrorCode.expectedMixinBody,
        ],
        'mixin A extends _s_ {}',
        expectedDiagnosticsInValidCode: [ParserErrorCode.expectedInstead],
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor('onBody', 'mixin A on {}', [
        ParserErrorCode.expectedTypeName,
      ], 'mixin A on _s_ {}'),
      TestDescriptor(
        'onNameComma',
        'mixin A on B,',
        [ParserErrorCode.expectedTypeName, ParserErrorCode.expectedMixinBody],
        'mixin A on B, _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor('onNameCommaBody', 'mixin A on B, {}', [
        ParserErrorCode.expectedTypeName,
      ], 'mixin A on B, _s_ {}'),
      TestDescriptor(
        'onImplementsNameBody',
        'mixin A on implements B {}',
        [ParserErrorCode.expectedTypeName],
        'mixin A on _s_ implements B {}',
        allFailing: true,
      ),
      TestDescriptor(
        'onNameImplements',
        'mixin A on B implements',
        [ParserErrorCode.expectedTypeName, ParserErrorCode.expectedMixinBody],
        'mixin A on B implements _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'onNameImplementsBody',
        'mixin A on B implements {}',
        [ParserErrorCode.expectedTypeName],
        'mixin A on B implements _s_ {}',
      ),
      TestDescriptor(
        'implements',
        'mixin A implements',
        [ParserErrorCode.expectedTypeName, ParserErrorCode.expectedMixinBody],
        'mixin A implements _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor('implementsBody', 'mixin A implements {}', [
        ParserErrorCode.expectedTypeName,
      ], 'mixin A implements _s_ {}'),
      TestDescriptor(
        'implementsNameComma',
        'mixin A implements B,',
        [ParserErrorCode.expectedTypeName, ParserErrorCode.expectedMixinBody],
        'mixin A implements B, _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'implementsNameCommaBody',
        'mixin A implements B, {}',
        [ParserErrorCode.expectedTypeName],
        'mixin A implements B, _s_ {}',
      ),
    ], PartialCodeTest.declarationSuffixes);
  }
}
