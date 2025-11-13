// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
  FixKind get kind => DartFixKind.addExtensionOverride;

  Future<void> test_getter() async {
    newFile('$testPackageLibPath/ext1.dart', '''
extension StringExt1 on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
''');
    newFile('$testPackageLibPath/ext2.dart', '''
extension StringExt2 on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
''');
    await resolveTestCode('''
import 'ext1.dart';
import 'ext2.dart';

void f(String str) {
  str.nullIfEmpty;
}
''');
    await assertHasFix(
      '''
import 'ext1.dart';
import 'ext2.dart';

void f(String str) {
  StringExt1(str).nullIfEmpty;
}
''',
      matchFixMessage: "Add an extension override for 'StringExt1'",
      filter: (error) =>
          error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo,
    );

    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Add an extension override for 'StringExt1'",
        "Add an extension override for 'StringExt2'",
      ],
      filter: (error) =>
          error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo,
    );
  }

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
      filter: (error) {
        return error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo;
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

  Future<void> test_noTarget_insideExtension() async {
    await resolveTestCode('''
abstract class A {}

extension on A {
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
abstract class A {}

extension on A {
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
      filter: (error) =>
          error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo,
    );
  }

  Future<void> test_noTarget_lateFinal() async {
    await resolveTestCode('''
abstract class A {
  late final myValue = value;
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
  late final myValue = E2(this).value;
}

extension E on A {
  int value() => 0;
}

extension E2 on A {
  int get value => 0;
}
''',
      matchFixMessage: "Add an extension override for 'E2'",
      filter: (error) =>
          error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo,
    );
  }

  Future<void> test_noTarget_method() async {
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
      filter: (error) =>
          error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo,
    );
  }

  Future<void> test_otherType() async {
    await resolveTestCode('''
extension E on int {
  void foo() {}
}
extension E2 on int {
  void foo() {}
}
extension E3 on String {
  void foo() {}
}
f() {
  0.foo();
}
''');

    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Add an extension override for 'E'",
        "Add an extension override for 'E2'",
      ],
    );

    await assertHasFix('''
extension E on int {
  void foo() {}
}
extension E2 on int {
  void foo() {}
}
extension E3 on String {
  void foo() {}
}
f() {
  E(0).foo();
}
''', matchFixMessage: "Add an extension override for 'E'");
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

  Future<void> test_setter() async {
    newFile('$testPackageLibPath/ext1.dart', '''
extension StringExt1 on String {
  set foo(String? value) {}
}
''');
    newFile('$testPackageLibPath/ext2.dart', '''
extension StringExt2 on String {
  set foo(String? value) {}
}
''');
    await resolveTestCode('''
import 'ext1.dart';
import 'ext2.dart';

void f(String str) {
  str.foo = 0;
}
''');
    await assertHasFix(
      '''
import 'ext1.dart';
import 'ext2.dart';

void f(String str) {
  StringExt1(str).foo = 0;
}
''',
      matchFixMessage: "Add an extension override for 'StringExt1'",
      filter: (error) =>
          error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo,
    );

    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Add an extension override for 'StringExt1'",
        "Add an extension override for 'StringExt2'",
      ],
      filter: (error) =>
          error.diagnosticCode == diag.ambiguousExtensionMemberAccessTwo,
    );
  }
}
