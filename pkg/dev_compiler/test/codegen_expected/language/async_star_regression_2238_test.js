dart_library.library('language/async_star_regression_2238_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__async_star_regression_2238_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const async_star_regression_2238_test = Object.create(null);
  let StreamOfint = () => (StreamOfint = dart.constFn(async.Stream$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidToStreamOfint = () => (VoidToStreamOfint = dart.constFn(dart.definiteFunctionType(StreamOfint(), [])))();
  let ListOfintTodynamic = () => (ListOfintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfint()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_star_regression_2238_test.main = function() {
    function f() {
      return dart.asyncStar(function*(stream) {
        label1:
          label2: {
            if (stream.add(0)) return;
            yield;
          }
      }, core.int);
    }
    dart.fn(f, VoidToStreamOfint());
    async_helper$.asyncStart();
    f().toList().then(dart.dynamic)(dart.fn(list => {
      expect$.Expect.listEquals(JSArrayOfint().of([0]), list);
      async_helper$.asyncEnd();
    }, ListOfintTodynamic()));
  };
  dart.fn(async_star_regression_2238_test.main, VoidTodynamic());
  // Exports:
  exports.async_star_regression_2238_test = async_star_regression_2238_test;
});
