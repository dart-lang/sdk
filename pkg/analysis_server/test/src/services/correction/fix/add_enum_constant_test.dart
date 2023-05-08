// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddEnumConstantTest);
  });
}

@reflectiveTest
class AddEnumConstantTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_ENUM_CONSTANT;

  Future<void> test_add() async {
    await resolveTestCode('''
enum E {ONE}

E e() {
  return E.TWO;
}
''');
    await assertHasFix('''
enum E {ONE, TWO}

E e() {
  return E.TWO;
}
''', matchFixMessage: "Add enum constant 'TWO'");
  }

  Future<void> test_differentLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
enum E {ONE}
''');

    await resolveTestCode('''
import 'a.dart';

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {ONE, TWO}
''', target: '$testPackageLibPath/a.dart');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(), TWO.named();

  const E.named();
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_named_factory() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE.named(), TWO.named();

  const E.named();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_named_named() async {
    await resolveTestCode('''
enum E {
  ONE.something(), TWO.other();

  const E.something();
  const E.other();
}

E e() {
  return E.THREE;
}
''');

    await assertNoFix();
  }

  Future<void> test_named_non_zero() async {
    await resolveTestCode('''
enum E {
  ONE.named(1);

  final int i;
  const E.named(this.i);
}

E e() {
  return E.TWO;
}
''');

    await assertNoFix();
  }

  Future<void> test_named_unnamed() async {
    await resolveTestCode('''
enum E {
  ONE.named();

  const E.named();
  const E();
}

E e() {
  return E.TWO;
}
''');

    await assertNoFix();
  }

  Future<void> test_unnamed() async {
    await resolveTestCode('''
enum E {
  ONE;

  const E();
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE, TWO;

  const E();
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_unnamed_factory() async {
    await resolveTestCode('''
enum E {
  ONE;

  const E();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');

    await assertHasFix('''
enum E {
  ONE, TWO;

  const E();
  factory E.f() => ONE;
}

E e() {
  return E.TWO;
}
''');
  }

  Future<void> test_unnamed_non_zero() async {
    await resolveTestCode('''
enum E {
  ONE(1);

  final int i;
  const E(this.i);
}

E e() {
  return E.TWO;
}
''');

    await assertNoFix();
  }
}
