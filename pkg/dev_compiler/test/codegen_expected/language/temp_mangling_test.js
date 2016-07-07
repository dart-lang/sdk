dart_library.library('language/temp_mangling_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__temp_mangling_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const temp_mangling_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  temp_mangling_test.main = function() {
    temp_mangling_test.testOne();
    temp_mangling_test.testTwo();
  };
  dart.fn(temp_mangling_test.main, VoidTodynamic());
  temp_mangling_test.testOne = function() {
    let t0 = core.List.new();
    expect$.Expect.isTrue(typeof t0[dartx.length] == 'number');
    expect$.Expect.isTrue(core.List.is(t0));
  };
  dart.fn(temp_mangling_test.testOne, VoidTodynamic());
  temp_mangling_test.testTwo = function() {
    let x = core.List.new();
    let x_0 = core.List.new();
    {
      let x = core.Set.new();
      expect$.Expect.equals(0, x.length);
      expect$.Expect.isTrue(x.isEmpty);
    }
    expect$.Expect.isTrue(core.List.is(x));
    expect$.Expect.isTrue(core.List.is(x_0));
  };
  dart.fn(temp_mangling_test.testTwo, VoidTodynamic());
  // Exports:
  exports.temp_mangling_test = temp_mangling_test;
});
