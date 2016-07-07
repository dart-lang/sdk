dart_library.library('language/async_star_regression_fisk_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__async_star_regression_fisk_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const async_star_regression_fisk_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  async_star_regression_fisk_test.main = function() {
    let res = [];
    function fisk() {
      return dart.asyncStar(function*(stream) {
        res[dartx.add]("+fisk");
        try {
          for (let i = 0; i < 2; i++) {
            if (stream.add(yield async.Future.microtask(dart.fn(() => i, VoidToint())))) return;
            yield;
          }
        } finally {
          res[dartx.add]("-fisk");
        }
      }, dart.dynamic);
    }
    dart.fn(fisk, VoidTodynamic());
    function fugl(count) {
      return dart.async(function*(count) {
        res[dartx.add](dart.str`fisk ${count}`);
        try {
          let it = async.StreamIterator.new(async.Stream._check(dart.dsend(fisk(), 'take', count)));
          try {
            while (yield it.moveNext()) {
              let i = it.current;
              core.int._check(i);
              res[dartx.add](i);
            }
          } finally {
            yield it.cancel();
          }
        } finally {
          res[dartx.add]("done");
        }
      }, dart.dynamic, count);
    }
    dart.fn(fugl, intTodynamic());
    async_helper$.asyncStart();
    dart.dsend(dart.dsend(dart.dsend(fugl(3), 'whenComplete', dart.fn(() => fugl(2), VoidTodynamic())), 'whenComplete', dart.fn(() => fugl(1), VoidTodynamic())), 'whenComplete', dart.fn(() => {
      expect$.Expect.listEquals(JSArrayOfObject().of(["fisk 3", "+fisk", 0, 1, "-fisk", "done", "fisk 2", "+fisk", 0, 1, "-fisk", "done", "fisk 1", "+fisk", 0, "-fisk", "done"]), res);
      async_helper$.asyncEnd();
    }, VoidTodynamic()));
  };
  dart.fn(async_star_regression_fisk_test.main, VoidTodynamic());
  // Exports:
  exports.async_star_regression_fisk_test = async_star_regression_fisk_test;
});
