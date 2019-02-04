// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
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
    addMetaPackage();
  }

  test_factory() async {
    await resolveTestUnit('''
import 'package:meta/meta.dart';

@factory
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }

  test_immutable() async {
    await resolveTestUnit('''
import 'package:meta/meta.dart';

@immutable
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }

  test_literal() async {
    await resolveTestUnit('''
import 'package:meta/meta.dart';

@literal
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }

  test_override_field() async {
    await resolveTestUnit('''
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

  test_override_getter() async {
    await resolveTestUnit('''
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

  test_override_method() async {
    await resolveTestUnit('''
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

  test_override_setter() async {
    await resolveTestUnit('''
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

  test_required_namedWithDefault() async {
    await resolveTestUnit('''
import 'package:meta/meta.dart';

f({@required int x = 0}) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f({int x = 0}) {}
''');
  }

  test_required_positional() async {
    await resolveTestUnit('''
import 'package:meta/meta.dart';

f([@required int x]) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f([int x]) {}
''');
  }

  test_required_required() async {
    await resolveTestUnit('''
import 'package:meta/meta.dart';

f(@required int x) {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f(int x) {}
''');
  }

  test_sealed() async {
    await resolveTestUnit('''
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
