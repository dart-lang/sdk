// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertClassToMixinTest);
  });
}

@reflectiveTest
class ConvertClassToMixinTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertClassToMixin;

  Future<void> test_abstract() async {
    await resolveTestCode('''
abstract class ^A {}
''');
    await assertHasAssist('''
mixin A {}
''');
  }

  Future<void> test_base_extendsWithImplements_super_both() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
base class ^D extends A with B implements C {
  d() {
    super.a();
    super.b();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
base mixin D on A, B implements C {
  d() {
    super.a();
    super.b();
  }
}
''');
  }

  Future<void> test_extends_noSuper() async {
    await resolveTestCode('''
class A {}
class ^B extends A {}
''');
    await assertHasAssist('''
class A {}
mixin B implements A {}
''');
  }

  Future<void> test_extends_super() async {
    await resolveTestCode('''
class A {
  a() {}
}
class ^B extends A {
  b() {
    super.a();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin B on A {
  b() {
    super.a();
  }
}
''');
  }

  Future<void> test_extends_superSuper() async {
    await resolveTestCode('''
class A {
  a() {}
}
class B extends A {}
class ^C extends B {
  c() {
    super.a();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
class B extends A {}
mixin C on B {
  c() {
    super.a();
  }
}
''');
  }

  Future<void> test_extendsImplements_noSuper() async {
    await resolveTestCode('''
class A {}
class B {}
class ^C extends A implements B {}
''');
    await assertHasAssist('''
class A {}
class B {}
mixin C implements A, B {}
''');
  }

  Future<void> test_extendsImplements_super_extends() async {
    await resolveTestCode('''
class A {
  a() {}
}
class B {}
class ^C extends A implements B {
  c() {
    super.a();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
class B {}
mixin C on A implements B {
  c() {
    super.a();
  }
}
''');
  }

  Future<void> test_extendsWith_noSuper() async {
    await resolveTestCode('''
class A {}
mixin B {}
class ^C extends A with B {}
''');
    await assertHasAssist('''
class A {}
mixin B {}
mixin C implements A, B {}
''');
  }

  Future<void> test_extendsWith_super_both() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class ^C extends A with B {
  c() {
    super.a();
    super.b();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
mixin C on A, B {
  c() {
    super.a();
    super.b();
  }
}
''');
  }

  Future<void> test_extendsWith_super_extends() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class ^C extends A with B {
  c() {
    super.a();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
mixin C on A implements B {
  c() {
    super.a();
  }
}
''');
  }

  Future<void> test_extendsWith_super_with() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class ^C extends A with B {
  c() {
    super.b();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
mixin C on B implements A {
  c() {
    super.b();
  }
}
''');
  }

  Future<void> test_extendsWithImplements_noSuper() async {
    await resolveTestCode('''
class A {}
mixin B {}
class C {}
class ^D extends A with B implements C {}
''');
    await assertHasAssist('''
class A {}
mixin B {}
class C {}
mixin D implements A, B, C {}
''');
  }

  Future<void> test_extendsWithImplements_super_both() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
class ^D extends A with B implements C {
  d() {
    super.a();
    super.b();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
mixin D on A, B implements C {
  d() {
    super.a();
    super.b();
  }
}
''');
  }

  Future<void> test_extendsWithImplements_super_extends() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
class ^D extends A with B implements C {
  d() {
    super.a();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
mixin D on A implements B, C {
  d() {
    super.a();
  }
}
''');
  }

  Future<void> test_extendsWithImplements_super_with() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
class ^D extends A with B implements C {
  d() {
    super.b();
  }
}
''');
    await assertHasAssist('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
class C {}
mixin D on B implements A, C {
  d() {
    super.b();
  }
}
''');
  }

  Future<void> test_final_implements() async {
    await resolveTestCode('''
class A {}
final class ^B implements A {}
''');
    await assertNoAssist();
  }

  Future<void> test_implements() async {
    await resolveTestCode('''
class A {}
class ^B implements A {}
''');
    await assertHasAssist('''
class A {}
mixin B implements A {}
''');
  }

  Future<void> test_noClauses_invalidSelection() async {
    await resolveTestCode('''
class A ^{}
''');
    await assertNoAssist();
  }

  Future<void> test_noClauses_selectKeyword() async {
    await resolveTestCode('''
^class A {}
''');
    await assertHasAssist('''
mixin A {}
''');
  }

  Future<void> test_noClauses_selectName() async {
    await resolveTestCode('''
class ^A {}
''');
    await assertHasAssist('''
mixin A {}
''');
  }

  Future<void> test_sealed_extends_noSuper() async {
    await resolveTestCode('''
class A {}
sealed class ^B extends A {}
''');
    await assertNoAssist();
  }

  Future<void> test_sealed_extendsWith_super_extends() async {
    await resolveTestCode('''
class A {
  a() {}
}
mixin class B {
  b() {}
}
sealed class ^C extends A with B {
  c() {
    super.a();
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_typeParameters() async {
    await resolveTestCode('''
class ^A<T> {}
''');
    await assertHasAssist('''
mixin A<T> {}
''');
  }

  Future<void> test_with_noSuper() async {
    await resolveTestCode('''
mixin class A {}
class ^B with A {}
''');
    await assertHasAssist('''
mixin class A {}
mixin B implements A {}
''');
  }

  Future<void> test_with_super() async {
    await resolveTestCode('''
mixin class A {
  a() {}
}
class ^B with A {
  b() {
    super.a();
  }
}
''');
    await assertHasAssist('''
mixin class A {
  a() {}
}
mixin B on A {
  b() {
    super.a();
  }
}
''');
  }
}
