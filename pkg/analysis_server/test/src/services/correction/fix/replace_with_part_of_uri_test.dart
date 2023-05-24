// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithPartOfUriTest);
  });
}

@reflectiveTest
class ReplaceWithPartOfUriTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_PART_OF_URI;

  @override
  String get lintCode => LintNames.use_string_in_part_of_directives;

  Future<void> test_packageLib_nestedDirectory() async {
    newFile('$testPackageLibPath/nested/a.dart', r'''
library my.lib;
part '../test.dart';
''');

    await resolveTestCode('''
part of my.lib;

class A {} 
''');

    await assertHasFix('''
part of 'nested/a.dart';

class A {} 
''');
  }

  Future<void> test_packageLib_parentDirectory() async {
    newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'nested/test.dart';
''');

    testFile = '$testPackageLibPath/nested/test.dart';

    await resolveTestCode('''
part of my.lib;

class A {} 
''');

    await assertHasFix('''
part of '../a.dart';

class A {} 
''');
  }

  Future<void> test_packageLib_sameDirectory() async {
    newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'test.dart';
''');

    await resolveTestCode('''
part of my.lib;

class A {} 
''');

    await assertHasFix('''
part of 'a.dart';

class A {} 
''');
  }

  Future<void> test_packageLib_siblingDirectory() async {
    newFile('$testPackageLibPath/first/a.dart', r'''
library my.lib;
part '../second/test.dart';
''');

    testFile = '$testPackageLibPath/second/test.dart';

    await resolveTestCode('''
part of my.lib;

class A {} 
''');

    await assertHasFix('''
part of '../first/a.dart';

class A {} 
''');
  }
}
