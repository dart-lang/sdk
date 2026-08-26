// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithPartOfUriNestedTest);
    defineReflectiveTests(ReplaceWithPartOfUriSecondTest);
    defineReflectiveTests(ReplaceWithPartOfUriTest);
  });
}

@reflectiveTest
class ReplaceWithPartOfUriNestedTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithPartOfUri;

  @override
  String get lintCode => LintNames.use_string_in_part_of_directives;

  /// The path to the test file, which, for this class, is in the test package's
  /// `lib/nested` directory.
  @override
  String get testFilePath =>
      getFile('$testPackageLibPath/nested/test.dart').path;

  Future<void> test_packageLib_parentDirectory() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
// (pre enhanced-parts)

library my.lib;
part 'nested/test.dart';
''');

    await resolveTestCode('''
// @dart = 3.4
// (pre enhanced-parts)

part of my.lib;

class A {}
''');

    await assertHasFix('''
// @dart = 3.4
// (pre enhanced-parts)

part of '../a.dart';

class A {}
''');
  }
}

@reflectiveTest
class ReplaceWithPartOfUriSecondTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithPartOfUri;

  @override
  String get lintCode => LintNames.use_string_in_part_of_directives;

  /// The path to the test file, which, for this class, is in the test package's
  /// `lib/second` directory.
  @override
  String get testFilePath =>
      getFile('$testPackageLibPath/second/test.dart').path;

  Future<void> test_packageLib_siblingDirectory() async {
    newFile('$testPackageLibPath/first/a.dart', r'''
// @dart = 3.4
// (pre enhanced-parts)

library my.lib;
part '../second/test.dart';
''');

    await resolveTestCode('''
// @dart = 3.4
// (pre enhanced-parts)

part of my.lib;

class A {}
''');

    await assertHasFix('''
// @dart = 3.4
// (pre enhanced-parts)

part of '../first/a.dart';

class A {}
''');
  }
}

@reflectiveTest
class ReplaceWithPartOfUriTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithPartOfUri;

  @override
  String get lintCode => LintNames.use_string_in_part_of_directives;

  Future<void> test_packageLib_nestedDirectory() async {
    newFile('$testPackageLibPath/nested/a.dart', r'''
// @dart = 3.4
// (pre enhanced-parts)

library my.lib;
part '../test.dart';
''');

    await resolveTestCode('''
// @dart = 3.4
// (pre enhanced-parts)

part of my.lib;

class A {}
''');

    await assertHasFix('''
// @dart = 3.4
// (pre enhanced-parts)

part of 'nested/a.dart';

class A {}
''');
  }

  Future<void> test_packageLib_sameDirectory() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 3.4
// (pre enhanced-parts)

library my.lib;
part 'test.dart';
''');

    await resolveTestCode('''
// @dart = 3.4
// (pre enhanced-parts)

part of my.lib;

class A {}
''');

    await assertHasFix('''
// @dart = 3.4
// (pre enhanced-parts)

part of 'a.dart';

class A {}
''');
  }
}
