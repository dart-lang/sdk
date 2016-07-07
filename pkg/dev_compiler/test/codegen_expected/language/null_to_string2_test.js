dart_library.library('language/null_to_string2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_to_string2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_to_string2_test = Object.create(null);
  let VoidToA = () => (VoidToA = dart.constFn(dart.definiteFunctionType(null_to_string2_test.A, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  null_to_string2_test.A = class A extends core.Object {};
  null_to_string2_test.foo = function() {
    return null;
  };
  dart.fn(null_to_string2_test.foo, VoidToA());
  null_to_string2_test.main = function() {
    let nullObj = null_to_string2_test.foo();
    let x = dart.toString(nullObj);
    expect$.Expect.isTrue(typeof x == 'string');
    let y = dart.bind(nullObj, 'toString', dart.toString);
    expect$.Expect.isNotNull(y);
  };
  dart.fn(null_to_string2_test.main, VoidTodynamic());
  // Exports:
  exports.null_to_string2_test = null_to_string2_test;
});
