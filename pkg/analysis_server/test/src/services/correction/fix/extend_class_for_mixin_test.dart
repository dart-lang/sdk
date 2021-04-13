// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendClassForMixinTest);
  });
}

@reflectiveTest
class ExtendClassForMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.EXTEND_CLASS_FOR_MIXIN;

  Future<void> test_missingClass_withExtends() async {
    await resolveTestCode('''
class A {}
class B {}
mixin M on B {}
class C extends A with M {}
''');
    await assertNoFix();
  }

  Future<void> test_missingClass_withoutExtends_withImplements() async {
    await resolveTestCode('''
class A {}
class B {}
mixin M on B {}
class C with M implements A {}
''');
    await assertHasFix('''
class A {}
class B {}
mixin M on B {}
class C extends B with M implements A {}
''');
  }

  Future<void> test_missingClass_withoutExtends_withoutImplements() async {
    await resolveTestCode('''
class A {}
mixin M on A {}
class C with M {}
''');
    await assertHasFix('''
class A {}
mixin M on A {}
class C extends A with M {}
''');
  }

  Future<void> test_missingMixin_withExtends() async {
    await resolveTestCode('''
class A {}
mixin M {}
mixin N on M {}
class C extends A with N {}
''');
    await assertNoFix();
  }

  @failingTest
  Future<void> test_missingMixin_withoutExtends() async {
    await resolveTestCode('''
mixin M {}
mixin N on M {}
class C with N {}
''');
    await assertNoFix();
  }
}
