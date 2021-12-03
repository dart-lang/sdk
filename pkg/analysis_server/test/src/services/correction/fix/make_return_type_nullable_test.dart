// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeReturnTypeNullableTest);
  });
}

@reflectiveTest
class MakeReturnTypeNullableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.MAKE_RETURN_TYPE_NULLABLE;

  Future<void> test_function_async() async {
    await resolveTestCode('''
Future<String> f(String? s) async {
  return s;
}
''');
    await assertHasFix('''
Future<String?> f(String? s) async {
  return s;
}
''');
  }

  Future<void> test_function_asyncStar() async {
    await resolveTestCode('''
Stream<String> f(String? s) async* {
  yield s;
}
''');
    await assertHasFix('''
Stream<String?> f(String? s) async* {
  yield s;
}
''');
  }

  Future<void> test_function_sync() async {
    await resolveTestCode('''
String f(String? s) {
  return s;
}
''');
    await assertHasFix('''
String? f(String? s) {
  return s;
}
''');
  }

  Future<void> test_function_syncStar() async {
    await resolveTestCode('''
Iterable<String> f(String? s) sync* {
  yield s;
}
''');
    await assertHasFix('''
Iterable<String?> f(String? s) sync* {
  yield s;
}
''');
  }

  Future<void> test_getter_sync() async {
    await resolveTestCode('''
class C {
  String? f;
  String get g => f;
}
''');
    await assertHasFix('''
class C {
  String? f;
  String? get g => f;
}
''');
  }

  /// This code is parsed in such a way that we find `void` as an `Expression`.
  /// But this expression is a name in a `NamedType`, and so `NamedType` has
  /// the `type`, but not `void` - its type is `null`. So, the producer should
  /// check for `null`, and don't expect that every expression has a type.
  Future<void> test_getter_sync_invalidVoid() async {
    await resolveTestCode('''
int f() {
  return void;
}
''');
    await assertNoFix(
      errorFilter: (e) =>
          e.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION,
    );
  }

  Future<void> test_incompatibilityIsNotLimitedToNullability() async {
    await resolveTestCode('''
int f() {
  return '';
}
''');
    await assertNoFix();
  }

  Future<void> test_localFunction_sync() async {
    await resolveTestCode('''
void f() {
  String g(String? s) {
    return s;
  }
  g(null);
}
''');
    await assertHasFix('''
void f() {
  String? g(String? s) {
    return s;
  }
  g(null);
}
''');
  }

  Future<void> test_method_sync() async {
    await resolveTestCode('''
class C {
  String m(String? s) {
    return s;
  }
}
''');
    await assertHasFix('''
class C {
  String? m(String? s) {
    return s;
  }
}
''');
  }

  Future<void> test_method_sync_inherited() async {
    await resolveTestCode('''
abstract class A {
  String m(String? s);
}

class B extends A {
  m(String? s) {
    return s;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_returnTypeHasTypeArguments() async {
    await resolveTestCode('''
List<String> f() {
  return null;
}
''');
    await assertHasFix('''
List<String>? f() {
  return null;
}
''');
  }
}
