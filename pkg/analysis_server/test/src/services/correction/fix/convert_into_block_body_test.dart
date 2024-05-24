// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoBlockBodyMissingBodyTest);
    defineReflectiveTests(ConvertIntoBlockBodySetLiteralBulkTest);
    defineReflectiveTests(ConvertIntoBlockBodySetLiteralTest);
    defineReflectiveTests(ConvertIntoBlockBodySetLiteralMultiTest);
  });
}

@reflectiveTest
class ConvertIntoBlockBodyMissingBodyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_INTO_BLOCK_BODY;

  Future<void> test_enum_getter() async {
    await resolveTestCode('''
enum E {
  v;
  int get g;
}
''');
    await assertHasFix('''
enum E {
  v;
  int get g {
    // TODO: implement g
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_enum_method() async {
    await resolveTestCode('''
enum E {
  v;
  void m();
}
''');
    await assertHasFix('''
enum E {
  v;
  void m() {
    // TODO: implement m
  }
}
''');
  }

  Future<void> test_enum_setter() async {
    await resolveTestCode('''
enum E {
  v;
  set s(int _);
}
''');
    await assertHasFix('''
enum E {
  v;
  set s(int _) {
    // TODO: implement s
  }
}
''');
  }

  test_extenstionTypeWithAbstractMember_getter() async {
    await resolveTestCode('''
extension type A(int it) {
  int get g;
}
''');
    await assertHasFix('''
extension type A(int it) {
  int get g {
    // TODO: implement g
    throw UnimplementedError();
  }
}
''');
  }

  test_extenstionTypeWithAbstractMember_method() async {
    await resolveTestCode('''
extension type A(int it) {
  void f();
}
''');
    await assertHasFix('''
extension type A(int it) {
  void f() {
    // TODO: implement f
  }
}
''');
  }

  Future<void> test_function() async {
    await resolveTestCode('''
void f();
''');
    await assertHasFix('''
void f() {
  // TODO: implement f
}
''');
  }

  Future<void> test_method_Never() async {
    await resolveTestCode('''
class A {
  Never m();
}
''');
    await assertHasFix('''
class A {
  Never m() {
    // TODO: implement m
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_method_nonVoid() async {
    await resolveTestCode('''
class A {
  String m(int i);
}
''');
    await assertHasFix('''
class A {
  String m(int i) {
    // TODO: implement m
    throw UnimplementedError();
  }
}
''');
  }

  Future<void> test_method_void() async {
    await resolveTestCode('''
class A {
  void m();
}
''');
    await assertHasFix('''
class A {
  void m() {
    // TODO: implement m
  }
}
''');
  }
}

@reflectiveTest
class ConvertIntoBlockBodySetLiteralBulkTest extends BulkFixProcessorTest {
  Future<void> test_file() async {
    await resolveTestCode('''
void g(void Function() fun) {}

void f() {
  g(() => {
    g(() => {
      1
    })
  });
}
''');
    await assertHasFix('''
void g(void Function() fun) {}

void f() {
  g(() {
    g(() {
      1;
    });
  });
}
''');
  }
}

@reflectiveTest
class ConvertIntoBlockBodySetLiteralMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_INTO_BLOCK_BODY_MULTI;

  Future<void> test_multi() async {
    await resolveTestCode('''
void g(void Function() fun) {}

void f() {
  g(() => {
    g(() => {
      1
    })
  });
}
''');
    await assertHasFixAllFix(WarningCode.UNNECESSARY_SET_LITERAL, '''
void g(void Function() fun) {}

void f() {
  g(() {
    g(() {
      1;
    });
  });
}
''');
  }
}

@reflectiveTest
class ConvertIntoBlockBodySetLiteralTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_INTO_BLOCK_BODY;

  Future<void> test_expressionFunctionBody() async {
    await resolveTestCode('''
void g(void Function() fun) {}
void f() {
  g(() => {1});
}
''');
    await assertHasFix('''
void g(void Function() fun) {}
void f() {
  g(() {1;});
}
''');
  }

  Future<void> test_expressionFunctionBody_comma_both() async {
    await resolveTestCode('''
void g(void Function() fun) {}
void f() {
  g(() => {1,},);
}
''');
    await assertHasFix('''
void g(void Function() fun) {}
void f() {
  g(() {1;},);
}
''');
  }

  Future<void> test_expressionFunctionBody_comma_both_spaces() async {
    await resolveTestCode('''
void g(void Function() fun) {}
void f() {
  g(() => { 1 , } , );
}
''');
    await assertHasFix('''
void g(void Function() fun) {}
void f() {
  g(() { 1 ; } , );
}
''');
  }

  Future<void> test_expressionFunctionBody_comma_inside() async {
    await resolveTestCode('''
void g(void Function() fun) {}
void f() {
  g(() => {1,});
}
''');
    await assertHasFix('''
void g(void Function() fun) {}
void f() {
  g(() {1;});
}
''');
  }

  Future<void> test_expressionFunctionBody_comma_outside() async {
    await resolveTestCode('''
void g(void Function() fun) {}
void f() {
  g(() => {1},);
}
''');
    await assertHasFix('''
void g(void Function() fun) {}
void f() {
  g(() {1;},);
}
''');
  }

  Future<void> test_expressionFunctionBody_comment() async {
    await resolveTestCode('''
void g(void Function() fun) {}
void f() {
  g(() => /* hi */ {1});
}
''');
    await assertHasFix('''
void g(void Function() fun) {}
void f() {
  g(() /* hi */ {1;});
}
''');
  }

  Future<void> test_expressionFunctionBody_multiple() async {
    await resolveTestCode('''
void g(void Function() fun) {}
void f(bool b) {
  g(() => {1, if (b) 2, if (b) 3 else 4, for(;;) 5});
}
''');
    await assertHasFix('''
void g(void Function() fun) {}
void f(bool b) {
  g(() {1; if (b) 2; if (b) 3; else 4; for(;;) 5;});
}
''');
  }

  Future<void> test_functionDeclaration() async {
    await resolveTestCode('''
void f() => {1};
''');
    await assertHasFix('''
void f() {1;}
''');
  }

  Future<void> test_functionDeclaration_comma() async {
    await resolveTestCode('''
void f() => {1,};
''');
    await assertHasFix('''
void f() {1;}
''');
  }

  Future<void> test_functionDeclaration_comma_spaces() async {
    await resolveTestCode('''
void f() => { 1 , } ;
''');
    await assertHasFix('''
void f() { 1 ; }
''');
  }

  Future<void> test_functionDeclaration_comments() async {
    await resolveTestCode('''
void f() => /* first */ {1} /* second */ /* third */ ;
''');
    await assertHasFix('''
void f() /* first */ {1;} /* second */ /* third */
''');
  }

  Future<void> test_functionDeclaration_multiple() async {
    await resolveTestCode('''
void f(bool b) => {for (;b;) 1, if (b) 2 else 3, if (b) 4,};
''');
    await assertHasFix('''
void f(bool b) {for (;b;) 1; if (b) 2; else 3; if (b) 4;}
''');
  }
}
