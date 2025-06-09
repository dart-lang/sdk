// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoGetterTest);
  });
}

@reflectiveTest
class ConvertIntoGetterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertIntoGetter;

  Future<void> test_extension_static() async {
    await resolveTestCode('''
extension E on int {
  static int ^a = 0;
}
''');
    await assertHasAssist('''
extension E on int {
  static int get a => 0;
}
''');
  }

  Future<void> test_extensionType_static() async {
    await resolveTestCode('''
extension type A(int i) {
  static int ^a = 0;
}
''');
    await assertHasAssist('''
extension type A(int i) {
  static int get a => 0;
}
''');
  }

  Future<void> test_late() async {
    await resolveTestCode('''
class A {
  late final int ^f = 1 + 2;
}
''');
    await assertHasAssist('''
class A {
  int get f => 1 + 2;
}
''');
  }

  Future<void> test_mixin() async {
    await resolveTestCode('''
mixin M {
  final int ^v = 1;
}
''');
    await assertHasAssist('''
mixin M {
  int get v => 1;
}
''');
  }

  Future<void> test_mixin_static() async {
    await resolveTestCode('''
mixin M {
  static int ^a = 0;
}
''');
    await assertHasAssist('''
mixin M {
  static int get a => 0;
}
''');
  }

  Future<void> test_noInitializer() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  final int ^foo;
}
''');
    await assertHasAssist('''
class A {
  int get foo => null;
}
''');
  }

  Future<void> test_notFinal() async {
    await resolveTestCode('''
class A {
  int ^foo = 1;
}
''');
    await assertHasAssist('''
class A {
  int get foo => 1;
}
''');
  }

  Future<void> test_notSingleField() async {
    await resolveTestCode('''
class A {
  final int ^foo = 1, bar = 2;
}
''');
    await assertNoAssist();
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
class A {
  final ^foo = 42;
}
''');
    await assertHasAssist('''
class A {
  int get foo => 42;
}
''');
  }

  Future<void> test_static() async {
    await resolveTestCode('''
class A {
  static int ^foo = 1;
}
''');
    await assertHasAssist('''
class A {
  static int get foo => 1;
}
''');
  }

  Future<void> test_type() async {
    await resolveTestCode('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  final int ^foo = 1 + 2;
}
''');
    await assertHasAssist('''
const myAnnotation = const Object();
class A {
  @myAnnotation
  int get foo => 1 + 2;
}
''');
  }
}
