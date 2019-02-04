// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveMethodDeclarationTest);
  });
}

@reflectiveTest
class RemoveMethodDeclarationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_METHOD_DECLARATION;

  @override
  String get lintCode => LintNames.unnecessary_override;

  test_getter() async {
    await resolveTestUnit('''
class A {
  int x;
}
class B extends A {
  @override
  int get /*LINT*/x => super.x;
}
''');
    await assertHasFix('''
class A {
  int x;
}
class B extends A {
}
''');
  }

  test_method() async {
    await resolveTestUnit('''
class A {
  @override
  String /*LINT*/toString() => super.toString();
}
''');
    await assertHasFix('''
class A {
}
''');
  }

  test_setter() async {
    await resolveTestUnit('''
class A {
  int x;
}
class B extends A {
  @override
  set /*LINT*/x(int other) {
    this.x = other;
  }
}
''');
    await assertHasFix('''
class A {
  int x;
}
class B extends A {
}
''');
  }
}
