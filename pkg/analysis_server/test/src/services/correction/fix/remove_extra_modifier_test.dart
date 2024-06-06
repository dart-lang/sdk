// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveExtraModifierMultiTest);
    defineReflectiveTests(RemoveExtraModifierTest);
  });
}

@reflectiveTest
class RemoveExtraModifierMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EXTRA_MODIFIER_MULTI;

  Future<void> test_singleFile() async {
    newFile('$testPackageLibPath/a.dart', '''
import augment 'test.dart';

class A { }
''');

    await resolveTestCode('''
augment library 'a.dart';

augment abstract class A {}

augment final class A {}
''');
    await assertHasFixAllFix(
        CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA, '''
augment library 'a.dart';

augment class A {}

augment class A {}
''');
  }
}

@reflectiveTest
class RemoveExtraModifierTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EXTRA_MODIFIER;

  Future<void> test_abstract_static_field() async {
    await resolveTestCode('''
abstract class A {
  abstract static int? i;
}
''');
    await assertHasFix('''
abstract class A {
  static int? i;
}
''');
  }

  Future<void> test_abstract_static_method() async {
    await resolveTestCode('''
abstract class A {
  abstract static void m;
}
''');
    await assertHasFix('''
abstract class A {
  static void m;
}
''');
  }

  Future<void> test_abstractEnum() async {
    await resolveTestCode(r'''
abstract enum E {ONE}
''');
    await assertHasFix('''
enum E {ONE}
''');
  }

  Future<void> test_abstractTopLevelFunction_function() async {
    await resolveTestCode(r'''
abstract f(v) {}
''');
    await assertHasFix('''
f(v) {}
''');
  }

  Future<void> test_abstractTopLevelFunction_getter() async {
    await resolveTestCode(r'''
abstract get m {}
''');
    await assertHasFix('''
get m {}
''');
  }

  Future<void> test_abstractTopLevelFunction_setter() async {
    await resolveTestCode(r'''
abstract set m(v) {}
''');
    await assertHasFix('''
set m(v) {}
''');
  }

  Future<void> test_abstractTopLevelVariable() async {
    await resolveTestCode(r'''
abstract Object? o;
''');
    await assertHasFix('''
Object? o;
''');
  }

  Future<void> test_abstractTypeDef() async {
    await resolveTestCode(r'''
abstract typedef F();
''');
    await assertHasFix('''
typedef F();
''');
  }

  Future<void> test_class_sealed_mixin() async {
    await resolveTestCode('''
sealed mixin class A {}
''');
    await assertHasFix('''
mixin class A {}
''');
  }

  Future<void> test_constMethod() async {
    await resolveTestCode('''
const void m() {}
''');
    await assertHasFix('''
void m() {}
''');
  }

  Future<void> test_covariantMember() async {
    await resolveTestCode(r'''
class C {
  covariant c() {}
}
''');
    await assertHasFix('''
class C {
  c() {}
}
''');
  }

  Future<void> test_covariantTopLevelDeclaration_class() async {
    await resolveTestCode(r'''
covariant class C {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_covariantTopLevelDeclaration_enum() async {
    await resolveTestCode(r'''
covariant enum E { v }
''');
    await assertHasFix('''
enum E { v }
''');
  }

  Future<void> test_duplicatedModifier() async {
    await resolveTestCode(r'''
f() {
  const const c = '';
  c;
}
''');
    await assertHasFix('''
f() {
  const c = '';
  c;
}
''');
  }

  Future<void> test_externalClass() async {
    await resolveTestCode(r'''
external class C {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_externalEnum() async {
    await resolveTestCode(r'''
external enum E { o }
''');
    await assertHasFix('''
enum E { o }
''');
  }

  Future<void> test_final_constructor() async {
    await resolveTestCode('''
class C {
  final C();
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void> test_final_method() async {
    await resolveTestCode('''
class C {
  final m() {}
}
''');
    await assertHasFix('''
class C {
  m() {}
}
''');
  }

  Future<void> test_finalEnum() async {
    await resolveTestCode(r'''
final enum E {e}
''');
    await assertHasFix('''
enum E {e}
''');
  }

  Future<void> test_finalMixin() async {
    await resolveTestCode('''
final mixin M {}
''');
    await assertHasFix('''
mixin M {}
''');
  }

  Future<void> test_finalMixinClass() async {
    await resolveTestCode('''
final mixin class A {}
''');
    await assertHasFix('''
mixin class A {}
''');
  }

  Future<void> test_interfaceMixin() async {
    await resolveTestCode('''
interface mixin M {}
''');
    await assertHasFix('''
mixin M {}
''');
  }

  Future<void> test_interfaceMixinClass() async {
    await resolveTestCode('''
interface mixin class A {}
''');
    await assertHasFix('''
mixin class A {}
''');
  }

  Future<void> test_invalidAsyncConstructorModifier() async {
    await resolveTestCode(r'''
class A {
  A() async {}
}
''');
    await assertHasFix('''
class A {
  A() {}
}
''');
  }

  Future<void> test_it() async {
    newFile('$testPackageLibPath/a.dart', '''
import augment 'test.dart';

class A { }
''');

    await resolveTestCode('''
augment library 'a.dart';

augment abstract class A {}
''');
    await assertHasFix('''
augment library 'a.dart';

augment class A {}
''');
  }

  Future<void> test_localFunctionDeclarationModifier_abstract() async {
    await resolveTestCode(r'''
class C {
  m() { 
    abstract f() {} 
    f();
  } 
}
''');
    await assertHasFix('''
class C {
  m() { 
    f() {} 
    f();
  } 
}
''');
  }

  Future<void> test_sealed_mixin() async {
    await resolveTestCode('''
sealed mixin M {}
''');
    await assertHasFix('''
mixin M {}
''');
  }

  Future<void> test_staticTopLevelDeclaration_enum() async {
    await resolveTestCode(r'''
static enum E { v }
''');
    await assertHasFix('''
enum E { v }
''');
  }

  Future<void> test_topLevel_factoryDeclaration() async {
    await resolveTestCode(r'''
factory class C {}
''');
    await assertHasFix('''
class C {}
''');
  }
}
