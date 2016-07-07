dart_library.library('language/logical_expression4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__logical_expression4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const logical_expression4_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ObjectTobool = () => (ObjectTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.Object])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  logical_expression4_test.nonInlinedNumTypeCheck = function(object) {
    if (new core.DateTime.now().millisecondsSinceEpoch == 42) {
      return logical_expression4_test.nonInlinedNumTypeCheck(object);
    }
    return typeof object == 'number';
  };
  dart.fn(logical_expression4_test.nonInlinedNumTypeCheck, ObjectTobool());
  logical_expression4_test.confuse = function(x) {
    if (new core.DateTime.now().millisecondsSinceEpoch == 42) return logical_expression4_test.confuse(dart.dsend(x, '-', 1));
    return core.int._check(x);
  };
  dart.fn(logical_expression4_test.confuse, dynamicToint());
  logical_expression4_test.main = function() {
    let o = JSArrayOfObject().of(["foo", 499])[dartx.get](logical_expression4_test.confuse(0));
    if (!(typeof o == 'number' && typeof o == 'number')) {
      expect$.Expect.isFalse(logical_expression4_test.nonInlinedNumTypeCheck(o));
    }
  };
  dart.fn(logical_expression4_test.main, VoidTodynamic());
  // Exports:
  exports.logical_expression4_test = logical_expression4_test;
});
