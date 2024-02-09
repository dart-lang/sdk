// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithNullAwareTest);
    defineReflectiveTests(UncheckedMethodInvocationOfNullableValueTest);
    defineReflectiveTests(UncheckedPropertyAccessOfNullableValueTest);
  });
}

@reflectiveTest
class ReplaceWithNullAwareTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_NULL_AWARE;

  Future<void> test_indexExpression() async {
    await resolveTestCode('''
void f(List<int>? l) {
  l[0];
}
''');
    await assertHasFix('''
void f(List<int>? l) {
  l?[0];
}
''');
  }

  Future<void> test_indexExpression_cascade() async {
    await resolveTestCode('''
void f(List<int>? l) {
  l..[0]..length;
}
''');
    await assertHasFix(
      '''
void f(List<int>? l) {
  l?..[0]..length;
}
''',
      errorFilter: (error) => error.length == 6,
      matchFixMessage: "Replace the '..' with a '?..' in the invocation",
    );
  }

  Future<void> test_methodInvocation_cascade() async {
    await resolveTestCode('''
void f(int? i) {
  i..toInt()..abs();
}
''');
    await assertHasFix(
      '''
void f(int? i) {
  i?..toInt()..abs();
}
''',
      errorFilter: (error) => error.length == 3,
      matchFixMessage: "Replace the '..' with a '?..' in the invocation",
    );
  }

  Future<void> test_propertyAccess_cascade() async {
    await resolveTestCode('''
void f(int? i) {
  (i)..isEven..abs();
}
''');
    await assertHasFix(
      '''
void f(int? i) {
  (i)?..isEven..abs();
}
''',
      errorFilter: (error) => error.length == 3,
      matchFixMessage: "Replace the '..' with a '?..' in the invocation",
    );
  }

  Future<void> test_propertyAccess_parentCascade() async {
    await resolveTestCode('''
void f(List<int>? l) {
  l..length..[0];
}
''');
    await assertHasFix(
      '''
void f(List<int>? l) {
  l?..length..[0];
}
''',
      errorFilter: (error) => error.length == 1,
      matchFixMessage: "Replace the '..' with a '?..' in the invocation",
    );
  }
}

@reflectiveTest
class UncheckedMethodInvocationOfNullableValueTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_NULL_AWARE;

  Future<void> test_method() async {
    await resolveTestCode('''
class C {
  List<int>? values;

  void m() {
    if (values != null) {
      print(values.toList());
    }
  }
}
''');
    await assertHasFix('''
class C {
  List<int>? values;

  void m() {
    if (values != null) {
      print(values?.toList());
    }
  }
}
''');
  }
}

@reflectiveTest
class UncheckedPropertyAccessOfNullableValueTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_NULL_AWARE;

  Future<void> test_prefixedIdentifier() async {
    await resolveTestCode('''
class C {
  List<int>? values;

  void m() {
    if (values != null) {
      print(values.length);
    }
  }
}
''');
    await assertHasFix('''
class C {
  List<int>? values;

  void m() {
    if (values != null) {
      print(values?.length);
    }
  }
}
''');
  }

  Future<void> test_propertyAccess() async {
    await resolveTestCode('''
class C {
  List<int>? values;

  void m() {
    if (values != null) {
      print((values).length);
    }
  }
}
''');
    await assertHasFix('''
class C {
  List<int>? values;

  void m() {
    if (values != null) {
      print((values)?.length);
    }
  }
}
''');
  }
}
