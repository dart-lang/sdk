// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  EnumDeclarationTest().buildAll();
}

class EnumDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests('enum_declaration', [
      TestDescriptor(
        'keyword',
        'enum',
        [diag.missingIdentifier, diag.missingEnumBody],
        'enum _s_ {}',
        expectedDiagnosticsInValidCode: [],
        failing: ['const', 'functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'name',
        'enum E',
        [diag.missingEnumBody],
        'enum E {}',
        expectedDiagnosticsInValidCode: [],
      ),
      TestDescriptor(
        'missingName',
        'enum {}',
        [diag.missingIdentifier],
        'enum _s_ {}',
        expectedDiagnosticsInValidCode: [],
      ),
      TestDescriptor(
        'leftBrace',
        'enum E {',
        [diag.missingIdentifier, diag.expectedToken],
        'enum E {_s_}',
        failing: [
          'eof' /* tested separately below */,
          'typedef',
          'functionNonVoid',
          'getter',
          'mixin',
          'setter',
        ],
      ),
      TestDescriptor(
        'comma',
        'enum E {,',
        [diag.missingIdentifier, diag.missingIdentifier, diag.expectedToken],
        'enum E {_s_,_s_}',
        failing: [
          'eof' /* tested separately below */,
          'typedef',
          'functionNonVoid',
          'getter',
          'mixin',
          'setter',
        ],
      ),
      TestDescriptor('value', 'enum E {a', [diag.expectedToken], 'enum E {a}'),
      TestDescriptor('commaValue', 'enum E {,a', [
        diag.missingIdentifier,
        diag.expectedToken,
      ], 'enum E {_s_, a}'),
      TestDescriptor('commaRightBrace', 'enum E {,}', [
        diag.missingIdentifier,
      ], 'enum E {_s_}'),
      TestDescriptor('commaValueRightBrace', 'enum E {, a}', [
        diag.missingIdentifier,
      ], 'enum E {_s_, a}'),
    ], PartialCodeTest.declarationSuffixes);
    buildTests('enum_eof', [
      TestDescriptor(
        'leftBrace',
        'enum E {',
        [diag.expectedToken],
        'enum E {}',
        expectedDiagnosticsInValidCode: [],
      ),
      TestDescriptor('comma', 'enum E {,', [
        diag.missingIdentifier,
        diag.expectedToken,
      ], 'enum E {_s_}'),
    ], []);
  }
}
