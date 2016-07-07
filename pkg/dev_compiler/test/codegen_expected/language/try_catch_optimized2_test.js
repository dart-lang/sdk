dart_library.library('language/try_catch_optimized2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__try_catch_optimized2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const try_catch_optimized2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  try_catch_optimized2_test.bar = function() {
    try {
    } finally {
    }
  };
  dart.fn(try_catch_optimized2_test.bar, VoidTodynamic());
  try_catch_optimized2_test.foo = function(a) {
    let r = 0;
    for (let i of core.Iterable._check(a)) {
      r = dart.notNull(r) + dart.notNull(core.int._check(i));
    }
    try {
      try_catch_optimized2_test.bar();
    } finally {
    }
    return r;
  };
  dart.fn(try_catch_optimized2_test.foo, dynamicTodynamic());
  try_catch_optimized2_test.main = function() {
    let a = JSArrayOfint().of([1, 2, 3]);
    for (let i = 0; i < 20; i++)
      try_catch_optimized2_test.foo(a);
    expect$.Expect.equals(6, try_catch_optimized2_test.foo(a));
  };
  dart.fn(try_catch_optimized2_test.main, VoidTodynamic());
  // Exports:
  exports.try_catch_optimized2_test = try_catch_optimized2_test;
});
