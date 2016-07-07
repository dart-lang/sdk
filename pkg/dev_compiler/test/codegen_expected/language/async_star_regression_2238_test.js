dart_library.library('language/async_star_regression_2238_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__async_star_regression_2238_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const async_star_regression_2238_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  async_star_regression_2238_test.main = function() {
    function f() {
      return dart.asyncStar(function*(stream) {
        label1:
          label2: {
            if (stream.add(0)) return;
            yield;
          }
      }, dart.dynamic);
    }
    dart.fn(f, VoidTodynamic());
    async_helper$.asyncStart();
    dart.dsend(dart.dsend(f(), 'toList'), 'then', dart.fn(list => {
      expect$.Expect.listEquals(JSArrayOfint().of([0]), core.List._check(list));
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(async_star_regression_2238_test.main, VoidTodynamic());
  // Exports:
  exports.async_star_regression_2238_test = async_star_regression_2238_test;
});
