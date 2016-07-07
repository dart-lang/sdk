dart_library.library('lib/convert/chunked_conversion2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__chunked_conversion2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const chunked_conversion2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  chunked_conversion2_test.MyByteSink = class MyByteSink extends convert.ByteConversionSinkBase {
    new() {
      this.accumulator = [];
    }
    add(bytes) {
      this.accumulator[dartx.add](bytes);
    }
    close() {}
  };
  dart.setSignature(chunked_conversion2_test.MyByteSink, {
    methods: () => ({
      add: dart.definiteFunctionType(dart.void, [core.List$(core.int)]),
      close: dart.definiteFunctionType(dart.void, [])
    })
  });
  chunked_conversion2_test.testBase = function() {
    let byteSink = new chunked_conversion2_test.MyByteSink();
    let bytes = JSArrayOfint().of([1]);
    byteSink.addSlice(bytes, 0, 1, false);
    bytes[dartx.set](0, 2);
    byteSink.addSlice(bytes, 0, 1, true);
    expect$.Expect.equals(1, dart.dindex(byteSink.accumulator[dartx.get](0), 0));
    expect$.Expect.equals(2, dart.dindex(byteSink.accumulator[dartx.get](1), 0));
  };
  dart.fn(chunked_conversion2_test.testBase, VoidTovoid());
  chunked_conversion2_test.MyChunkedSink = class MyChunkedSink extends convert.ChunkedConversionSink$(core.List$(core.int)) {
    new() {
      this.accumulator = [];
      super.new();
    }
    add(bytes) {
      this.accumulator[dartx.add](bytes);
    }
    close() {}
  };
  dart.addSimpleTypeTests(chunked_conversion2_test.MyChunkedSink);
  dart.setSignature(chunked_conversion2_test.MyChunkedSink, {
    methods: () => ({
      add: dart.definiteFunctionType(dart.void, [core.List$(core.int)]),
      close: dart.definiteFunctionType(dart.void, [])
    })
  });
  chunked_conversion2_test.testAdapter = function() {
    let chunkedSink = new chunked_conversion2_test.MyChunkedSink();
    let byteSink = convert.ByteConversionSink.from(chunkedSink);
    let bytes = JSArrayOfint().of([1]);
    byteSink.addSlice(bytes, 0, 1, false);
    bytes[dartx.set](0, 2);
    byteSink.addSlice(bytes, 0, 1, true);
    expect$.Expect.equals(1, dart.dindex(chunkedSink.accumulator[dartx.get](0), 0));
    expect$.Expect.equals(2, dart.dindex(chunkedSink.accumulator[dartx.get](1), 0));
  };
  dart.fn(chunked_conversion2_test.testAdapter, VoidTovoid());
  chunked_conversion2_test.main = function() {
    chunked_conversion2_test.testBase();
    chunked_conversion2_test.testAdapter();
  };
  dart.fn(chunked_conversion2_test.main, VoidTovoid());
  // Exports:
  exports.chunked_conversion2_test = chunked_conversion2_test;
});
