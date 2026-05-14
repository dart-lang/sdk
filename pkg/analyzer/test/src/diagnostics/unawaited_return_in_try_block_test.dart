// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnawaitedReturnInTryBlockTest);
  });
}

@reflectiveTest
class UnawaitedReturnInTryBlockTest extends PubPackageResolutionTest {
  Future<void> test_arrowFunction() async {
    await assertNoErrorsInCode('''
Future<int> foo() async => Future.value(42);
''');
  }

  Future<void> test_dynamic() async {
    await assertNoErrorsInCode('''
Future<int> foo(dynamic v) async {
  try {
    return v;
  } catch (_) {}
  return v;
}
''');
  }

  Future<void> test_dynamic_returnType() async {
    await assertErrorsInCode(
      '''
foo() async {
  try {
    return Future.value(42);
  } catch (_) {}
  return Future.value(42);
}
''',
      [error(diag.unawaitedReturnInTryBlock, 26, 6)],
    );
  }

  Future<void> test_finallyBlock() async {
    await assertNoErrorsInCode('''
Future<int> foo() async {
  try {
  } finally {
    return Future.value(42);
  }
}
''');
  }

  Future<void> test_futureOr() async {
    await assertErrorsInCode(
      '''
import 'dart:async';

Future<int> foo(FutureOr<int> v) async {
  try {
    return v;
  } catch (_) {}
  return v;
}
''',
      [error(diag.unawaitedReturnInTryBlock, 75, 6)],
    );
  }

  Future<void> test_futureOr_returnType() async {
    await assertErrorsInCode(
      '''
import 'dart:async';

FutureOr<int> foo() async {
  try {
    return Future.value(42);
  } catch (_) {}
  return Future.value(42);
}
''',
      [error(diag.unawaitedReturnInTryBlock, 62, 6)],
    );
  }

  Future<void> test_futureSubtype() async {
    await assertErrorsInCode(
      '''
Future<int> foo() async {
  try {
    return MyFuture();
  } catch (_) {}
  return MyFuture();
}

class MyFuture implements Future<int> {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''',
      [error(diag.unawaitedReturnInTryBlock, 38, 6)],
    );
  }

  Future<void> test_insideBlock() async {
    await assertErrorsInCode(
      '''
Future<void> foo() async {
  try {
    {
      return Future<Null>.value(null);
    }
  } catch (_) {}
}
''',
      [error(diag.unawaitedReturnInTryBlock, 47, 6)],
    );
  }

  Future<void> test_insideClosure() async {
    await assertNoErrorsInCode('''
void foo() {
  try {
    () async {
      return Future<Null>.value(null);
    }();
  } catch (_) {}
}
''');
  }

  Future<void> test_insideClosure_functionExpression() async {
    await assertErrorsInCode(
      '''
void foo() {
  try {
    var x = () async => return Future.value(null);
  } catch (_) {}
}
''',
      [
        error(diag.unusedLocalVariable, 29, 1),
        error(diag.unexpectedToken, 45, 6),
      ],
    );
  }

  Future<void> test_invalidType() async {
    await assertErrorsInCode(
      '''
foo() async {
  return unknown;
}
''',
      [error(diag.undefinedIdentifier, 23, 7)],
    );
  }

  Future<void> test_localFunction() async {
    await assertErrorsInCode(
      '''
void f() {
  Future<int> foo() async {
    try {
      return Future.value(0);
    } catch (_) {}
    return 0;
  }
  foo();
}
''',
      [error(diag.unawaitedReturnInTryBlock, 55, 6)],
    );
  }

  Future<void> test_localFunctionExpression_blockBody() async {
    await assertErrorsInCode(
      '''
void f() {
  var foo = () async {
    try {
      return Future.value(0);
    } catch (_) {}
    return 0;
  };
  foo();
}
''',
      [error(diag.unawaitedReturnInTryBlock, 50, 6)],
    );
  }

  Future<void> test_method() async {
    await assertErrorsInCode(
      '''
class A {
  Future<int> foo() async {
    try {
      return Future.value(0);
    } catch (_) {}
    return 0;
  }
}
''',
      [error(diag.unawaitedReturnInTryBlock, 54, 6)],
    );
  }

  Future<void> test_nestedTry() async {
    await assertErrorsInCode(
      '''
Future<int> foo() async {
  try {
    try {
    } catch (_) {
      return Future.value(42);
    }
  } catch (_) {}
  return -1;
}
''',
      [error(diag.unawaitedReturnInTryBlock, 68, 6)],
    );
  }

  Future<void> test_nonFuture() async {
    await assertNoErrorsInCode('''
Future<int> foo() async {
  try {
    return 0;
  } catch (_) {}
  return 0;
}
''');
  }

  Future<void> test_notAsync() async {
    await assertNoErrorsInCode('''
Future<int> foo() {
  try {
    return Future.value(42);
  } catch (_) {}
  return Future.value(42);
}
''');
  }

  Future<void> test_stream() async {
    await assertErrorsInCode(
      '''
import 'dart:async';

Stream<int> foo() async* {
  try {
    yield 42;
    return Future.value(42);
  } catch (_) {}
}
''',
      [error(diag.returnInGenerator, 75, 6)],
    );
  }

  Future<void> test_typeParameter() async {
    await assertErrorsInCode(
      '''
Future<int> foo<T extends Future<int>>(T v) async {
  try {
    return v;
  } catch (_) {}
  return v;
}
''',
      [error(diag.unawaitedReturnInTryBlock, 64, 6)],
    );
  }

  Future<void> test_withinTryCatch() async {
    await assertNoErrorsInCode('''
Future<int> foo() async {
  try {} catch (_) {
    return Future.value(42);
  }
  return -1;
}
''');
  }

  Future<void> test_withinTryCatch_withinTryBlock() async {
    await assertErrorsInCode(
      '''
Future<int> foo() async {
  try {
    try {} catch (_) {
      return Future.value(42);
    }
  } catch (_) {}
  return -1;
}
''',
      [error(diag.unawaitedReturnInTryBlock, 63, 6)],
    );
  }

  Future<void> test_wrongType() async {
    await assertErrorsInCode(
      '''
Future<int> foo() async {
  return '';
}
''',
      [error(diag.returnOfInvalidTypeFromFunction, 35, 2)],
    );
  }

  Future<void> test_wrongType2() async {
    await assertErrorsInCode(
      '''
Future<int>? foo() async {
  return Future<Null>.value(null);
}
''',
      [error(diag.returnOfInvalidTypeFromFunction, 36, 24)],
    );
  }
}
