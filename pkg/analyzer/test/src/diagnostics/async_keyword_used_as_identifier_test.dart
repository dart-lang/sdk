// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncKeywordUsedAsIdentifierTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AsyncKeywordUsedAsIdentifierTest extends PubPackageResolutionTest {
  test_async_async() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  m() async {
    int async;
//      ^^^^^
// [diag.unusedLocalVariable] The value of the local variable 'async' isn't used.
  }
}
''');
  }

  test_await_async() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async {
  var await = 1;
//    ^^^^^
// [diag.asyncKeywordUsedAsIdentifier] The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.
// [diag.unusedLocalVariable] The value of the local variable 'await' isn't used.
}
''');
  }

  test_await_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async* {
  var await = 1;
//    ^^^^^
// [diag.asyncKeywordUsedAsIdentifier] The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.
// [diag.unusedLocalVariable] The value of the local variable 'await' isn't used.
}
''');
  }

  test_await_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
f() sync* {
  var await = 1;
//    ^^^^^
// [diag.asyncKeywordUsedAsIdentifier] The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.
// [diag.unusedLocalVariable] The value of the local variable 'await' isn't used.
}
''');
  }

  test_yield_async() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async {
  var yield = 1;
//    ^^^^^
// [diag.asyncKeywordUsedAsIdentifier] The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.
// [diag.unusedLocalVariable] The value of the local variable 'yield' isn't used.
}
''');
  }

  test_yield_asyncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
f() async* {
  var yield = 1;
//    ^^^^^
// [diag.asyncKeywordUsedAsIdentifier] The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.
// [diag.unusedLocalVariable] The value of the local variable 'yield' isn't used.
}
''');
  }

  test_yield_syncStar() async {
    await resolveTestCodeWithDiagnostics(r'''
f() sync* {
  var yield = 1;
//    ^^^^^
// [diag.asyncKeywordUsedAsIdentifier] The keywords 'await' and 'yield' can't be used as identifiers in an asynchronous or generator function.
// [diag.unusedLocalVariable] The value of the local variable 'yield' isn't used.
}
''');
  }
}
