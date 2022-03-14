// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLeadingUnderscoreBulkTest);
    defineReflectiveTests(RemoveLeadingUnderscoreForLibraryPrefixesTest);
    defineReflectiveTests(RemoveLeadingUnderscoreForLocalVariablesTest);
  });
}

@reflectiveTest
class RemoveLeadingUnderscoreBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.no_leading_underscores_for_local_identifiers;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
main() {
  int _foo = 42;
  print(_foo);
  [0, 1, 2].forEach((_bar) {
    print(_bar);
  });
}
''');
    await assertHasFix('''
main() {
  int foo = 42;
  print(foo);
  [0, 1, 2].forEach((bar) {
    print(bar);
  });
}
''');
  }
}

@reflectiveTest
class RemoveLeadingUnderscoreForLibraryPrefixesTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_LEADING_UNDERSCORE;

  @override
  String get lintCode => LintNames.no_leading_underscores_for_library_prefixes;

  Future<void> test_importPrefix() async {
    await resolveTestCode('''
import 'dart:core' as _core;
_core.int i = 1;
''');
    await assertHasFix('''
import 'dart:core' as core;
core.int i = 1;
''');
  }
}

@reflectiveTest
class RemoveLeadingUnderscoreForLocalVariablesTest
    extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_LEADING_UNDERSCORE;

  @override
  String get lintCode => LintNames.no_leading_underscores_for_local_identifiers;

  Future<void> test_localVariable() async {
    await resolveTestCode('''
void f() {
  var _foo = 1;
  print(_foo);
}
''');
    await assertHasFix('''
void f() {
  var foo = 1;
  print(foo);
}
''');
  }

  Future<void> test_parameter_closure() async {
    await resolveTestCode('''
void f() {
  [0, 1, 2].forEach((_foo) {
    print(_foo);
  });
}
''');
    await assertHasFix('''
void f() {
  [0, 1, 2].forEach((foo) {
    print(foo);
  });
}
''');
  }

  Future<void> test_parameter_function() async {
    await resolveTestCode('''
void f(int _foo) {
  print(_foo);
}
''');
    await assertHasFix('''
void f(int foo) {
  print(foo);
}
''');
  }

  Future<void> test_parameter_method() async {
    await resolveTestCode('''
class A {
  void f(int _foo) {
    print(_foo);
  }
}
''');
    await assertHasFix('''
class A {
  void f(int foo) {
    print(foo);
  }
}
''');
  }

  Future<void> test_parameter_optionalNamed() async {
    await resolveTestCode('''
void f({int? _foo}) {
  print(_foo);
}
''');
    await assertNoFix();
  }

  Future<void> test_parameter_optionalPositional() async {
    await resolveTestCode('''
void f([int? _foo]) {
  print(_foo);
}
''');
    await assertHasFix('''
void f([int? foo]) {
  print(foo);
}
''');
  }
}
