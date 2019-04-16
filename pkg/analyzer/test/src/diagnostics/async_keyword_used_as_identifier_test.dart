// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncKeywordUsedAsIdentifierTest);
  });
}

@reflectiveTest
class AsyncKeywordUsedAsIdentifierTest extends DriverResolutionTest {
  test_async_annotation() async {
    await assertErrorsInCode('''
const int async = 0;
f() async {
  g(@async x) {}
  g(0);
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 38, 5),
    ]);
  }

  test_async_argumentLabel() async {
    await assertErrorsInCode('''
f(c) async {
  c.g(async: 0);
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 19, 5),
    ]);
  }

  test_async_async() async {
    await assertErrorsInCode('''
f() async {
  var async = 1;
  print(async);
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 37, 5),
    ]);
  }

  test_async_asyncStar() async {
    await assertErrorsInCode('''
f() async* {
  var async = 1;
  print(async);
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 19, 5),
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 38, 5),
    ]);
  }

  test_async_break() async {
    await assertErrorsInCode('''
f() async {
  while (true) {
    break async;
  }
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 39, 5),
      error(CompileTimeErrorCode.LABEL_UNDEFINED, 39, 5),
    ]);
  }

  test_async_catchException() async {
    await assertErrorsInCode('''
g() {}
f() async {
  try {
    g();
  } catch (async) { }
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 47, 5),
    ]);
  }

  test_async_catchStacktrace() async {
    await assertErrorsInCode('''
g() {}
f() async {
  try {
    g();
  } catch (e, async) { }
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 50, 5),
      error(HintCode.UNUSED_CATCH_STACK, 50, 5),
    ]);
  }

  test_async_continue() async {
    await assertErrorsInCode('''
f() async {
  while (true) {
    continue async;
  }
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 42, 5),
      error(CompileTimeErrorCode.LABEL_UNDEFINED, 42, 5),
    ]);
  }

  test_async_for() async {
    await assertErrorsInCode('''
var async;
f() async {
  for (async in []) {}
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 30, 5),
    ]);
  }

  test_async_formalParameter() async {
    await assertErrorsInCode('''
f() async {
  g(int async) {}
  g(0);
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 20, 5),
    ]);
  }

  test_async_getter() async {
    await assertErrorsInCode('''
class C {
  int get async => 1;
}
f() async {
  return new C().async;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 63, 5),
    ]);
  }

  test_async_invocation() async {
    await assertErrorsInCode('''
class C {
  int async() => 1;
}
f() async {
  return new C().async();
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 61, 5),
    ]);
  }

  test_async_invocation_cascaded() async {
    await assertErrorsInCode('''
class C {
  int async() => 1;
}
f() async {
  return new C()..async();
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 62, 5),
    ]);
  }

  test_async_label() async {
    await assertErrorsInCode('''
f() async {
  async: g();
}
g() {}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 14, 5),
      error(HintCode.UNUSED_LABEL, 14, 6),
    ]);
  }

  test_async_localFunction() async {
    await assertErrorsInCode('''
f() async {
  int async() => null;
  async();
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 37, 5),
    ]);
  }

  test_async_prefix() async {
    await assertErrorsInCode('''
import 'dart:async' as async;
f() async {
  return new async.Future.value(0);
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 55, 5),
    ]);
  }

  test_async_setter() async {
    await assertErrorsInCode('''
class C {
  void set async(int i) {}
}
f() async {
  new C().async = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 61, 5),
    ]);
  }

  test_async_setter_cascaded() async {
    await assertErrorsInCode('''
class C {
  void set async(int i) {}
}
f() async {
  return new C()..async = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 69, 5),
    ]);
  }

  test_async_stringInterpolation() async {
    await assertErrorsInCode(r'''
int async = 1;
f() async {
  return "$async";
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 38, 5),
    ]);
  }

  test_async_suffix() async {
    newFile("/test/lib/lib1.dart", content: r'''
library lib1;
int async;
''');
    await assertErrorsInCode('''
import 'lib1.dart' as l;
f() async {
  return l.async;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 48, 5),
    ]);
  }

  test_async_switchLabel() async {
    await assertErrorsInCode('''
f() async {
  switch (0) {
    async: case 0: break;
  }
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 31, 5),
      error(HintCode.UNUSED_LABEL, 31, 6),
    ]);
  }

  test_async_syncStar() async {
    await assertErrorsInCode('''
f() sync* {
  var async = 1;
  print(async);
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 37, 5),
    ]);
  }

  test_await_async() async {
    await assertErrorsInCode('''
f() async {
  var await = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }

  test_await_asyncStar() async {
    await assertErrorsInCode('''
f() async* {
  var await = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 19, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 5),
    ]);
  }

  test_await_syncStar() async {
    await assertErrorsInCode('''
f() sync* {
  var await = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }
}
