// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveConstructorTest_extension);
    defineReflectiveTests(RemoveConstructorTest_mixin);
  });
}

@reflectiveTest
class RemoveConstructorTest_extension extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONSTRUCTOR;

  Future<void> test_betweenFields() async {
    await resolveTestCode('''
extension E on int {
  static int foo = 0;

  E();

  static int bar = 0;
}
''');
    await assertHasFix('''
extension E on int {
  static int foo = 0;

  static int bar = 0;
}
''');
  }

  Future<void> test_betweenMethods() async {
    await resolveTestCode('''
extension E on int {
  void foo() {}

  E();

  void bar() {}
}
''');
    await assertHasFix('''
extension E on int {
  void foo() {}

  void bar() {}
}
''');
  }

  Future<void> test_factory_named() async {
    await resolveTestCode('''
extension E on int {
  factory E.named() => throw 0;
}
''');
    await assertHasFix('''
extension E on int {
}
''');
  }

  Future<void> test_factory_unnamed() async {
    await resolveTestCode('''
extension E on int {
  factory E() => throw 0;
}
''');
    await assertHasFix('''
extension E on int {
}
''');
  }

  Future<void> test_generative_named() async {
    await resolveTestCode('''
extension E on int {
  E.named();
}
''');
    await assertHasFix('''
extension E on int {
}
''');
  }

  Future<void> test_generative_unnamed() async {
    await resolveTestCode('''
extension E on int {
  E();
}
''');
    await assertHasFix('''
extension E on int {
}
''');
  }
}

@reflectiveTest
class RemoveConstructorTest_mixin extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONSTRUCTOR;

  Future<void> test_betweenFields() async {
    await resolveTestCode('''
mixin M {
  static int foo = 0;

  M();

  static int bar = 0;
}
''');
    await assertHasFix('''
mixin M {
  static int foo = 0;

  static int bar = 0;
}
''');
  }

  Future<void> test_betweenMethods() async {
    await resolveTestCode('''
mixin M {
  void foo() {}

  M();

  void bar() {}
}
''');
    await assertHasFix('''
mixin M {
  void foo() {}

  void bar() {}
}
''');
  }

  Future<void> test_factory_named() async {
    await resolveTestCode('''
mixin M {
  factory M.named() => throw 0;
}
''');
    await assertHasFix('''
mixin M {
}
''');
  }

  Future<void> test_factory_unnamed() async {
    await resolveTestCode('''
mixin M {
  factory M() => throw 0;
}
''');
    await assertHasFix('''
mixin M {
}
''');
  }

  Future<void> test_generative_named() async {
    await resolveTestCode('''
mixin M {
  M.named();
}
''');
    await assertHasFix('''
mixin M {
}
''');
  }

  Future<void> test_generative_unnamed() async {
    await resolveTestCode('''
mixin M {
  M();
}
''');
    await assertHasFix('''
mixin M {
}
''');
  }
}
