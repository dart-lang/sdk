// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

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
        [ParserErrorCode.missingIdentifier, ParserErrorCode.missingEnumBody],
        'enum _s_ {}',
        expectedDiagnosticsInValidCode: [],
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'name',
        'enum E',
        [ParserErrorCode.missingEnumBody],
        'enum E {}',
        expectedDiagnosticsInValidCode: [],
      ),
      TestDescriptor(
        'missingName',
        'enum {}',
        [ParserErrorCode.missingIdentifier],
        'enum _s_ {}',
        expectedDiagnosticsInValidCode: [],
      ),
      TestDescriptor(
        'leftBrace',
        'enum E {',
        [ParserErrorCode.missingIdentifier, ScannerErrorCode.expectedToken],
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
        [
          ParserErrorCode.missingIdentifier,
          ParserErrorCode.missingIdentifier,
          ScannerErrorCode.expectedToken,
        ],
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
      TestDescriptor('value', 'enum E {a', [
        ScannerErrorCode.expectedToken,
      ], 'enum E {a}'),
      TestDescriptor('commaValue', 'enum E {,a', [
        ParserErrorCode.missingIdentifier,
        ScannerErrorCode.expectedToken,
      ], 'enum E {_s_, a}'),
      TestDescriptor('commaRightBrace', 'enum E {,}', [
        ParserErrorCode.missingIdentifier,
      ], 'enum E {_s_}'),
      TestDescriptor('commaValueRightBrace', 'enum E {, a}', [
        ParserErrorCode.missingIdentifier,
      ], 'enum E {_s_, a}'),
    ], PartialCodeTest.declarationSuffixes);
    buildTests('enum_eof', [
      TestDescriptor(
        'leftBrace',
        'enum E {',
        [ScannerErrorCode.expectedToken],
        'enum E {}',
        expectedDiagnosticsInValidCode: [],
      ),
      TestDescriptor('comma', 'enum E {,', [
        ParserErrorCode.missingIdentifier,
        ScannerErrorCode.expectedToken,
      ], 'enum E {_s_}'),
    ], []);
  }
}
