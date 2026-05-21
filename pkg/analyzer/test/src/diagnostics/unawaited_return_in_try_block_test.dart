// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnawaitedReturnInTryBlockTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnawaitedReturnInTryBlockTest extends PubPackageResolutionTest {
  Future<void> test_arrowFunction() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async => Future.value(42);
''');
  }

  Future<void> test_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo(dynamic v) async {
  try {
    return v;
  } catch (_) {}
  return v;
}
''');
  }

  Future<void> test_dynamic_returnType() async {
    await resolveTestCodeWithDiagnostics('''
foo() async {
  try {
    return Future.value(42);
//  ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
  } catch (_) {}
  return Future.value(42);
}
''');
  }

  Future<void> test_finallyBlock() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async {
  try {
  } finally {
    return Future.value(42);
  }
}
''');
  }

  Future<void> test_futureOr() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

Future<int> foo(FutureOr<int> v) async {
  try {
    return v;
//  ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
  } catch (_) {}
  return v;
}
''');
  }

  Future<void> test_futureOr_returnType() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

FutureOr<int> foo() async {
  try {
    return Future.value(42);
//  ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
  } catch (_) {}
  return Future.value(42);
}
''');
  }

  Future<void> test_futureSubtype() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async {
  try {
    return MyFuture();
//  ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
  } catch (_) {}
  return MyFuture();
}

class MyFuture implements Future<int> {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_insideBlock() async {
    await resolveTestCodeWithDiagnostics('''
Future<void> foo() async {
  try {
    {
      return Future<Null>.value(null);
//    ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
    }
  } catch (_) {}
}
''');
  }

  Future<void> test_insideClosure() async {
    await resolveTestCodeWithDiagnostics('''
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
    await resolveTestCodeWithDiagnostics('''
void foo() {
  try {
    var x = () async => return Future.value(null);
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//                      ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
  } catch (_) {}
}
''');
  }

  Future<void> test_invalidType() async {
    await resolveTestCodeWithDiagnostics('''
foo() async {
  return unknown;
//       ^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unknown'.
}
''');
  }

  Future<void> test_localFunction() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  Future<int> foo() async {
    try {
      return Future.value(0);
//    ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
    } catch (_) {}
    return 0;
  }
  foo();
}
''');
  }

  Future<void> test_localFunctionExpression_blockBody() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  var foo = () async {
    try {
      return Future.value(0);
//    ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
    } catch (_) {}
    return 0;
  };
  foo();
}
''');
  }

  Future<void> test_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  Future<int> foo() async {
    try {
      return Future.value(0);
//    ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
    } catch (_) {}
    return 0;
  }
}
''');
  }

  Future<void> test_nestedTry() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async {
  try {
    try {
    } catch (_) {
      return Future.value(42);
//    ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
    }
  } catch (_) {}
  return -1;
}
''');
  }

  Future<void> test_nonFuture() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async {
  try {
    return 0;
  } catch (_) {}
  return 0;
}
''');
  }

  Future<void> test_notAsync() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() {
  try {
    return Future.value(42);
  } catch (_) {}
  return Future.value(42);
}
''');
  }

  Future<void> test_stream() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

Stream<int> foo() async* {
  try {
    yield 42;
    return Future.value(42);
//  ^^^^^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
  } catch (_) {}
}
''');
  }

  Future<void> test_typeParameter() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo<T extends Future<int>>(T v) async {
  try {
    return v;
//  ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
  } catch (_) {}
  return v;
}
''');
  }

  Future<void> test_withinTryCatch() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async {
  try {} catch (_) {
    return Future.value(42);
  }
  return -1;
}
''');
  }

  Future<void> test_withinTryCatch_withinTryBlock() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async {
  try {
    try {} catch (_) {
      return Future.value(42);
//    ^^^^^^
// [diag.unawaitedReturnInTryBlock] Returning a 'Future' without 'await' inside a try block.
    }
  } catch (_) {}
  return -1;
}
''');
  }

  Future<void> test_wrongType() async {
    await resolveTestCodeWithDiagnostics('''
Future<int> foo() async {
  return '';
//       ^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'foo' because it has a return type of 'Future<int>'.
}
''');
  }

  Future<void> test_wrongType2() async {
    await resolveTestCodeWithDiagnostics('''
Future<int>? foo() async {
  return Future<Null>.value(null);
//       ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Future<Null>' can't be returned from the function 'foo' because it has a return type of 'Future<int>?'.
}
''');
  }
}
