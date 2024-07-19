// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseStringInPartOfDirectivesTest);
  });
}

@reflectiveTest
class UseStringInPartOfDirectivesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'use_string_in_part_of_directives';

  test_part_of_with_library_name() async {
    newFile('$testPackageRootPath/lib/lib.dart', '''
library lib;
part '$testFileName';
''');
    await assertNoDiagnostics(r'''
part of lib;
''');
  }

  test_part_of_with_library_name_preEnhancedParts() async {
    newFile('$testPackageRootPath/lib/lib.dart', '''
// @dart = 3.4
// (pre enhanced-parts)

library lib;
part '$testFileName';
''');
    await assertDiagnostics(
      r'''
// @dart = 3.4
// (pre enhanced-parts)

part of lib;
''',
      [
        lint(40, 12),
      ],
    );
  }

  test_part_of_with_string() async {
    newFile('$testPackageRootPath/lib/lib.dart', '''
part '$testFileName';
''');
    await assertNoDiagnostics(r'''
part of 'lib.dart';
''');
  }
}
