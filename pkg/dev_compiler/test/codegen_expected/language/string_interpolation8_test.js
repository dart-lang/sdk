dart_library.library('language/string_interpolation8_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_interpolation8_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_interpolation8_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  string_interpolation8_test.A = class A extends core.Object {};
  string_interpolation8_test.A.x = 1;
  dart.defineLazy(string_interpolation8_test.A, {
    get y() {
      return dart.str`Two is greater than ${string_interpolation8_test.A.x}`;
    }
  });
  string_interpolation8_test.main = function() {
    expect$.Expect.identical("Two is greater than 1", string_interpolation8_test.A.y);
  };
  dart.fn(string_interpolation8_test.main, VoidTodynamic());
  // Exports:
  exports.string_interpolation8_test = string_interpolation8_test;
});
