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
    defineReflectiveTests(ReplaceReturnTypeTest);
  });
}

@reflectiveTest
class ReplaceReturnTypeTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_RETURN_TYPE;

  Future<void> test_async_method() async {
    await resolveTestCode('''
class A {
  Future<int> m() async {
    return '';
  }
}
''');
    await assertHasFix('''
class A {
  Future<String> m() async {
    return '';
  }
}
''');
  }

  Future<void> test_closure() async {
    await resolveTestCode('''
class A {
  int m() {
    var list = <String>[];
    list.map((e) {
      return 0;
    });
    return 2.4;
  }
}
''');
    await assertHasFix('''
class A {
  double m() {
    var list = <String>[];
    list.map((e) {
      return 0;
    });
    return 2.4;
  }
}
''');
  }

  Future<void> test_function() async {
    await resolveTestCode('''
int f() {
  return '';
}
''');
    await assertHasFix('''
String f() {
  return '';
}
''');
  }

  Future<void> test_function_local() async {
    await resolveTestCode('''
void top() {
  int f() {
    return '';
  }
}
''');
    await assertHasFix('''
void top() {
  String f() {
    return '';
  }
}
''', errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION;
    });
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class A {
  int m() {
    return '';
  }
}
''');
    await assertHasFix('''
class A {
  String m() {
    return '';
  }
}
''');
  }

  Future<void> test_methodOverride() async {
    await resolveTestCode('''
class A {
  A m() => this;
}
class B extends A {
  @override
  int m() => this;
}
''');
    await assertHasFix('''
class A {
  A m() => this;
}
class B extends A {
  @override
  B m() => this;
}
''', errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD;
    });
  }

  Future<void> test_methodOverride_multiple_subtype() async {
    await resolveTestCode('''
class A {}
class B extends A {}

class Parent {
  A m() => A();
}

class I {
  B m() => B();
}

class D extends Parent implements I {
  @override
  B m() => A();
}
''');

    await assertNoFix();
  }

  Future<void> test_methodOverride_subtype() async {
    await resolveTestCode('''
class A {
  B m() => B();
}
class B extends A {
  @override
  B m() => A();
}
''');
    await assertNoFix();
  }

  Future<void> test_privateType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  _B b => _B();
}
class _B {}
''');

    await resolveTestCode('''
import 'package:test/a.dart';

int f(A a) {
  return a.b();
}
''');
    await assertNoFix();
  }

  Future<void> test_upperBound_function() async {
    await resolveTestCode('''
int f() {
  if (true) {
    return 3;
  }
  return 2.4;
}
''');
    await assertHasFix('''
num f() {
  if (true) {
    return 3;
  }
  return 2.4;
}
''', errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION;
    });
  }

  Future<void> test_upperBound_method() async {
    await resolveTestCode('''
class A {
  int m() {
    if (true) {
      return 3;
    }
    return 2.4;
  }
}
''');
    await assertHasFix('''
class A {
  num m() {
    if (true) {
      return 3;
    }
    return 2.4;
  }
}
''', errorFilter: (error) {
      return error.errorCode ==
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD;
    });
  }
}
