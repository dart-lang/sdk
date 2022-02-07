// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceReturnTypeFutureLintBulkTest);
    defineReflectiveTests(ReplaceReturnTypeFutureLintTest);
    defineReflectiveTests(ReplaceReturnTypeFutureTest);
  });
}

@reflectiveTest
class ReplaceReturnTypeFutureLintBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_void_async;

  Future<void> test_bulk() async {
    await resolveTestCode('''
void f1() async {}

void f2() async => null;

class C {
  void m1() async {}

  void m2() async => null;

  void m3() async {
    void f() async {};
    f();
  }
}
''');
    await assertHasFix('''
Future<void> f1() async {}

Future<void> f2() async => null;

class C {
  Future<void> m1() async {}

  Future<void> m2() async => null;

  Future<void> m3() async {
    Future<void> f() async {};
    f();
  }
}
''');
  }
}

@reflectiveTest
class ReplaceReturnTypeFutureLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_RETURN_TYPE_FUTURE;

  @override
  String get lintCode => LintNames.avoid_void_async;

  Future<void> test_function() async {
    await resolveTestCode('void f() async {}');
    await assertHasFix('Future<void> f() async {}');
  }

  Future<void> test_functionInMethod() async {
    await resolveTestCode('''
class C {
  void m() {
    void f() async {};
    f();
  }
}
''');
    await assertHasFix('''
class C {
  void m() {
    Future<void> f() async {};
    f();
  }
}
''');
  }

  Future<void> test_functionReturnNull() async {
    await resolveTestCode('void f() async => null;');
    await assertHasFix('Future<void> f() async => null;');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class C {
  void m() async {}
}
''');
    await assertHasFix('''
class C {
  Future<void> m() async {}
}
''');
  }

  Future<void> test_methodReturnNull() async {
    await resolveTestCode('''
class C {
  void m() async => null;
}
''');
    await assertHasFix('''
class C {
  Future<void> m() async => null;
}
''');
  }
}

@reflectiveTest
class ReplaceReturnTypeFutureTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_RETURN_TYPE_FUTURE;

  Future<void> test_complexTypeName_withImport() async {
    await resolveTestCode('''
import 'dart:async';
List<int> f() async {}
''');
    await assertHasFix('''
import 'dart:async';
Future<List<int>> f() async {}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_complexTypeName_withoutImport() async {
    await resolveTestCode('''
List<int> f() async {}
''');
    await assertHasFix('''
Future<List<int>> f() async {}
''');
  }

  Future<void> test_importedWithPrefix() async {
    await resolveTestCode('''
import 'dart:async' as al;
int f() async {}
''');
    await assertHasFix('''
import 'dart:async' as al;
al.Future<int> f() async {}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class C {
  int m() async {}
}
''');
    await assertHasFix('''
class C {
  Future<int> m() async {}
}
''');
  }

  Future<void> test_simpleTypeName_withImport() async {
    await resolveTestCode('''
import 'dart:async';
int f() async {}
''');
    await assertHasFix('''
import 'dart:async';
Future<int> f() async {}
''', errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE;
    });
  }

  Future<void> test_simpleTypeName_withoutImport() async {
    await resolveTestCode('''
int f() async {}
''');
    await assertHasFix('''
Future<int> f() async {}
''');
  }
}
