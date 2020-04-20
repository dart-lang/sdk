// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingRequiredArgumentTest);
  });
}

@reflectiveTest
class AddMissingRequiredArgumentTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT;

  Future<void> test_cons_flutter_children() async {
    addFlutterPackage();
    addMetaPackage();
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
  return new MyWidget(children: [],);
}
''');
  }

  Future<void> test_cons_flutter_hasTrailingComma() async {
    addFlutterPackage();
    addMetaPackage();
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

  Future<void> test_cons_single() async {
    addMetaPackage();
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  A({@required int a}) {}
}
''');
    await resolveTestUnit('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(a: null);
  print(a);
}
''');
  }

  Future<void> test_cons_single_closure() async {
    addMetaPackage();
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef void VoidCallback();

class A {
  A({@required VoidCallback onPressed}) {}
}
''');
    await resolveTestUnit('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(onPressed: () {  });
  print(a);
}
''');
  }

  Future<void> test_cons_single_closure_2() async {
    addMetaPackage();
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef void Callback(e);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestUnit('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(callback: (e) {  });
  print(a);
}
''');
  }

  Future<void> test_cons_single_closure_3() async {
    addMetaPackage();
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef void Callback(a,b,c);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestUnit('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(callback: (a, b, c) {  });
  print(a);
}
''');
  }

  Future<void> test_cons_single_closure_4() async {
    addMetaPackage();
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef int Callback(int a, String b,c);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestUnit('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(callback: (int a, String b, c) {  });
  print(a);
}
''');
  }

  Future<void> test_cons_single_list() async {
    addMetaPackage();
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  A({@required List<String> names}) {}
}
''');
    await resolveTestUnit('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(names: []);
  print(a);
}
''');
  }

  Future<void> test_multiple() async {
    addMetaPackage();
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

  Future<void> test_multiple_1of2() async {
    addMetaPackage();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(a: null);
}
''', errorFilter: (error) => error.message.contains("'a'"));
  }

  Future<void> test_multiple_2of2() async {
    addMetaPackage();
    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test();
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(bcd: null);
}
''', errorFilter: (error) => error.message.contains("'bcd'"));
  }

  Future<void> test_param_child() async {
    addFlutterPackage();
    addMetaPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required String foo, @required Widget child});
}

build() {
  return new MyWidget(
    child: null,
  );
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required String foo, @required Widget child});
}

build() {
  return new MyWidget(
    foo: null,
    child: null,
  );
}
''');
  }

  Future<void> test_param_children() async {
    addFlutterPackage();
    addMetaPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required String foo, @required List<Widget> children});
}

build() {
  return new MyWidget(
    children: null,
  );
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required String foo, @required List<Widget> children});
}

build() {
  return new MyWidget(
    foo: null,
    children: null,
  );
}
''');
  }

  Future<void> test_single() async {
    addMetaPackage();
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
    assertLinkedGroup(change.linkedEditGroups[0], ['null);']);
  }

  Future<void> test_single_normal() async {
    addMetaPackage();
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

  Future<void> test_single_with_details() async {
    addMetaPackage();
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
