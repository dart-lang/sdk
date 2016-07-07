dart_library.library('language/generic_async_star_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_async_star_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_async_star_test = Object.create(null);
  let TToStreamOfT = () => (TToStreamOfT = dart.constFn(dart.definiteFunctionType(T => [async.Stream$(T), [T]])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_async_star_test.foo = function(T) {
    return x => {
      return dart.asyncStar(function*(stream, x) {
        for (let i = 0; i < 3; i++) {
          if (stream.add(x)) return;
          yield;
        }
      }, T, x);
    };
  };
  dart.fn(generic_async_star_test.foo, TToStreamOfT());
  generic_async_star_test.main = function() {
    return dart.async(function*() {
      let it = async.StreamIterator.new(generic_async_star_test.foo(core.int)(1));
      try {
        while (yield it.moveNext()) {
          let x = it.current;
          expect$.Expect.equals(1, x);
        }
      } finally {
        yield it.cancel();
      }
    }, dart.dynamic);
  };
  dart.fn(generic_async_star_test.main, VoidTodynamic());
  // Exports:
  exports.generic_async_star_test = generic_async_star_test;
});
