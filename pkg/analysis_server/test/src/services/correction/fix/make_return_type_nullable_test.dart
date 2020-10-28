// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MakeReturnTypeNullableTest);
  });
}

@reflectiveTest
class MakeReturnTypeNullableTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.MAKE_RETURN_TYPE_NULLABLE;

  Future<void> test_function_async() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  Future<void> test_incompatibilityIsNotLimitedToNullability() async {
    await resolveTestUnit('''
int f() {
  return '';
}
''');
    await assertNoFix();
  }

  Future<void> test_localFunction_sync() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  Future<void> test_returnTypeHasTypeArguments() async {
    await resolveTestUnit('''
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
