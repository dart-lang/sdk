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

  Future<void> test_immutable_instanceCreation() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@Immutable()
f() {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

f() {}
''');
  }

  Future<void> test_invalidAnnotationTarget() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  static int f = 0;
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  static int f = 0;
}
''');
  }

  Future<void> test_invalidAnnotationTarget_prefixed() async {
    await resolveTestCode('''
import 'package:meta/meta.dart' as meta;

class A {
  @meta.mustBeOverridden
  static int f = 0;
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart' as meta;

class A {
  static int f = 0;
}
''');
  }

  Future<void> test_invalidInternalAnnotation() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@internal
class A {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {}
''');
  }

  Future<void> test_invalidNonVirtualAnnotation() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@nonVirtual
class A {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {}
''');
  }

  Future<void> test_invalidNonVisibilityAnnotation() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class C {
  @visibleForTesting C._() {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class C {
  C._() {}
}
''');
  }

  Future<void> test_invalidVisibleForOverridingAnnotation() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

@visibleForOverriding
class C {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class C {}
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
  String name = '';
}
''');
    await assertHasFix('''
class A {
  String name = '';
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

  Future<void> test_redeclare_invalidTarget() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class C {
  @redeclare
  void m() {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class C {
  void m() {}
}
''');
  }

  Future<void> test_redeclare_notRedeclaring() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  int get i => 0;
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  int get i => 0;
}
''');
  }

  test_reopen() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {}

@reopen
base class B extends A {}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {}

base class B extends A {}
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
