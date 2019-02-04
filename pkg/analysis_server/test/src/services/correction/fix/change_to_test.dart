// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeToTest);
  });
}

@reflectiveTest
class ChangeToTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TO;

  test_undefinedClass_fromImport() async {
    await resolveTestUnit('''
main() {
  Stirng s = 'abc';
  print(s);
}
''');
    await assertHasFix('''
main() {
  String s = 'abc';
  print(s);
}
''');
  }

  test_undefinedClass_fromThisLibrary() async {
    await resolveTestUnit('''
class MyClass {}
main() {
  MyCalss v = null;
  print(v);
}
''');
    await assertHasFix('''
class MyClass {}
main() {
  MyClass v = null;
  print(v);
}
''');
  }

  test_undefinedClass_prefixed() async {
    await resolveTestUnit('''
import 'dart:async' as c;
main() {
  c.Fture v = null;
  print(v);
}
''');
    await assertHasFix('''
import 'dart:async' as c;
main() {
  c.Future v = null;
  print(v);
}
''');
  }

  test_undefinedFunction_fromImport() async {
    await resolveTestUnit('''
main() {
  pritn(0);
}
''');
    await assertHasFix('''
main() {
  print(0);
}
''');
  }

  test_undefinedFunction_prefixed_fromImport() async {
    await resolveTestUnit('''
import 'dart:core' as c;
main() {
  c.prnt(42);
}
''');
    await assertHasFix('''
import 'dart:core' as c;
main() {
  c.print(42);
}
''');
  }

  test_undefinedFunction_prefixed_ignoreLocal() async {
    await resolveTestUnit('''
import 'dart:async' as c;
main() {
  c.main();
}
''');
    await assertNoFix();
  }

  test_undefinedFunction_thisLibrary() async {
    await resolveTestUnit('''
myFunction() {}
main() {
  myFuntcion();
}
''');
    await assertHasFix('''
myFunction() {}
main() {
  myFunction();
}
''');
  }

  test_undefinedGetter_hint() async {
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  print(x.myFild);
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  print(x.myField);
}
''');
  }

  test_undefinedGetter_qualified() async {
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  print(a.myFild);
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  print(a.myField);
}
''');
  }

  test_undefinedGetter_qualified_static() async {
    await resolveTestUnit('''
class A {
  static int MY_NAME = 1;
}
main() {
  A.MY_NAM;
}
''');
    await assertHasFix('''
class A {
  static int MY_NAME = 1;
}
main() {
  A.MY_NAME;
}
''');
  }

  test_undefinedGetter_unqualified() async {
    await resolveTestUnit('''
class A {
  int myField;
  main() {
    print(myFild);
  }
}
''');
    await assertHasFix('''
class A {
  int myField;
  main() {
    print(myField);
  }
}
''');
  }

  test_undefinedMethod_ignoreOperators() async {
    await resolveTestUnit('''
main(Object object) {
  object.then();
}
''');
    await assertNoFix();
  }

  test_undefinedMethod_qualified() async {
    await resolveTestUnit('''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMehtod();
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMethod();
}
''');
  }

  test_undefinedMethod_unqualified_superClass() async {
    await resolveTestUnit('''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMehtod();
  }
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMethod();
  }
}
''');
  }

  test_undefinedMethod_unqualified_thisClass() async {
    await resolveTestUnit('''
class A {
  myMethod() {}
  main() {
    myMehtod();
  }
}
''');
    await assertHasFix('''
class A {
  myMethod() {}
  main() {
    myMethod();
  }
}
''');
  }

  test_undefinedSetter_hint() async {
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  x.myFild = 42;
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  x.myField = 42;
}
''');
  }

  test_undefinedSetter_qualified() async {
    await resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  a.myFild = 42;
}
''');
    await assertHasFix('''
class A {
  int myField;
}
main(A a) {
  a.myField = 42;
}
''');
  }

  test_undefinedSetter_unqualified() async {
    await resolveTestUnit('''
class A {
  int myField;
  main() {
    myFild = 42;
  }
}
''');
    await assertHasFix('''
class A {
  int myField;
  main() {
    myField = 42;
  }
}
''');
  }
}
