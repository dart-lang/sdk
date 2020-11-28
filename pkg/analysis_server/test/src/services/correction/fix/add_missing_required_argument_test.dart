// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingRequiredArgumentTest);
    defineReflectiveTests(AddMissingRequiredArgumentWithNullSafetyTest);
  });
}

@reflectiveTest
class AddMissingRequiredArgumentTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_constructor_flutter_children() async {
    await resolveTestCode('''
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

  Future<void> test_constructor_flutter_hasTrailingComma() async {
    await resolveTestCode('''
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

  Future<void> test_constructor_named() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  A.named({@required int a}) {}
}

void f() {
  A a = new A.named();
  print(a);
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  A.named({@required int a}) {}
}

void f() {
  A a = new A.named(a: null);
  print(a);
}
''');
  }

  Future<void> test_constructor_single() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  A({@required int a}) {}
}
''');
    await resolveTestCode('''
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

  Future<void> test_constructor_single_closure() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef void VoidCallback();

class A {
  A({@required VoidCallback onPressed}) {}
}
''');
    await resolveTestCode('''
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

  Future<void> test_constructor_single_closure2() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef void Callback(e);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestCode('''
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

  Future<void> test_constructor_single_closure3() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef void Callback(a,b,c);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestCode('''
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

  Future<void> test_constructor_single_closure4() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef int Callback(int a, String b,c);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestCode('''
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

  Future<void> test_constructor_single_list() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  A({@required List<String> names}) {}
}
''');
    await resolveTestCode('''
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
    await resolveTestCode('''
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
    await resolveTestCode('''
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
    await resolveTestCode('''
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
    await resolveTestCode('''
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
    foo: '',
    child: null,
  );
}
''');
  }

  Future<void> test_param_children() async {
    await resolveTestCode('''
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
    foo: '',
    children: null,
  );
}
''');
  }

  Future<void> test_single() async {
    await resolveTestCode('''
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
    await resolveTestCode('''
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
    await resolveTestCode('''
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

@reflectiveTest
class AddMissingRequiredArgumentWithNullSafetyTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_constructor_single_closure_nnbd() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef int Callback(int? a);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestCode('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(callback: (int? a) {  });
  print(a);
}
''');
  }

  Future<void> test_constructor_single_closure_nnbd_from_legacy() async {
    addSource('/home/test/lib/a.dart', r'''
// @dart = 2.8
import 'package:meta/meta.dart';

typedef int Callback(int a);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestCode('''
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
import 'package:test/a.dart';

main() {
  A a = new A(callback: (int a) {  });
  print(a);
}
''',
        errorFilter: (error) =>
            error.errorCode == HintCode.MISSING_REQUIRED_PARAM);
  }

  Future<void> test_constructor_single_closure_nnbd_into_legacy() async {
    addSource('/home/test/lib/a.dart', r'''
import 'package:meta/meta.dart';

typedef int Callback(int? a);

class A {
  A({@required Callback callback}) {}
}
''');
    await resolveTestCode('''
// @dart = 2.8
import 'package:test/a.dart';

main() {
  A a = new A();
  print(a);
}
''');
    await assertHasFix('''
// @dart = 2.8
import 'package:test/a.dart';

main() {
  A a = new A(callback: (int a) {  });
  print(a);
}
''');
  }

  Future<void> test_nonNullable() async {
    await resolveTestCode('''
void f({required int x}) {}
void g() {
  f();
}
''');
    await assertHasFix('''
void f({required int x}) {}
void g() {
  f(x: null);
}
''');
  }

  Future<void> test_nullable() async {
    await resolveTestCode('''
void f({required int? x}) {}
void g() {
  f();
}
''');
    await assertHasFix('''
void f({required int? x}) {}
void g() {
  f(x: null);
}
''');
  }
}
