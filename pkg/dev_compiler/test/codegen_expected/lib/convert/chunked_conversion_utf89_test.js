dart_library.library('lib/convert/chunked_conversion_utf89_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__chunked_conversion_utf89_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const chunked_conversion_utf89_test = Object.create(null);
  let SinkOfString = () => (SinkOfString = dart.constFn(core.Sink$(core.String)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _add = Symbol('_add');
  const _close = Symbol('_close');
  chunked_conversion_utf89_test.MySink = class MySink extends convert.ChunkedConversionSink$(core.String) {
    new(add, close) {
      this[_add] = add;
      this[_close] = close;
      super.new();
    }
    add(x) {
      dart.dcall(this[_add], x);
    }
    close() {
      dart.dcall(this[_close]);
    }
  };
  dart.addSimpleTypeTests(chunked_conversion_utf89_test.MySink);
  dart.setSignature(chunked_conversion_utf89_test.MySink, {
    constructors: () => ({new: dart.definiteFunctionType(chunked_conversion_utf89_test.MySink, [core.Function, core.Function])}),
    methods: () => ({
      add: dart.definiteFunctionType(dart.void, [core.String]),
      close: dart.definiteFunctionType(dart.void, [])
    })
  });
  chunked_conversion_utf89_test.main = function() {
    let lastString = null;
    let isClosed = false;
    let sink = new chunked_conversion_utf89_test.MySink(dart.fn(x => lastString = core.String._check(x), dynamicTodynamic()), dart.fn(() => isClosed = true, VoidTobool()));
    let byteSink = new convert.Utf8Decoder().startChunkedConversion(SinkOfString()._check(sink));
    byteSink.add("abc"[dartx.codeUnits]);
    expect$.Expect.equals("abc", lastString);
    byteSink.add(JSArrayOfint().of([97, 195]));
    expect$.Expect.equals("a", lastString);
    byteSink.add(JSArrayOfint().of([142]));
    expect$.Expect.equals("Î", lastString);
    expect$.Expect.isFalse(isClosed);
    byteSink.close();
    expect$.Expect.isTrue(isClosed);
  };
  dart.fn(chunked_conversion_utf89_test.main, VoidTodynamic());
  // Exports:
  exports.chunked_conversion_utf89_test = chunked_conversion_utf89_test;
});
