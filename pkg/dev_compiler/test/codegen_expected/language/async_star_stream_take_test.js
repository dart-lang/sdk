dart_library.library('language/async_star_stream_take_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__async_star_stream_take_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const async_star_stream_take_test = Object.create(null);
  let FutureOfint = () => (FutureOfint = dart.constFn(async.Future$(core.int)))();
  let intToStream = () => (intToStream = dart.constFn(dart.definiteFunctionType(async.Stream, [core.int])))();
  let StreamToFutureOfint = () => (StreamToFutureOfint = dart.constFn(dart.definiteFunctionType(FutureOfint(), [async.Stream])))();
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_star_stream_take_test.makeStream = function(n) {
    return dart.asyncStar(function*(stream, n) {
      for (let i = 0; i < dart.notNull(n); i++) {
        if (stream.add(i)) return;
        yield;
      }
    }, dart.dynamic, n);
  };
  dart.fn(async_star_stream_take_test.makeStream, intToStream());
  async_star_stream_take_test.main = function() {
    function f(s) {
      return dart.async(function*(s) {
        let r = 0;
        let it = async.StreamIterator.new(s.take(5));
        try {
          while (yield it.moveNext()) {
            let v = it.current;
            r = dart.notNull(r) + dart.notNull(core.int._check(v));
          }
        } finally {
          yield it.cancel();
        }
        return r;
      }, core.int, s);
    }
    dart.fn(f, StreamToFutureOfint());
    async_helper$.asyncStart();
    f(async_star_stream_take_test.makeStream(10)).then(dart.dynamic)(dart.fn(v => {
      expect$.Expect.equals(10, v);
      async_helper$.asyncEnd();
    }, intTodynamic()));
  };
  dart.fn(async_star_stream_take_test.main, VoidTodynamic());
  // Exports:
  exports.async_star_stream_take_test = async_star_stream_take_test;
});
