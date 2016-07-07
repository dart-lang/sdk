dart_library.library('language/load_indexed_constant_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__load_indexed_constant_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const load_indexed_constant_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  load_indexed_constant_test.main = function() {
    expect$.Expect.equals(101, load_indexed_constant_test.stringIndexedLoad());
    expect$.Expect.equals(102, load_indexed_constant_test.arrayIndexedLoad());
    for (let i = 0; i < 20; i++) {
      load_indexed_constant_test.stringIndexedLoad();
      load_indexed_constant_test.arrayIndexedLoad();
    }
    expect$.Expect.equals(101, load_indexed_constant_test.stringIndexedLoad());
    expect$.Expect.equals(102, load_indexed_constant_test.arrayIndexedLoad());
  };
  dart.fn(load_indexed_constant_test.main, VoidTodynamic());
  load_indexed_constant_test.stringIndexedLoad = function() {
    return "Hello"[dartx.codeUnitAt](1);
  };
  dart.fn(load_indexed_constant_test.stringIndexedLoad, VoidTodynamic());
  let const$;
  load_indexed_constant_test.arrayIndexedLoad = function() {
    return (const$ || (const$ = dart.constList([101, 102, 103], core.int)))[dartx.get](1);
  };
  dart.fn(load_indexed_constant_test.arrayIndexedLoad, VoidTodynamic());
  // Exports:
  exports.load_indexed_constant_test = load_indexed_constant_test;
});
