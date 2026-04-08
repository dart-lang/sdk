// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateNoSuchMethodTest);
  });
}

@reflectiveTest
class CreateNoSuchMethodTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createNoSuchMethod;

  Future<void> test_class() async {
    await resolveTestCode('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}
}
''');
    await assertHasFix('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_class_emptyBody_braces_adjacent() async {
    await resolveTestCode('''
abstract class A {
  m1();
  int m2();
}

class B extends A {}
''');
    await assertHasFix('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_class_emptyBody_braces_nonAdjacent() async {
    await resolveTestCode('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
}
''');
    await assertHasFix('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_class_emptyBody_semicolon() async {
    await resolveTestCode('''
abstract class A {
  m1();
  int m2();
}

class B extends A;
''');
    await assertHasFix('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_class_lint_alwaysDeclareReturnTypes() async {
    createAnalysisOptionsFile(lints: [LintNames.always_declare_return_types]);

    await resolveTestCode('''
abstract class A {
  void m1();
  int m2();
}

class B extends A {
  void existing() {}
}
''');
    await assertHasFix('''
abstract class A {
  void m1();
  int m2();
}

class B extends A {
  void existing() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_class_lint_alwaysDeclareReturnTypes_avoidDynamic() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.always_declare_return_types,
        LintNames.avoid_annotating_with_dynamic,
      ],
    );
    await resolveTestCode('''
abstract class A {
  void m1();
  int m2();
}

class B extends A {
  void existing() {}
}
''');
    await assertHasFix('''
abstract class A {
  void m1();
  int m2();
}

class B extends A {
  void existing() {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_classTypeAlias() async {
    await resolveTestCode('''
abstract mixin class A {
  m();
}

class B = Object with A;
''');
    await assertNoFix();
  }
}
