dart_library.library('language/try_catch_optimized4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch_optimized4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch_optimized4_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(try_catch_optimized4_test, {
    get a() {
      return JSArrayOfObject().of([1, 2, 3, 4, 5]);
    },
    set a(_) {}
  });
  try_catch_optimized4_test.MyError = class MyError extends core.Object {};
  try_catch_optimized4_test.M = class M extends core.Object {
    maythrow(i) {
      try {
        if (dart.test(dart.dsend(i, '<=', 5))) dart.throw(new try_catch_optimized4_test.MyError());
      } catch (e) {
        dart.throw(e);
      }

    }
  };
  dart.setSignature(try_catch_optimized4_test.M, {
    methods: () => ({maythrow: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  try_catch_optimized4_test.loop_test = function() {
    let failed = false;
    let m = new try_catch_optimized4_test.M();
    for (let i of try_catch_optimized4_test.a) {
      try {
        let res = core.String._check(m.maythrow(i));
        failed = true;
      } catch (e) {
        if (try_catch_optimized4_test.MyError.is(e)) {
        } else
          throw e;
      }

      if (!core.identical(failed, false)) {
        expect$.Expect.fail("");
      }
    }
  };
  dart.fn(try_catch_optimized4_test.loop_test, VoidTodynamic());
  try_catch_optimized4_test.main = function() {
    for (let i = 0; i < 20; i++)
      try_catch_optimized4_test.loop_test();
  };
  dart.fn(try_catch_optimized4_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch_optimized4_test = try_catch_optimized4_test;
});
