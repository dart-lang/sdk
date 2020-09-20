// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(YieldOfInvalidTypeTest);
    defineReflectiveTests(YieldOfInvalidTypeTest2);
  });
}

@reflectiveTest
class YieldOfInvalidTypeTest extends PubPackageResolutionTest {
  test_none_asyncStar_dynamic_to_streamInt() async {
    await assertErrorsInCode(
        '''
Stream<int> f() async* {
  dynamic a = 0;
  yield a;
}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 50, 1),
        ], legacy: []));
  }

  test_none_asyncStar_int_to_basic() async {
    await assertErrorsInCode('''
int f() async* {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 0, 3),
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 25, 1),
    ]);
  }

  test_none_asyncStar_int_to_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f() async* {
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_iterableDynamic() async {
    await assertErrorsInCode('''
Iterable<int> f() async* {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 0, 13),
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 35, 1),
    ]);
  }

  test_none_asyncStar_int_to_streamDynamic() async {
    await assertNoErrorsInCode('''
Stream f() async* {
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_streamInt() async {
    await assertNoErrorsInCode('''
Stream<int> f() async* {
  yield 0;
}
''');
  }

  test_none_asyncStar_int_to_streamString() async {
    await assertErrorsInCode('''
Stream<String> f() async* {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 36, 1),
    ]);
  }

  test_none_asyncStar_int_to_untyped() async {
    await assertNoErrorsInCode('''
f() async* {
  yield 0;
}
''');
  }

  test_none_syncStar_dynamic_to_iterableInt() async {
    await assertErrorsInCode(
        '''
Iterable<int> f() sync* {
  dynamic a = 0;
  yield a;
}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 51, 1),
        ], legacy: []));
  }

  test_none_syncStar_int_to_basic() async {
    await assertErrorsInCode('''
int f() sync* {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 0, 3),
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 24, 1),
    ]);
  }

  test_none_syncStar_int_to_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f() sync* {
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_iterableDynamic() async {
    await assertNoErrorsInCode('''
Iterable f() sync* {
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_iterableInt() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  yield 0;
}
''');
  }

  test_none_syncStar_int_to_iterableString() async {
    await assertErrorsInCode('''
Iterable<String> f() sync* {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 37, 1),
    ]);
  }

  test_none_syncStar_int_to_stream() async {
    await assertErrorsInCode('''
Stream<int> f() sync* {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 0, 11),
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 32, 1),
    ]);
  }

  test_none_syncStar_int_to_untyped() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield 0;
}
''');
  }

  test_star_asyncStar_dynamic_to_dynamic() async {
    await assertNoErrorsInCode('''
f() async* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_asyncStar_dynamic_to_streamDynamic() async {
    await assertNoErrorsInCode('''
Stream f() async* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_asyncStar_dynamic_to_streamInt() async {
    await assertNoErrorsInCode('''
Stream<int> f() async* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_asyncStar_int_to_dynamic() async {
    await assertErrorsInCode('''
f() async* {
  yield* 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 22, 1),
    ]);
  }

  test_star_asyncStar_iterableInt_to_dynamic() async {
    await assertErrorsInCode('''
f() async* {
  var a = <int>[];
  yield* a;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 41, 1),
    ]);
  }

  test_star_asyncStar_iterableInt_to_streamInt() async {
    await assertErrorsInCode('''
Stream<int> f() async* {
  var a = <int>[];
  yield* a;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 53, 1),
    ]);
  }

  test_star_asyncStar_iterableString_to_streamInt() async {
    await assertErrorsInCode('''
Stream<int> f() async* {
  var a = <String>[];
  yield* a;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 56, 1),
    ]);
  }

  test_star_asyncStar_streamDynamic_to_dynamic() async {
    await assertNoErrorsInCode('''
f() async* {
  yield* g();
}

Stream g() => throw 0;
''');
  }

  test_star_asyncStar_streamDynamic_to_streamInt() async {
    await assertErrorsInCode(
        '''
Stream<int> f() async* {
  yield* g();
}

Stream g() => throw 0;
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 34, 3),
        ], legacy: []));
  }

  test_star_asyncStar_streamInt_to_dynamic() async {
    await assertNoErrorsInCode('''
f() async* {
  yield* g();
}

Stream<int> g() => throw 0;
''');
  }

  test_star_asyncStar_streamInt_to_streamInt() async {
    await assertNoErrorsInCode('''
Stream<int> f() async* {
  yield* g();
}

Stream<int> g() => throw 0;
''');
  }

  test_star_asyncStar_streamString_to_streamInt() async {
    await assertErrorsInCode('''
Stream<int> f() async* {
  yield* g();
}

Stream<String> g() => throw 0;
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 34, 3),
    ]);
  }

  test_star_syncStar_dynamic_to_dynamic() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_syncStar_dynamic_to_iterableDynamic() async {
    await assertNoErrorsInCode('''
Iterable f() sync* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_syncStar_dynamic_to_iterableInt() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  yield* g();
}

g() => throw 0;
''');
  }

  test_star_syncStar_int() async {
    await assertErrorsInCode('''
f() sync* {
  yield* 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 21, 1),
    ]);
  }

  test_star_syncStar_int_closure() async {
    await assertErrorsInCode('''
main() {
  var f = () sync* {
    yield* 0;
  };
  f;
}
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 41, 1),
    ]);
  }

  test_star_syncStar_iterableDynamic_to_dynamic() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield* g();
}

Iterable g() => throw 0;
''');
  }

  test_star_syncStar_iterableDynamic_to_iterableInt() async {
    await assertErrorsInCode(
        '''
Iterable<int> f() sync* {
  yield* g();
}

Iterable g() => throw 0;
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 35, 3),
        ], legacy: []));
  }

  test_star_syncStar_iterableInt_to_dynamic() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield* g();
}

Iterable<int> g() => throw 0;
''');
  }

  test_star_syncStar_iterableInt_to_iterableInt() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  yield* g();
}

Iterable<int> g() => throw 0;
''');
  }

  test_star_syncStar_iterableString_to_iterableInt() async {
    await assertErrorsInCode('''
Iterable<int> f() sync* {
  yield* g();
}

Iterable<String> g() => throw 0;
''', [
      error(CompileTimeErrorCode.YIELD_OF_INVALID_TYPE, 35, 3),
    ]);
  }
}

@reflectiveTest
class YieldOfInvalidTypeTest2 extends YieldOfInvalidTypeTest
    with WithNullSafetyMixin {}
