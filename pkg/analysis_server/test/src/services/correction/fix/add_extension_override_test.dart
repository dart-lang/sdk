// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddExtensionOverrideTest);
  });
}

@reflectiveTest
class AddExtensionOverrideTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_EXTENSION_OVERRIDE;

  Future<void> test_method() async {
    await resolveTestCode('''
extension E on int {
  void foo() {}
}
extension E2 on int {
  void foo() {}
}
f() {
  0.foo();
}
''');
    await assertHasFix('''
extension E on int {
  void foo() {}
}
extension E2 on int {
  void foo() {}
}
f() {
  E(0).foo();
}
''', matchFixMessage: "Add an extension override for 'E'");

    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Add an extension override for 'E'",
        "Add an extension override for 'E2'",
      ],
    );
  }

  Future<void> test_no_name() async {
    await resolveTestCode('''
extension E on int {
  int get a => 1;
}
extension on int {
  set a(int v) {}
}
f() {
  0.a;
}
''');
    await assertHasFix(
      '''
extension E on int {
  int get a => 1;
}
extension on int {
  set a(int v) {}
}
f() {
  E(0).a;
}
''',
      expectedNumberOfFixesForKind: 1,
      errorFilter: (error) {
        return error.errorCode ==
            CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_TWO;
      },
    );
  }

  Future<void> test_no_parentheses() async {
    await resolveTestCode('''
extension E on int {
  int get a => 1;
}
extension E2 on int {
  set a(int v) {}
}
f() {
  0.a;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 1;
}
extension E2 on int {
  set a(int v) {}
}
f() {
  E(0).a;
}
''');

    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Add an extension override for 'E'",
        "Add an extension override for 'E2'",
      ],
    );
  }

  Future<void> test_noTarget() async {
    await resolveTestCode('''
abstract class A {
  void m() {
    value;
  }
}

extension E on A {
  int value() => 0;
}

extension E2 on A {
  int get value => 0;
}
''');
    await assertHasFix(
      '''
abstract class A {
  void m() {
    E2(this).value;
  }
}

extension E on A {
  int value() => 0;
}

extension E2 on A {
  int get value => 0;
}
''',
      matchFixMessage: "Add an extension override for 'E2'",
      errorFilter:
          (error) =>
              error.errorCode ==
              CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_TWO,
    );
  }

  Future<void> test_parentheses() async {
    await resolveTestCode('''
extension E on int {
  int get a => 1;
}
extension E2 on int {
  set a(int v) {}
}
f() {
  (0).a;
}
''');
    await assertHasFix('''
extension E on int {
  int get a => 1;
}
extension E2 on int {
  set a(int v) {}
}
f() {
  E(0).a;
}
''');

    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Add an extension override for 'E'",
        "Add an extension override for 'E2'",
      ],
    );
  }
}
