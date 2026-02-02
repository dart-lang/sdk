// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

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
        [diag.missingIdentifier, diag.expectedToken],
        "const _s_;",
        failing: [
          'class',
          'functionVoid',
          'functionNonVoid',
          'getter',
          'setter',
        ],
      ),
      TestDescriptor(
        'constName',
        'const a',
        [diag.expectedToken],
        "const a;",
        failing: ['functionNonVoid', 'getter', 'setter', 'mixin'],
      ),
      TestDescriptor('constTypeName', 'const int a', [
        diag.expectedToken,
      ], "const int a;"),
      TestDescriptor(
        'constNameComma',
        'const a,',
        [diag.missingIdentifier, diag.expectedToken],
        "const a, _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor(
        'constTypeNameComma',
        'const int a,',
        [diag.missingIdentifier, diag.expectedToken],
        "const int a, _s_;",
        failing: ['functionNonVoid', 'getter'],
      ),
      TestDescriptor('constNameCommaName', 'const a, b', [
        diag.expectedToken,
      ], "const a, b;"),
      TestDescriptor('constTypeNameCommaName', 'const int a, b', [
        diag.expectedToken,
      ], "const int a, b;"),
      TestDescriptor(
        'final',
        'final',
        [diag.missingIdentifier, diag.expectedToken],
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
      ),
      TestDescriptor(
        'finalName',
        'final a',
        [diag.expectedToken],
        "final a;",
        failing: ['functionNonVoid', 'getter', 'setter', 'mixin'],
      ),
      TestDescriptor('finalTypeName', 'final int a', [
        diag.expectedToken,
      ], "final int a;"),
      TestDescriptor(
        'type',
        'int',
        [diag.missingConstFinalVarOrType, diag.expectedToken],
        "int _s_;",
        allFailing: true,
      ),
      TestDescriptor('typeName', 'int a', [diag.expectedToken], "int a;"),
      TestDescriptor(
        'var',
        'var',
        [diag.missingIdentifier, diag.expectedToken],
        "var _s_;",
        failing: ['functionVoid', 'functionNonVoid', 'getter', 'setter'],
      ),
      TestDescriptor(
        'varName',
        'var a',
        [diag.expectedToken],
        "var a;",
        failing: ['functionNonVoid', 'getter', 'mixin', 'setter'],
      ),
      TestDescriptor(
        'varNameEquals',
        'var a =',
        [diag.missingIdentifier, diag.expectedToken],
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
        diag.expectedToken,
      ], "var a = b;"),
    ], PartialCodeTest.declarationSuffixes);
  }
}
