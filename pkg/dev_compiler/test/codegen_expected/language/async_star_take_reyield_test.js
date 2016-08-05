dart_library.library('language/async_star_take_reyield_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__async_star_take_reyield_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const async_star_take_reyield_test = Object.create(null);
  let StreamOfnum = () => (StreamOfnum = dart.constFn(async.Stream$(core.num)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let intToStream = () => (intToStream = dart.constFn(dart.definiteFunctionType(async.Stream, [core.int])))();
  let StreamToStreamOfnum = () => (StreamToStreamOfnum = dart.constFn(dart.definiteFunctionType(StreamOfnum(), [async.Stream])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_star_take_reyield_test.expectList = function(stream, list) {
    return dart.dsend(dart.dsend(stream, 'toList'), 'then', dart.fn(v => {
      expect$.Expect.listEquals(core.List._check(v), core.List._check(list));
    }, dynamicTodynamic()));
  };
  dart.fn(async_star_take_reyield_test.expectList, dynamicAnddynamicTodynamic());
  async_star_take_reyield_test.makeStream = function(n) {
    return dart.asyncStar(function*(stream, n) {
      for (let i = 0; i < dart.notNull(n); i++) {
        if (stream.add(i)) return;
        yield;
      }
    }, dart.dynamic, n);
  };
  dart.fn(async_star_take_reyield_test.makeStream, intToStream());
  async_star_take_reyield_test.main = function() {
    function fivePartialSums(s) {
      return dart.asyncStar(function*(stream, s) {
        let r = 0;
        let it = async.StreamIterator.new(s.take(5));
        try {
          while (yield it.moveNext()) {
            let v = it.current;
            if (stream.add((r = dart.notNull(r) + dart.notNull(core.int._check(v))))) return;
            yield;
          }
        } finally {
          yield it.cancel();
        }
      }, core.num, s);
    }
    dart.fn(fivePartialSums, StreamToStreamOfnum());
    async_helper$.asyncStart();
    dart.dsend(async_star_take_reyield_test.expectList(fivePartialSums(async_star_take_reyield_test.makeStream(10)), JSArrayOfint().of([0, 1, 3, 6, 10])), 'then', async_helper$.asyncSuccess);
  };
  dart.fn(async_star_take_reyield_test.main, VoidTodynamic());
  // Exports:
  exports.async_star_take_reyield_test = async_star_take_reyield_test;
});
