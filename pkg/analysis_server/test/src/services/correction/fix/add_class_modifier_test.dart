// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddClassModifierBaseTest);
    defineReflectiveTests(AddClassModifierFinalTest);
    defineReflectiveTests(AddClassModifierSealedTest);
  });
}

@reflectiveTest
class AddClassModifierBaseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_CLASS_MODIFIER_BASE;

  Future<void> test_mixinSubtypeOfBaseIsNotBase() async {
    await resolveTestCode('''
base class A {}
mixin B implements A {}
''');
    await assertHasFix('''
base class A {}
base mixin B implements A {}
''');
  }

  Future<void> test_mixinSubtypeOfBaseIsNotBase_withDoc() async {
    await resolveTestCode('''
base class A {}
// Doc.
mixin B implements A {}
''');
    await assertHasFix('''
base class A {}
// Doc.
base mixin B implements A {}
''');
  }

  Future<void> test_mixinSubtypeOfFinalIsNotBase() async {
    await resolveTestCode('''
final class A {}
mixin B implements A {}
''');
    await assertHasFix('''
final class A {}
base mixin B implements A {}
''');
  }

  Future<void> test_subtypeOfBaseIsNotBaseFinalOrSealed() async {
    await resolveTestCode('''
base class A {}
class B extends A {}
''');
    await assertHasFix('''
base class A {}
base class B extends A {}
''');
  }

  Future<void> test_subtypeOfFinalIsNotBaseFinalOrSealed() async {
    await resolveTestCode('''
final class A {}
class B extends A {}
''');
    await assertHasFix('''
final class A {}
base class B extends A {}
''');
  }
}

@reflectiveTest
class AddClassModifierFinalTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_CLASS_MODIFIER_FINAL;

  Future<void> test_subtypeOfBaseIsNotBaseFinalOrSealed() async {
    await resolveTestCode('''
base class A {}
class B extends A {}
''');
    await assertHasFix('''
base class A {}
final class B extends A {}
''');
  }

  Future<void> test_subtypeOfFinalIsNotBaseFinalOrSealed() async {
    await resolveTestCode('''
final class A {}
class B extends A {}
''');
    await assertHasFix('''
final class A {}
final class B extends A {}
''');
  }
}

@reflectiveTest
class AddClassModifierSealedTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_CLASS_MODIFIER_SEALED;

  Future<void> test_subtypeOfBaseIsNotBaseFinalOrSealed() async {
    await resolveTestCode('''
base class A {}
class B extends A {}
''');
    await assertHasFix('''
base class A {}
sealed class B extends A {}
''');
  }

  Future<void> test_subtypeOfFinalIsNotBaseFinalOrSealed() async {
    await resolveTestCode('''
final class A {}
class B extends A {}
''');
    await assertHasFix('''
final class A {}
sealed class B extends A {}
''');
  }
}
