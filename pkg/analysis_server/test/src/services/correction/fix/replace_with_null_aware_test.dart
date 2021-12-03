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

  @override
  String? get testPackageLanguageVersion => '2.9';

  Future<void> test_chain() async {
    await resolveTestCode('''
void f(x) {
  x?.a.b.c;
}
''');
    await assertHasFix('''
void f(x) {
  x?.a?.b?.c;
}
''');
  }

  Future<void> test_methodInvocation() async {
    await resolveTestCode('''
void f(x) {
  x?.a.b();
}
''');
    await assertHasFix('''
void f(x) {
  x?.a?.b();
}
''');
  }

  Future<void> test_propertyAccess() async {
    await resolveTestCode('''
void f(x) {
  x?.a().b;
}
''');
    await assertHasFix('''
void f(x) {
  x?.a()?.b;
}
''');
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
