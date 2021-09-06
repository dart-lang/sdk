// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithVarTest);
  });
}

@reflectiveTest
class ReplaceWithVarTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REPLACE_WITH_VAR;

  Future<void> test_for() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (/*caret*/int i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
    await assertHasAssist('''
void f(List<int> list) {
  for (var i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
  }

  Future<void> test_forEach() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (/*caret*/int i in list) {
    print(i);
  }
}
''');
    await assertHasAssist('''
void f(List<int> list) {
  for (var i in list) {
    print(i);
  }
}
''');
  }

  Future<void> test_generic_instanceCreation_withArguments() async {
    await resolveTestCode('''
C<int> f() {
  /*caret*/C<int> c = C<int>();
  return c;
}
class C<T> {}
''');
    await assertHasAssist('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_instanceCreation_withoutArguments() async {
    await resolveTestCode('''
C<int> f() {
  /*caret*/C<int> c = C();
  return c;
}
class C<T> {}
''');
    await assertHasAssist('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_listLiteral() async {
    await resolveTestCode('''
List f() {
  /*caret*/List<int> l = [];
  return l;
}
''');
    await assertHasAssist('''
List f() {
  var l = <int>[];
  return l;
}
''');
  }

  Future<void> test_generic_mapLiteral() async {
    await resolveTestCode('''
Map f() {
  /*caret*/Map<String, int> m = {};
  return m;
}
''');
    await assertHasAssist('''
Map f() {
  var m = <String, int>{};
  return m;
}
''');
  }

  Future<void> test_generic_setLiteral() async {
    await resolveTestCode('''
Set f() {
  /*caret*/Set<int> s = {};
  return s;
}
''');
    await assertHasAssist('''
Set f() {
  var s = <int>{};
  return s;
}
''');
  }

  Future<void> test_generic_setLiteral_ambiguous() async {
    await resolveTestCode('''
Set f() {
  /*caret*/Set s = {};
  return s;
}
''');
    await assertNoAssist();
  }

  Future<void> test_moreGeneral() async {
    await resolveTestCode('''
num f() {
  /*caret*/num n = 0;
  return n;
}
''');
    await assertNoAssist();
  }

  Future<void> test_noInitializer() async {
    await resolveTestCode('''
String f() {
  /*caret*/String s;
  s = '';
  return s;
}
''');
    await assertNoAssist();
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
String f() {
  /*caret*/var s = '';
  return s;
}
''');
    await assertNoAssist();
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
String f() {
  /*caret*/String s = '';
  return s;
}
''');
    await assertHasAssist('''
String f() {
  var s = '';
  return s;
}
''');
  }
}
