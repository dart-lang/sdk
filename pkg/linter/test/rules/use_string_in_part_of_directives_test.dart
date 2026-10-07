// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseStringInPartOfDirectivesTest);
  });
}

@reflectiveTest
class UseStringInPartOfDirectivesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.use_string_in_part_of_directives;

  test_partOfWithLibraryName() async {
    newFile('$testPackageRootPath/lib/lib.dart', '''
library lib;
part '$testFileName';
''');
    await assertDiagnostics(
      r'''
part of lib;
''',
      [error(diag.partOfName, 8, 3)],
    );
  }

  test_partOfWithLibraryName_preEnhancedParts() async {
    newFile('$testPackageRootPath/lib/lib.dart', '''
// @dart = 3.4
// (pre enhanced-parts)

library lib;
part '$testFileName';
''');
    await assertDiagnosticsFromMarkup(r'''
// @dart = 3.4
// (pre enhanced-parts)

[!part of lib;!]
''');
  }

  test_partOfWithString() async {
    newFile('$testPackageRootPath/lib/lib.dart', '''
part '$testFileName';
''');
    await assertNoDiagnostics(r'''
part of 'lib.dart';
''');
  }

  test_partOfWithString_inSubpart() async {
    newFile('$testPackageRootPath/lib/lib.dart', '''
part 'part.dart';
''');
    newFile('$testPackageRootPath/lib/part.dart', '''
part of 'lib.dart';
part '$testFileName';
''');
    await assertNoDiagnostics(r'''
part of 'part.dart';
''');
  }
}
