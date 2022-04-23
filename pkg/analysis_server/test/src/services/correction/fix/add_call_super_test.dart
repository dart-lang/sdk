// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddCallSuperTest);
  });
}

@reflectiveTest
class AddCallSuperTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_CALL_SUPER;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(meta: true);
  }

  Future<void> test_body() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a() {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void a() {}
}
class B extends A {
  @override
  void a() {
    super.a();
  }
}
''', matchFixMessage: "Add 'super.a()'");
  }

  Future<void> test_body_added_parameters() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void m(int x) {}
}
class B extends A {
  @override
  void m(int x, [int? y]) {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void m(int x) {}
}
class B extends A {
  @override
  void m(int x, [int? y]) {
    super.m(x);
  }
}
''', matchFixMessage: "Add 'super.m(x)'");
  }

  Future<void> test_body_optional() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, {int y = 0}) {
    return x = y;
  }
}
class B extends A {
  @override
  int a(int x, {int y = 0}) {
    return x = y;
  }
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, {int y = 0}) {
    return x = y;
  }
}
class B extends A {
  @override
  int a(int x, {int y = 0}) {
    super.a(x, y: y);
    return x = y;
  }
}
''', matchFixMessage: "Add 'super.a(x, y: y)'");
  }

  Future<void> test_body_parameters() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void a(int i) {}
}
class B extends A {
  @override
  void a(int i) {}
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void a(int i) {}
}
class B extends A {
  @override
  void a(int i) {
    super.a(i);
  }
}
''', matchFixMessage: "Add 'super.a(i)'");
  }

  Future<void> test_body_required() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, {required int y}) {
    return x = y;
  }
}
class B extends A {
  @override
  int a(int x, {required int y}) {
    return x = y;
  }
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, {required int y}) {
    return x = y;
  }
}
class B extends A {
  @override
  int a(int x, {required int y}) {
    super.a(x, y: y);
    return x = y;
  }
}
''', matchFixMessage: "Add 'super.a(x, y: y)'");
  }

  Future<void> test_expression_async() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  Future<int> m() async => 3;
}
class B extends A {
  @override
  Future<int> m() async => 3;
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  Future<int> m() async => 3;
}
class B extends A {
  @override
  Future<int> m() async {
    super.m();
    return 3;
  }
}
''', matchFixMessage: "Add 'super.m()'");
  }

  Future<void> test_expression_parameters() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, int y) => x + y;
}
class B extends A {
  @override
  int a(int x, int y) => x + y;
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, int y) => x + y;
}
class B extends A {
  @override
  int a(int x, int y) {
    super.a(x, y);
    return x + y;
  }
}
''', matchFixMessage: "Add 'super.a(x, y)'");
  }

  Future<void> test_expression_positional() async {
    await resolveTestCode('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, [int y = 0]) => x + y;
}
class B extends A {
  @override
  int a(int x, [int y = 0]) => x + y;
}
''');
    await assertHasFix('''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int a(int x, [int y = 0]) => x + y;
}
class B extends A {
  @override
  int a(int x, [int y = 0]) {
    super.a(x, y);
    return x + y;
  }
}
''', matchFixMessage: "Add 'super.a(x, y)'");
  }
}
