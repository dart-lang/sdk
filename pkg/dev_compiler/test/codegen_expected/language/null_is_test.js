dart_library.library('language/null_is_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__null_is_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const null_is_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  null_is_test.main = function() {
    expect$.Expect.isTrue(core.Object.is(null));
    expect$.Expect.isTrue(core.Null.is(null));
    expect$.Expect.isFalse(typeof null == 'number');
    expect$.Expect.isFalse(typeof null == 'boolean');
    expect$.Expect.isFalse(typeof null == 'number');
    expect$.Expect.isFalse(typeof null == 'string');
    expect$.Expect.isFalse(core.List.is(null));
    expect$.Expect.isFalse(expect$.Expect.is(null));
    null_is_test.test(null);
    expect$.Expect.isFalse(core.Null.is(1));
    expect$.Expect.isFalse(core.Null.is("1"));
    expect$.Expect.isFalse(core.Null.is(true));
    expect$.Expect.isFalse(core.Null.is(false));
    expect$.Expect.isFalse(core.Null.is(new core.Object()));
    null_is_test.testNegative(1);
    null_is_test.testNegative("1");
    null_is_test.testNegative(true);
    null_is_test.testNegative(false);
    null_is_test.testNegative(new core.Object());
  };
  dart.fn(null_is_test.main, VoidTodynamic());
  null_is_test.test = function(n) {
    expect$.Expect.isTrue(core.Object.is(n));
    expect$.Expect.isTrue(core.Null.is(n));
    expect$.Expect.isFalse(typeof n == 'number');
    expect$.Expect.isFalse(typeof n == 'boolean');
    expect$.Expect.isFalse(typeof n == 'number');
    expect$.Expect.isFalse(typeof n == 'string');
    expect$.Expect.isFalse(core.List.is(n));
    expect$.Expect.isFalse(expect$.Expect.is(n));
  };
  dart.fn(null_is_test.test, dynamicTodynamic());
  null_is_test.testNegative = function(n) {
    expect$.Expect.isFalse(core.Null.is(n));
  };
  dart.fn(null_is_test.testNegative, dynamicTodynamic());
  // Exports:
  exports.null_is_test = null_is_test;
});
