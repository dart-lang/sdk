// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(YieldOfInvalidTypeTest);
    defineReflectiveTests(YieldOfInvalidTypeWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class YieldOfInvalidTypeTest extends PubPackageResolutionTest {
  test_none_asyncStar_dynamic_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f(dynamic a) async* {
  yield a;
}
''');
  }

  test_none_asyncStar_int_to_basic() async {
    await resolveTestCodeWithDiagnostics('''
int f() async* {
// [diag.illegalAsyncGeneratorReturnType][column 1][length 3] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
dynamic f() async* {
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_iterableDynamic() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<int> f() async* {
// [diag.illegalAsyncGeneratorReturnType][column 1][length 13] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_streamDynamic() async {
    await resolveTestCodeWithDiagnostics('''
Stream f() async* {
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_streamString() async {
    await resolveTestCodeWithDiagnostics('''
Stream<String> f() async* {
  yield 0;
//      ^
// [diag.yieldOfInvalidType] A yielded value of type 'int' must be assignable to 'String'.
}
''');
  }

  test_none_asyncStar_int_to_streamString_functionExpression() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  // ignore:unused_local_variable
  Stream<String> Function() v = () async* {
    yield 1;
//        ^
// [diag.yieldOfInvalidType] A yielded value of type 'int' must be assignable to 'String'.
  };
}
''');
  }

  test_none_asyncStar_int_to_untyped() async {
    await resolveTestCodeWithDiagnostics('''
f() async* {
  yield 0;
}
''');
  }

  test_none_asyncStar_null_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  yield null;
//      ^^^^
// [diag.yieldOfInvalidType] A yielded value of type 'Null' must be assignable to 'int'.
}
''');
  }

  test_none_asyncStar_to_futureOrNullableStream() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

FutureOr<Stream<int>?> f() async* {
  yield 3.14;
//      ^^^^
// [diag.yieldOfInvalidType] A yielded value of type 'double' must be assignable to 'int'.
  yield '2';
//      ^^^
// [diag.yieldOfInvalidType] A yielded value of type 'String' must be assignable to 'int'.
  yield Future<int>.value(0);
//      ^^^^^^^^^^^^^^^^^^^^
// [diag.yieldOfInvalidType] A yielded value of type 'Future<int>' must be assignable to 'int'.
}
''');
  }

  test_none_syncStar_dynamic_to_iterableInt() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<int> f(dynamic a) sync* {
  yield a;
}
''');
  }

  test_none_syncStar_int_to_basic() async {
    await resolveTestCodeWithDiagnostics('''
int f() sync* {
// [diag.illegalSyncGeneratorReturnType][column 1][length 3] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
dynamic f() sync* {
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_iterableDynamic() async {
    await resolveTestCodeWithDiagnostics('''
Iterable f() sync* {
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_iterableInt() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<int> f() sync* {
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_iterableString() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<String> f() sync* {
  yield 0;
//      ^
// [diag.yieldOfInvalidType] A yielded value of type 'int' must be assignable to 'String'.
}
''');
  }

  test_none_syncStar_int_to_iterableString_functionExpression() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  // ignore:unused_local_variable
  Iterable<String> Function() v = () sync* {
    yield 1;
//        ^
// [diag.yieldOfInvalidType] A yielded value of type 'int' must be assignable to 'String'.
  };
}
''');
  }

  test_none_syncStar_int_to_stream() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() sync* {
// [diag.illegalSyncGeneratorReturnType][column 1][length 11] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_untyped() async {
    await resolveTestCodeWithDiagnostics('''
f() sync* {
  yield 0;
}
''');
  }

  test_none_syncStar_to_futureOrNullableIterable() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';

FutureOr<Iterable<int>?> f() sync* {
  yield 3.14;
//      ^^^^
// [diag.yieldOfInvalidType] A yielded value of type 'double' must be assignable to 'int'.
  yield '2';
//      ^^^
// [diag.yieldOfInvalidType] A yielded value of type 'String' must be assignable to 'int'.
  yield Future<int>.value(0);
//      ^^^^^^^^^^^^^^^^^^^^
// [diag.yieldOfInvalidType] A yielded value of type 'Future<int>' must be assignable to 'int'.
}
''');
  }

  test_star_asyncStar_dynamic_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() async* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_asyncStar_dynamic_to_streamDynamic() async {
    await resolveTestCodeWithDiagnostics('''
Stream f() async* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_asyncStar_dynamic_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_asyncStar_int_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() async* {
  yield* 0;
//       ^
// [diag.yieldEachOfInvalidType] The type 'int' implied by the 'yield*' expression must be assignable to 'Stream<dynamic>'.
}
''');
  }

  test_star_asyncStar_iterableInt_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() async* {
  var a = <int>[];
  yield* a;
//       ^
// [diag.yieldEachOfInvalidType] The type 'List<int>' implied by the 'yield*' expression must be assignable to 'Stream<dynamic>'.
}
''');
  }

  test_star_asyncStar_iterableInt_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  var a = <int>[];
  yield* a;
//       ^
// [diag.yieldEachOfInvalidType] The type 'List<int>' implied by the 'yield*' expression must be assignable to 'Stream<int>'.
}
''');
  }

  test_star_asyncStar_iterableString_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  var a = <String>[];
  yield* a;
//       ^
// [diag.yieldEachOfInvalidType] The type 'List<String>' implied by the 'yield*' expression must be assignable to 'Stream<int>'.
}
''');
  }

  test_star_asyncStar_streamDynamic_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() async* {
  yield* g();
}

Stream g() => throw 0;
''');
  }

  test_star_asyncStar_streamDynamic_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  yield* g();
//       ^^^
// [diag.yieldEachOfInvalidType] The type 'Stream<dynamic>' implied by the 'yield*' expression must be assignable to 'Stream<int>'.
}

Stream g() => throw 0;
''');
  }

  test_star_asyncStar_streamInt_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() async* {
  yield* g();
}

Stream<int> g() => throw 0;
''');
  }

  test_star_asyncStar_streamInt_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  yield* g();
}

Stream<int> g() => throw 0;
''');
  }

  test_star_asyncStar_streamString_to_streamInt() async {
    await resolveTestCodeWithDiagnostics('''
Stream<int> f() async* {
  yield* g();
//       ^^^
// [diag.yieldEachOfInvalidType] The type 'Stream<String>' implied by the 'yield*' expression must be assignable to 'Stream<int>'.
}

Stream<String> g() => throw 0;
''');
  }

  test_star_syncStar_dynamic_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() sync* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_syncStar_dynamic_to_iterableDynamic() async {
    await resolveTestCodeWithDiagnostics('''
Iterable f() sync* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_syncStar_dynamic_to_iterableInt() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<int> f() sync* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_syncStar_int() async {
    await resolveTestCodeWithDiagnostics('''
f() sync* {
  yield* 0;
//       ^
// [diag.yieldEachOfInvalidType] The type 'int' implied by the 'yield*' expression must be assignable to 'Iterable<dynamic>'.
}
''');
  }

  test_star_syncStar_int_closure() async {
    await resolveTestCodeWithDiagnostics('''
main() {
  var f = () sync* {
    yield* 0;
//         ^
// [diag.yieldEachOfInvalidType] The type 'int' implied by the 'yield*' expression must be assignable to 'Iterable<dynamic>'.
  };
  f;
}
''');
  }

  test_star_syncStar_iterableDynamic_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() sync* {
  yield* g();
}

Iterable g() => throw 0;
''');
  }

  test_star_syncStar_iterableDynamic_to_iterableInt() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<int> f() sync* {
  yield* g();
//       ^^^
// [diag.yieldEachOfInvalidType] The type 'Iterable<dynamic>' implied by the 'yield*' expression must be assignable to 'Iterable<int>'.
}

Iterable g() => throw 0;
''');
  }

  test_star_syncStar_iterableInt_to_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
f() sync* {
  yield* g();
}

Iterable<int> g() => throw 0;
''');
  }

  test_star_syncStar_iterableInt_to_iterableInt() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<int> f() sync* {
  yield* g();
}

Iterable<int> g() => throw 0;
''');
  }

  test_star_syncStar_iterableString_to_iterableInt() async {
    await resolveTestCodeWithDiagnostics('''
Iterable<int> f() sync* {
  yield* g();
//       ^^^
// [diag.yieldEachOfInvalidType] The type 'Iterable<String>' implied by the 'yield*' expression must be assignable to 'Iterable<int>'.
}

Iterable<String> g() => throw 0;
''');
  }
}

@reflectiveTest
class YieldOfInvalidTypeWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_yieldEach_asyncStar() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
f(dynamic a) async* {
  yield* a;
//       ^
// [diag.yieldEachOfInvalidType] The type 'dynamic' implied by the 'yield*' expression must be assignable to 'Stream<dynamic>'.
}
''');
  }

  test_yieldEach_syncStar() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
f(dynamic a) sync* {
  yield* a;
//       ^
// [diag.yieldEachOfInvalidType] The type 'dynamic' implied by the 'yield*' expression must be assignable to 'Iterable<dynamic>'.
}
''');
  }
}
