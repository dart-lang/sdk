// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncReturnWithNoAwait);
  });
}

@reflectiveTest
class AsyncReturnWithNoAwait extends LintRuleTest {
  @override
  String get lintRule => LintNames.async_return_with_no_await;

  Future<void> test_arrowFunction() async {
    await assertDiagnosticsFromMarkup('''
Future<int> foo() async [!=>!] Future.value(42);
''');
  }

  Future<void> test_closure_declaring() async {
    await assertDiagnosticsFromMarkup('''
var foo = () async {
  [!return!] Future.value(42);
};
''');
  }

  Future<void> test_closure_initializer() async {
    await assertDiagnosticsFromMarkup('''
var foo = () async {
  [!return!] Future.value(42);
}();
''');
  }

  Future<void> test_dynamic() async {
    await assertNoDiagnostics('''
Future<int> foo(dynamic v) async {
  return v;
}
''');
  }

  Future<void> test_dynamic_returnType() async {
    await assertDiagnosticsFromMarkup('''
foo() async {
  [!return!] Future.value(42);
}
''');
  }

  Future<void> test_function() async {
    await assertDiagnosticsFromMarkup('''
Future<int> foo() async {
  [!return!] Future.value(42);
}
''');
  }

  Future<void> test_futureOr() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:async';

Future<int> foo(FutureOr<int> v) async {
  [!return!] v;
}
''');
  }

  Future<void> test_futureOr_returnType() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:async';

FutureOr<int> foo() async {
  [!return!] Future.value(42);
}
''');
  }

  Future<void> test_futureSubtype() async {
    await assertDiagnosticsFromMarkup('''
Future<int> foo() async {
  [!return!] MyFuture();
}

class MyFuture implements Future<int> {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  Future<void> test_getter() async {
    await assertDiagnosticsFromMarkup('''
Future<int> get foo async {
  [!return!] Future.value(42);
}
''');
  }

  Future<void> test_invalidType() async {
    await assertDiagnostics(
      '''
foo() async {
  return unknown;
}
''',
      [error(diag.undefinedIdentifier, 23, 7)],
    );
  }

  Future<void> test_method() async {
    await assertDiagnosticsFromMarkup('''
class A {
  Future<int> foo() async {
    [!return!] Future.value(42);
  }
}
''');
  }

  Future<void> test_notAsync() async {
    await assertNoDiagnostics('''
Future<int> foo() {
  return Future.value(42);
}
''');
  }

  Future<void> test_sync() async {
    await assertNoDiagnostics('''
Future<int> foo() async {
  return 0;
}
''');
  }

  Future<void> test_typeParameter() async {
    await assertDiagnosticsFromMarkup('''
Future<int> foo<T extends Future<int>>(T v) async {
  [!return!] v;
}
''');
  }

  Future<void> test_withinTryBlock() async {
    await assertDiagnostics(
      '''
Future<int> foo() async {
  try {
    return Future.value(42);
  } catch (_) {
    return -1;
  }
}
''',
      [error(diag.unawaitedReturnInTryBlock, 38, 6)],
    );
  }

  Future<void> test_withinTryCatch() async {
    await assertDiagnosticsFromMarkup('''
Future<int> foo() async {
  try {} catch (_) {
    [!return!] Future.value(42);
  }
  return -1;
}
''');
  }

  Future<void> test_withinTryCatch_withinTryBlock() async {
    await assertDiagnostics(
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
    await assertDiagnostics(
      '''
Future<int> foo() async {
  return '';
}
''',
      [error(diag.returnOfInvalidTypeFromFunction, 35, 2)],
    );
  }

  Future<void> test_wrongType2() async {
    await assertDiagnostics(
      '''
Future<int>? foo() async {
  return Future<Null>.value(null);
}
''',
      [error(diag.returnOfInvalidTypeFromFunction, 36, 24)],
    );
  }
}
