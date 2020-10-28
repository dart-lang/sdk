// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveAnnotationTest);
  });
}

@reflectiveTest
class RemoveAnnotationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_ANNOTATION;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_factory() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@factory
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }

  Future<void> test_immutable() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@immutable
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }

  Future<void> test_literal() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@literal
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }

  Future<void> test_override_field() async {
    await resolveTestCode('''
class A {
  @override
  String name;
}
''');
    await assertHasFix('''
class A {
  String name;
}
''');
  }

  Future<void> test_override_getter() async {
    await resolveTestCode('''
class A {
  @override
  int get zero => 0;
}
''');
    await assertHasFix('''
class A {
  int get zero => 0;
}
''');
  }

  Future<void> test_override_method() async {
    await resolveTestCode('''
class A {
  @override
  void m() {}
}
''');
    await assertHasFix('''
class A {
  void m() {}
}
''');
  }

  Future<void> test_override_setter() async {
    await resolveTestCode('''
class A {
  @override
  set value(v) {}
}
''');
    await assertHasFix('''
class A {
  set value(v) {}
}
''');
  }

  Future<void> test_required_namedWithDefault() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

f({@required int x = 0}) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f({int x = 0}) {}
''');
  }

  Future<void> test_required_positional() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

f([@required int x]) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f([int x]) {}
''');
  }

  Future<void> test_required_required() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

f(@required int x) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f(int x) {}
''');
  }

  Future<void> test_sealed() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@sealed
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }
}
