// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SummaryTest);
  });
}

@reflectiveTest
class SummaryTest extends AbstractLspAnalysisServerTest {
  Future<void> test_class() async {
    await verifySummary(
      '''
/// A class.
final class C extends Object {
  /// A field;
  int f;

  C(this.f);

  factory C.s(String s) {
    return C(s.length);
  }

  int operator +(int i) => f + i;

  /// A getter.
  int get g => f;

  /// A setter.
  set s(int i) {}

  void m(int i) {
    print(f + i);
  }
}
''',
      '''
final class C extends Object {
  int f;
  C(this.f);
  factory C.s(String s);
  int get g;
  set s(int i);
  int operator +(int i);
  void m(int i);
}
''',
    );
  }

  Future<void> test_enum() async {
    await verifySummary(
      '''
/// An enum.
enum E {
  a(1), b(2);

  final int f;

  const E(this.f);

  void m(int i) {
    print(f + i);
  }
}
''',
      '''
enum E {
  a, b;
  final int f;
  const E(this.f);
  void m(int i);
}
''',
    );
  }

  Future<void> test_extension_named() async {
    await verifySummary(
      '''
/// An extension.
extension E on String {
  int get l => length;

  String m(String s) => this + s;
}
''',
      '''
extension E on String {
  int get l;
  String m(String s);
}
''',
    );
  }

  Future<void> test_extension_unnamed() async {
    await verifySummary(
      '''
extension on String {
  int get l => length;

  String m(String s) => this + s;
}
''',
      // Unnamed extensions are not part of the public API.
      '',
    );
  }

  Future<void> test_extensionType() async {
    await verifySummary(
      '''
/// An extension.
extension type E(int self) {
  int get negated => -self;
}
''',
      '''
extension type E(int self) {
  int get negated;
}
''',
    );
  }

  Future<void> test_imports() async {
    failTestOnErrorDiagnostic = false;
    await verifySummary(
      '''
import 'dart:async' show Stream;
import 'package:test/test.dart' as test;
import 'other.dart' deferred as o hide SomeClass;
''',
      '''
import 'dart:async' show Stream;
import 'package:test/test.dart' as test;
import 'package:test/other.dart' as o hide SomeClass;
''',
    );
  }

  Future<void> test_mixin() async {
    await verifySummary(
      '''
mixin M on List {
  int get l => length;
}
''',
      '''
mixin M on List {
  int get l;
}
''',
    );
  }

  Future<void> test_topLevelConstant() async {
    await verifySummary(
      '''
/// A top-level constant.
@zero
const int zero = 0;
''',
      '''
const int zero;
''',
    );
  }

  Future<void> test_topLevelFunction() async {
    await verifySummary(
      '''
/// A top-level function.
void f(int p) {
  print(p);
}
''',
      '''
void f(int p);
''',
    );
  }

  Future<void> test_topLevelGetter() async {
    await verifySummary(
      '''
/// A top-level getter.
int get g => 0;
''',
      '''
int get g;
''',
    );
  }

  Future<void> test_topLevelSetter() async {
    await verifySummary(
      '''
/// A top-level setter.
set s(int p) {
  // ...
}
''',
      '''
set s(int p);
''',
    );
  }

  Future<void> test_topLevelVariable() async {
    await verifySummary(
      '''
/// A top-level variable.
int zero = 0;
''',
      '''
int zero;
''',
    );
  }

  Future<void> test_typedef() async {
    await verifySummary(
      '''
/// A typedef
typedef F = int Function(String);
''',
      '''
typedef F = int Function(String);
''',
    );
  }

  Future<void> verifySummary(String code, String expectedSummary) async {
    await initialize();
    await openFile(mainFileUri, code);
    var res = (await getSummary(mainFileUri)).summary;

    expect(res, equals(expectedSummary));
  }
}
