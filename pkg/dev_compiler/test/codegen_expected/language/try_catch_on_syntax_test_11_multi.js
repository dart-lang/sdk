dart_library.library('language/try_catch_on_syntax_test_11_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch_on_syntax_test_11_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch_on_syntax_test_11_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  try_catch_on_syntax_test_11_multi.MyException = class MyException extends core.Object {};
  try_catch_on_syntax_test_11_multi.MyException1 = class MyException1 extends try_catch_on_syntax_test_11_multi.MyException {};
  try_catch_on_syntax_test_11_multi.MyException2 = class MyException2 extends try_catch_on_syntax_test_11_multi.MyException {};
  try_catch_on_syntax_test_11_multi.test1 = function() {
    let foo = 0;
    try {
      dart.throw(new try_catch_on_syntax_test_11_multi.MyException1());
    } catch (e$) {
      if (try_catch_on_syntax_test_11_multi.MyException2.is(e$)) {
        let e = e$;
        foo = 1;
      } else if (try_catch_on_syntax_test_11_multi.MyException1.is(e$)) {
        let e = e$;
        foo = 2;
      } else if (try_catch_on_syntax_test_11_multi.MyException.is(e$)) {
        let e = e$;
        foo = 3;
      } else {
        let e = e$;
        foo = 4;
      }
    }

    expect$.Expect.equals(2, foo);
  };
  dart.fn(try_catch_on_syntax_test_11_multi.test1, VoidTovoid());
  try_catch_on_syntax_test_11_multi.testFinal = function() {
    try {
      dart.throw("catch this!");
    } catch (e) {
      let s = dart.stackTrace(e);
      s = null;
    }

  };
  dart.fn(try_catch_on_syntax_test_11_multi.testFinal, VoidTodynamic());
  try_catch_on_syntax_test_11_multi.main = function() {
    try_catch_on_syntax_test_11_multi.test1();
    try_catch_on_syntax_test_11_multi.testFinal();
  };
  dart.fn(try_catch_on_syntax_test_11_multi.main, VoidTodynamic());
  // Exports:
  exports.try_catch_on_syntax_test_11_multi = try_catch_on_syntax_test_11_multi;
});
