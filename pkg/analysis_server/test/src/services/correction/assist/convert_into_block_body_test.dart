// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoBlockBodyTest);
  });
}

@reflectiveTest
class ConvertIntoBlockBodyTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertIntoBlockBody;

  Future<void> test_async() async {
    await resolveTestCode('''
class A {
  ^mmm() async => 123;
}
''');
    await assertHasAssist('''
class A {
  mmm() async {
    return 123;
  }
}
''');
  }

  Future<void> test_closure() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(^() => 42);
}
''');
    await assertHasAssist('''
setup(x) {}
void f() {
  setup(() {
    return 42;
  });
}
''');
    assertExitPosition(after: '42;');
  }

  Future<void> test_closure_voidExpression() async {
    await resolveTestCode('''
setup(x) {}
void f() {
  setup(^() => print('done'));
}
''');
    await assertHasAssist('''
setup(x) {}
void f() {
  setup(() {
    print('done');
  });
}
''');
    assertExitPosition(after: "');");
  }

  Future<void> test_container_class() async {
    await resolveTestCode('''
class C^;
''');
    await assertHasAssist('''
class C {}
''');
  }

  Future<void> test_container_enum() async {
    await resolveTestCode(
      '''
enum E^;
''',
      ignore: [diag.enumWithoutConstants],
    );
    await assertHasAssist('''
enum E {}
''');
  }

  Future<void> test_container_extension() async {
    await resolveTestCode('''
extension E on int^;
''');
    await assertHasAssist('''
extension E on int {}
''');
  }

  Future<void> test_container_extensionType() async {
    await resolveTestCode('''
extension type ^E(int i);
''');
    await assertHasAssist('''
extension type E(int i) {}
''');
  }

  Future<void> test_container_mixin() async {
    await resolveTestCode('''
mixin M^;
''');
    await assertHasAssist('''
mixin M {}
''');
  }

  Future<void> test_inExpression() async {
    await resolveTestCode('''
void f() => ^123;
''');
    await assertNoAssist();
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class A {
  ^mmm() => 123;
}
''');
    await assertHasAssist('''
class A {
  mmm() {
    return 123;
  }
}
''');
  }

  Future<void> test_noEnclosingFunction() async {
    await resolveTestCode('''
var ^v = 123;
''');
    await assertNoAssist();
  }

  Future<void> test_notExpressionBlock() async {
    await resolveTestCode('''
^fff() {
  return 123;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onArrow() async {
    await resolveTestCode('''
fff() ^=> 123;
''');
    await assertHasAssist('''
fff() {
  return 123;
}
''');
  }

  Future<void> test_onName() async {
    await resolveTestCode('''
^fff() => 123;
''');
    await assertHasAssist('''
fff() {
  return 123;
}
''');
  }

  Future<void> test_primaryConstructor_empty() async {
    await resolveTestCode('''
class C() {
  this : x = 2^;

  int x;
}
''');
    await assertHasAssist('''
class C() {
  this : x = 2 {
    // TODO: implement C
    throw UnimplementedError();
  }

  int x;
}
''');
  }

  Future<void> test_secondaryConstructor() async {
    await resolveTestCode('''
class C {
  C.named();

  factory ^C() => C.named();
}
''');
    await assertHasAssist('''
class C {
  C.named();

  factory C() {
    return C.named();
  }
}
''');
  }

  Future<void> test_throw() async {
    await resolveTestCode('''
class A {
  ^mmm() => throw 'error';
}
''');
    await assertHasAssist('''
class A {
  mmm() {
    throw 'error';
  }
}
''');
  }

  Future<void> test_void() async {
    await resolveTestCode('''
class C {
  String? _s;

  set s(String s) ^=> _s = s;
}
''');
    await assertHasAssist('''
class C {
  String? _s;

  set s(String s) {
    _s = s;
  }
}
''');
  }
}
