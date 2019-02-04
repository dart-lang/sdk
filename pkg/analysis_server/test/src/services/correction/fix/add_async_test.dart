// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddAsyncTest);
  });
}

@reflectiveTest
class AddAsyncTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_ASYNC;

  test_asyncFor() async {
    await resolveTestUnit('''
import 'dart:async';
void main(Stream<String> names) {
  await for (String name in names) {
    print(name);
  }
}
''');
    await assertHasFix('''
import 'dart:async';
Future main(Stream<String> names) async {
  await for (String name in names) {
    print(name);
  }
}
''');
  }

  test_blockFunctionBody_function() async {
    await resolveTestUnit('''
foo() {}
main() {
  await foo();
}
''');
    await assertHasFix('''
foo() {}
main() async {
  await foo();
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode ==
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE;
    });
  }

  test_blockFunctionBody_getter() async {
    await resolveTestUnit('''
int get foo => null;
int f() {
  await foo;
  return 1;
}
''');
    await assertHasFix('''
int get foo => null;
Future<int> f() async {
  await foo;
  return 1;
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode ==
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE;
    });
  }

  test_closure() async {
    await resolveTestUnit('''
import 'dart:async';

void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() => await 1);
''');
    await assertHasFix('''
import 'dart:async';

void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() async => await 1);
''', errorFilter: (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    });
  }

  test_expressionFunctionBody() async {
    await resolveTestUnit('''
foo() {}
main() => await foo();
''');
    await assertHasFix('''
foo() {}
main() async => await foo();
''');
  }

  test_nullFunctionBody() async {
    await resolveTestUnit('''
var F = await;
''');
    await assertNoFix();
  }

  test_returnFuture_alreadyFuture() async {
    await resolveTestUnit('''
import 'dart:async';
foo() {}
Future<int> main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
import 'dart:async';
foo() {}
Future<int> main() async {
  await foo();
  return 42;
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode ==
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE;
    });
  }

  test_returnFuture_dynamic() async {
    await resolveTestUnit('''
foo() {}
dynamic main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
dynamic main() async {
  await foo();
  return 42;
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode ==
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE;
    });
  }

  test_returnFuture_nonFuture() async {
    await resolveTestUnit('''
foo() {}
int main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
Future<int> main() async {
  await foo();
  return 42;
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode ==
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE;
    });
  }

  test_returnFuture_noType() async {
    await resolveTestUnit('''
foo() {}
main() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
main() async {
  await foo();
  return 42;
}
''', errorFilter: (AnalysisError error) {
      return error.errorCode ==
          CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE;
    });
  }
}
