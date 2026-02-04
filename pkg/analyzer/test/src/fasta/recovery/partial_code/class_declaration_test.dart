// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  ClassDeclarationTest().buildAll();
}

class ClassDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests('class_declaration', [
      TestDescriptor(
        'keyword',
        'class',
        [diag.missingIdentifier, diag.expectedClassBody],
        'class _s_ {}',
        failing: ['const', 'functionNonVoid', 'getter'],
      ),
      TestDescriptor('named', 'class A', [
        diag.expectedClassBody,
      ], 'class A {}'),
      TestDescriptor(
        'extend',
        'class A extend',
        [diag.expectedInstead, diag.expectedTypeName, diag.expectedClassBody],
        'class A extend _s_ {}',
        expectedDiagnosticsInValidCode: [diag.expectedInstead],
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'extends',
        'class A extends',
        [diag.expectedTypeName, diag.expectedClassBody],
        'class A extends _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'on',
        'class A on',
        [diag.expectedInstead, diag.expectedTypeName, diag.expectedClassBody],
        'class A on _s_ {}',
        expectedDiagnosticsInValidCode: [diag.expectedInstead],
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor('extendsBody', 'class A extends {}', [
        diag.expectedTypeName,
      ], 'class A extends _s_ {}'),
      TestDescriptor(
        'extendsWithNameBody',
        'class A extends with B {}',
        [diag.expectedTypeName],
        'class A extends _s_ with B {}',
      ),
      TestDescriptor(
        'extendsImplementsNameBody',
        'class A extends implements B {}',
        [diag.expectedTypeName],
        'class A extends _s_ implements B {}',
        allFailing: true,
      ),
      TestDescriptor(
        'extendsNameWith',
        'class A extends B with',
        [diag.expectedTypeName, diag.expectedClassBody],
        'class A extends B with _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'extendsNameWithBody',
        'class A extends B with {}',
        [diag.expectedTypeName],
        'class A extends B with _s_ {}',
      ),
      TestDescriptor(
        'extendsNameImplements',
        'class A extends B implements',
        [diag.expectedTypeName, diag.expectedClassBody],
        'class A extends B implements _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'extendsNameImplementsBody',
        'class A extends B implements {}',
        [diag.expectedTypeName],
        'class A extends B implements _s_ {}',
      ),
      TestDescriptor(
        'extendsNameWithNameImplements',
        'class A extends B with C implements',
        [diag.expectedTypeName, diag.expectedClassBody],
        'class A extends B with C implements _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'extendsNameWithNameImplementsBody',
        'class A extends B with C implements {}',
        [diag.expectedTypeName],
        'class A extends B with C implements _s_ {}',
      ),
      TestDescriptor(
        'implements',
        'class A implements',
        [diag.expectedTypeName, diag.expectedClassBody],
        'class A implements _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor('implementsBody', 'class A implements {}', [
        diag.expectedTypeName,
      ], 'class A implements _s_ {}'),
      TestDescriptor(
        'implementsNameComma',
        'class A implements B,',
        [diag.expectedTypeName, diag.expectedClassBody],
        'class A implements B, _s_ {}',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'implementsNameCommaBody',
        'class A implements B, {}',
        [diag.expectedTypeName],
        'class A implements B, _s_ {}',
      ),
      TestDescriptor(
        'equals',
        'class A =',
        [diag.expectedTypeName, diag.expectedToken, diag.expectedToken],
        'class A = _s_ with _s_;',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor(
        'equalsName',
        'class A = B',
        [diag.expectedToken, diag.expectedToken],
        'class A = B with _s_;',
        failing: ['functionVoid', 'functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'equalsNameWith',
        'class A = B with',
        [diag.expectedTypeName, diag.expectedToken],
        'class A = B with _s_;',
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin'],
      ),
      TestDescriptor('equalsNameName', 'class A = B C', [
        diag.expectedToken,
        diag.expectedToken,
      ], 'class A = B with C;'),
    ], PartialCodeTest.declarationSuffixes);
  }
}
