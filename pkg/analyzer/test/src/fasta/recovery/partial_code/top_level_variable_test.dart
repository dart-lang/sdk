// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';

import 'partial_code_support.dart';

main() {
  TopLevelVariableTest().buildAll();
}

class TopLevelVariableTest extends PartialCodeTest {
  buildAll() {
    buildTests('top_level_variable', [
      TestDescriptor(
        'const',
        'const',
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
        "const _s_;",
        failing: [
          'class',
          'functionVoid',
          'functionNonVoid',
          'getter',
          'setter',
        ],
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.constNotInitialized,
        ],
      ),
      TestDescriptor(
        'constName',
        'const a',
        [
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.constNotInitialized,
        ],
        "const a;",
        failing: ['functionNonVoid', 'getter', 'setter', 'mixin'],
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.constNotInitialized,
        ],
      ),
      TestDescriptor(
        'constTypeName',
        'const int a',
        [
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.constNotInitialized,
        ],
        "const int a;",
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.constNotInitialized,
        ],
      ),
      TestDescriptor(
        'constNameComma',
        'const a,',
        [
          ParserErrorCode.missingIdentifier,
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.constNotInitialized,
        ],
        "const a, _s_;",
        failing: ['functionNonVoid', 'getter'],
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.constNotInitialized,
          CompileTimeErrorCode.constNotInitialized,
        ],
      ),
      TestDescriptor(
        'constTypeNameComma',
        'const int a,',
        [
          ParserErrorCode.missingIdentifier,
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.constNotInitialized,
        ],
        "const int a, _s_;",
        failing: ['functionNonVoid', 'getter'],
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.constNotInitialized,
          CompileTimeErrorCode.constNotInitialized,
        ],
      ),
      TestDescriptor(
        'constNameCommaName',
        'const a, b',
        [
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.constNotInitialized,
          CompileTimeErrorCode.constNotInitialized,
        ],
        "const a, b;",
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.constNotInitialized,
          CompileTimeErrorCode.constNotInitialized,
        ],
      ),
      TestDescriptor(
        'constTypeNameCommaName',
        'const int a, b',
        [
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.constNotInitialized,
          CompileTimeErrorCode.constNotInitialized,
        ],
        "const int a, b;",
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.constNotInitialized,
          CompileTimeErrorCode.constNotInitialized,
        ],
      ),
      TestDescriptor(
        'final',
        'final',
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
        "final _s_;",
        failing: [
          'class',
          'enum',
          'functionVoid',
          'functionNonVoid',
          'getter',
          'mixin',
          'setter',
        ],
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.finalNotInitialized,
        ],
      ),
      TestDescriptor(
        'finalName',
        'final a',
        [
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.finalNotInitialized,
        ],
        "final a;",
        failing: ['functionNonVoid', 'getter', 'setter', 'mixin'],
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.finalNotInitialized,
        ],
      ),
      TestDescriptor(
        'finalTypeName',
        'final int a',
        [
          ParserErrorCode.expectedToken,
          CompileTimeErrorCode.finalNotInitialized,
        ],
        "final int a;",
        expectedDiagnosticsInValidCode: [
          CompileTimeErrorCode.finalNotInitialized,
        ],
      ),
      TestDescriptor(
        'type',
        'int',
        [
          ParserErrorCode.missingConstFinalVarOrType,
          ParserErrorCode.expectedToken,
        ],
        "int _s_;",
        allFailing: true,
      ),
      TestDescriptor('typeName', 'int a', [
        ParserErrorCode.expectedToken,
      ], "int a;"),
      TestDescriptor(
        'var',
        'var',
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
        "var _s_;",
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'setter'],
      ),
      TestDescriptor(
        'varName',
        'var a',
        [ParserErrorCode.expectedToken],
        "var a;",
        failing: ['functionNonVoid', 'getter', 'mixin', 'setter'],
      ),
      TestDescriptor(
        'varNameEquals',
        'var a =',
        [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
        "var a = _s_;",
        failing: [
          'class',
          'typedef',
          'functionVoid',
          'functionNonVoid',
          'const',
          'enum',
          'getter',
          'mixin',
          'setter',
        ],
      ),
      TestDescriptor('varNameEqualsExpression', 'var a = b', [
        ParserErrorCode.expectedToken,
      ], "var a = b;"),
    ], PartialCodeTest.declarationSuffixes);
  }
}
