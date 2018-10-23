// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingRequiredArgumentTest);
  });
}

@reflectiveTest
class AddMissingRequiredArgumentTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT;

  test_cons_flutter_children() async {
    addFlutterPackage();
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required List<Widget> children});
}

build() {
  return new MyWidget();
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required List<Widget> children});
}

build() {
  return new MyWidget(children: <Widget>[],);
}
''');
  }

  test_cons_flutter_hasTrailingComma() async {
    addFlutterPackage();
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required int a, @required int b});
}

build() {
  return new MyWidget(a: 1,);
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required int a, @required int b});
}

build() {
  return new MyWidget(a: 1, b: null,);
}
''');
  }

  test_cons_single() async {
    addMetaPackageSource();
    addSource('/project/libA.dart', r'''
library libA;
import 'package:meta/meta.dart';

class A {
  A({@required int a}) {}
}
''');
    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'libA.dart';

main() {
  A a = new A(a: null);
  print(a);
}
''');
  }

  test_cons_single_closure() async {
    addMetaPackageSource();
    addSource('/project/libA.dart', r'''
library libA;
import 'package:meta/meta.dart';

typedef void VoidCallback();

class A {
  A({@required VoidCallback onPressed}) {}
}
''');
    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'libA.dart';

main() {
  A a = new A(onPressed: () {});
  print(a);
}
''');
  }

  test_cons_single_closure_2() async {
    addMetaPackageSource();
    addSource('/project/libA.dart', r'''
library libA;
import 'package:meta/meta.dart';

typedef void Callback(e);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'libA.dart';

main() {
  A a = new A(callback: (e) {});
  print(a);
}
''');
  }

  test_cons_single_closure_3() async {
    addMetaPackageSource();
    addSource('/project/libA.dart', r'''
library libA;
import 'package:meta/meta.dart';

typedef void Callback(a,b,c);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'libA.dart';

main() {
  A a = new A(callback: (a, b, c) {});
  print(a);
}
''');
  }

  test_cons_single_closure_4() async {
    addMetaPackageSource();
    addSource('/project/libA.dart', r'''
library libA;
import 'package:meta/meta.dart';

typedef int Callback(int a, String b,c);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'libA.dart';

main() {
  A a = new A(callback: (int a, String b, c) {});
  print(a);
}
''');
  }

  test_cons_single_list() async {
    addMetaPackageSource();
    addSource('/project/libA.dart', r'''
library libA;
import 'package:meta/meta.dart';

class A {
  A({@required List<String> names}) {}
}
''');
    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'libA.dart';

main() {
  A a = new A(names: <String>[]);
  print(a);
}
''');
  }

  test_multiple() async {
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(a: 3);
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(a: 3, bcd: null);
}
''');
  }

  test_multiple_1of2() async {
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test();
}
''');
    int index = 0;
    await assertHasFix('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(a: null);
}
''', errorFilter: (error) => index++ == 0);
  }

  test_multiple_2of2() async {
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test();
}
''');
    int index = 0;
    await assertHasFix('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(bcd: null);
}
''', errorFilter: (error) => index++ == 1);
  }

  test_single() async {
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int abc}) {}
main() {
  test();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

test({@required int abc}) {}
main() {
  test(abc: null);
}
''');
  }

  test_single_normal() async {
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test(String x, {@required int abc}) {}
main() {
  test("foo");
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

test(String x, {@required int abc}) {}
main() {
  test("foo", abc: null);
}
''');
  }

  test_single_with_details() async {
    addMetaPackageSource();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@Required("Really who doesn't need an abc?") int abc}) {}
main() {
  test();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

test({@Required("Really who doesn't need an abc?") int abc}) {}
main() {
  test(abc: null);
}
''');
  }
}
