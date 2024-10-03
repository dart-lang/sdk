// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameMethodParameterTest);
  });
}

@reflectiveTest
class RenameMethodParameterTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.RENAME_METHOD_PARAMETER;

  @override
  String get lintCode => LintNames.avoid_renaming_method_parameters;

  Future<void> test_local_variable() async {
    await resolveTestCode('''
class A {
  void m(a) {}
}
class B extends A {
  void m(b) {
    var a = '';
    print(a);
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_member() async {
    await resolveTestCode('''
class A {
  void m(a) {}
}
class B extends A {
  int? a;

  void m(b) {
    a = 1;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_rename() async {
    await resolveTestCode('''
class A {
  void m(a, b, c) {}
}
class B extends A {
  void m(a, d, c) {}
}
''');
    await assertHasFix('''
class A {
  void m(a, b, c) {}
}
class B extends A {
  void m(a, b, c) {}
}
''');
  }

  Future<void> test_shadowed() async {
    await resolveTestCode('''
class A {
  void m(a) {}
}
class B extends A {
  void m(b) {
    print(b);
    if (b > 0) {
      var b = 0;
      print(b);
    }
  }
}
''');
    await assertHasFix('''
class A {
  void m(a) {}
}
class B extends A {
  void m(a) {
    print(a);
    if (a > 0) {
      var b = 0;
      print(b);
    }
  }
}
''');
  }

  Future<void> test_topLevel() async {
    await resolveTestCode('''
int? a;
class A {
  void m(a) {}
}
class B extends A {
  void m(b) {
    a = 1;
  }
}
''');
    await assertNoFix();
  }
}
