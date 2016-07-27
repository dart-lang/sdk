dart_library.library('language/sync_generator2_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__sync_generator2_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const sync_generator2_test_none_multi = Object.create(null);
  let StreamOfint = () => (StreamOfint = dart.constFn(async.Stream$(core.int)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  sync_generator2_test_none_multi.sync = "topLevelSync";
  sync_generator2_test_none_multi.async = "topLevelAync";
  sync_generator2_test_none_multi.await = "topLevelAwait";
  sync_generator2_test_none_multi.yield = "topLevelYield";
  sync_generator2_test_none_multi.test01 = function() {
    return dart.syncStar(function*() {
      let x1 = sync_generator2_test_none_multi.sync;
      let stream = StreamOfint().fromIterable(JSArrayOfint().of([1, 2, 3]));
    }, dart.dynamic);
  };
  dart.fn(sync_generator2_test_none_multi.test01, VoidTodynamic());
  sync_generator2_test_none_multi.test02 = function() {
    return dart.syncStar(function*() {
      yield 12321;
    }, dart.dynamic);
  };
  dart.fn(sync_generator2_test_none_multi.test02, VoidTodynamic());
  sync_generator2_test_none_multi.K = class K extends core.Object {
    get nix() {
      return dart.syncStar(function*() {
      }, dart.dynamic);
    }
    sync() {
      return dart.syncStar((function*() {
        yield dart.bind(this, 'sync');
      }).bind(this), dart.dynamic);
    }
  };
  dart.setSignature(sync_generator2_test_none_multi.K, {
    methods: () => ({sync: dart.definiteFunctionType(dart.dynamic, [])})
  });
  sync_generator2_test_none_multi.main = function() {
    let x = null;
    x = sync_generator2_test_none_multi.test01();
    expect$.Expect.equals("()", dart.toString(x));
    x = sync_generator2_test_none_multi.test02();
    expect$.Expect.equals("(12321)", dart.toString(x));
    x = new sync_generator2_test_none_multi.K();
    core.print(dart.dsend(dart.dsend(x, 'sync'), 'toList'));
    expect$.Expect.equals(1, dart.dload(dart.dsend(x, 'sync'), 'length'));
  };
  dart.fn(sync_generator2_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.sync_generator2_test_none_multi = sync_generator2_test_none_multi;
});
