dart_library.library('language/library5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__library5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const library5_test = Object.create(null);
  const library5a = Object.create(null);
  const library5b = Object.create(null);
  let FunToint = () => (FunToint = dart.constFn(dart.definiteFunctionType(core.int, [library5a.Fun])))();
  let FunToint$ = () => (FunToint$ = dart.constFn(dart.definiteFunctionType(core.int, [library5b.Fun])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  library5_test.foo = function(f) {
    return f();
  };
  dart.lazyFn(library5_test.foo, () => FunToint());
  library5_test.bar = function(f) {
    return dart.dcall(f, 42);
  };
  dart.lazyFn(library5_test.bar, () => FunToint$());
  library5_test.main = function() {
    expect$.Expect.equals(41, library5_test.foo(dart.fn(() => 41, VoidToint())));
    expect$.Expect.equals(42, library5_test.bar(dart.fn(x => core.int._check(x), dynamicToint())));
  };
  dart.fn(library5_test.main, VoidTodynamic());
  library5a.Fun = dart.typedef('Fun', () => dart.functionType(core.int, []));
  library5b.Fun = dart.typedef('Fun', () => dart.functionType(core.int, [dart.dynamic]));
  // Exports:
  exports.library5_test = library5_test;
  exports.library5a = library5a;
  exports.library5b = library5b;
});
