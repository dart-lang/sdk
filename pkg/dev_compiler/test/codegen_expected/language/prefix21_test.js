dart_library.library('language/prefix21_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__prefix21_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const prefix21_test = Object.create(null);
  const prefix21_good_lib = Object.create(null);
  const prefix21_bad_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  prefix21_test.main = function() {
    expect$.Expect.equals(dart.dcall(prefix21_good_lib.getValue, 42), 42);
    expect$.Expect.equals(dart.dcall(prefix21_bad_lib.getValue, 42), 84);
  };
  dart.fn(prefix21_test.main, VoidTodynamic());
  prefix21_good_lib.goodFunction = function(x) {
    return x;
  };
  dart.fn(prefix21_good_lib.goodFunction, intToint());
  dart.copyProperties(prefix21_good_lib, {
    get getValue() {
      return prefix21_good_lib.goodFunction;
    }
  });
  prefix21_bad_lib.badFunction = function(x) {
    return dart.notNull(x) << 1 >>> 0;
  };
  dart.fn(prefix21_bad_lib.badFunction, intToint());
  dart.copyProperties(prefix21_bad_lib, {
    get getValue() {
      return prefix21_bad_lib.badFunction;
    }
  });
  // Exports:
  exports.prefix21_test = prefix21_test;
  exports.prefix21_good_lib = prefix21_good_lib;
  exports.prefix21_bad_lib = prefix21_bad_lib;
});
