dart_library.library('language/logical_expression2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__logical_expression2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const logical_expression2_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ObjectTovoid = () => (ObjectTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Object])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  logical_expression2_test.globalCounter = 0;
  logical_expression2_test.nonInlinedUse = function(object) {
    if (new core.DateTime.now().millisecondsSinceEpoch == 42) logical_expression2_test.nonInlinedUse(object);
    if (!(typeof object == 'string')) {
      logical_expression2_test.globalCounter = dart.notNull(logical_expression2_test.globalCounter) + 1;
    }
  };
  dart.fn(logical_expression2_test.nonInlinedUse, ObjectTovoid());
  logical_expression2_test.confuse = function(x) {
    if (new core.DateTime.now().millisecondsSinceEpoch == 42) return logical_expression2_test.confuse(dart.dsend(x, '-', 1));
    return core.int._check(x);
  };
  dart.fn(logical_expression2_test.confuse, dynamicToint());
  logical_expression2_test.main = function() {
    let o = JSArrayOfObject().of(["foo", 499])[dartx.get](logical_expression2_test.confuse(1));
    if (typeof o == 'number' || typeof o == 'string' && true) {
      logical_expression2_test.nonInlinedUse(o);
    }
    expect$.Expect.equals(1, logical_expression2_test.globalCounter);
  };
  dart.fn(logical_expression2_test.main, VoidTodynamic());
  // Exports:
  exports.logical_expression2_test = logical_expression2_test;
});
