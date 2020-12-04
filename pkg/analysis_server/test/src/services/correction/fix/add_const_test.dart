// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddConstTest);
    defineReflectiveTests(AddConstToImmutableConstructorTest);
  });
}

@reflectiveTest
class AddConstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_CONST;

  @override
  String get lintCode => LintNames.prefer_const_constructors;

  Future<void> test_new() async {
    await resolveTestCode('''
class C {
  const C();
}
main() {
  var c = new C();
  print(c);
}
''');
    // handled by REPLACE_NEW_WITH_CONST
    await assertNoFix();
  }

  Future<void> test_noKeyword() async {
    await resolveTestCode('''
class C {
  const C();
}
main() {
  var c = C();
  print(c);
}
''');
    await assertHasFix('''
class C {
  const C();
}
main() {
  var c = const C();
  print(c);
}
''');
  }
}

@reflectiveTest
class AddConstToImmutableConstructorTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_CONST;

  @override
  String get lintCode => LintNames.prefer_const_constructors_in_immutables;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      meta: true,
    );
  }

  Future<void> test_constConstructor() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class A {
  A();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class A {
  const A();
}
''');
  }

  Future<void> test_constConstructorWithComment() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
class A {
  /// Comment.
  A();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

@immutable
class A {
  /// Comment.
  const A();
}
''');
  }
}
