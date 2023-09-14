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
    newFile2('$testPackageRootPath/lib/lib.dart', '''
library lib;
part '$testFileName';
''');
    await assertDiagnostics(
      r'''
part of lib;
''',
      [
        lint(0, 12),
      ],
    );
  }

  test_part_of_with_string() async {
    newFile2('$testPackageRootPath/lib/lib.dart', '''
part '$testFileName';
''');
    await assertNoDiagnostics(r'''
part of 'lib.dart';
''');
  }
}
