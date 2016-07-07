dart_library.library('lib/convert/close_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__close_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const close_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let SinkOfListOfint = () => (SinkOfListOfint = dart.constFn(core.Sink$(ListOfint())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  close_test.MySink = class MySink extends core.Object {
    new() {
      this.accumulated = JSArrayOfint().of([]);
      this.isClosed = false;
    }
    add(list) {
      this.accumulated[dartx.addAll](list);
      list[dartx.length];
    }
    close() {
      this.isClosed = true;
    }
  };
  close_test.MySink[dart.implements] = () => [SinkOfListOfint()];
  dart.setSignature(close_test.MySink, {
    methods: () => ({
      add: dart.definiteFunctionType(dart.void, [core.List$(core.int)]),
      close: dart.definiteFunctionType(dart.void, [])
    })
  });
  close_test.main = function() {
    let mySink = new close_test.MySink();
    let byteSink = convert.ByteConversionSink.from(mySink);
    byteSink.add(JSArrayOfint().of([1, 2, 3]));
    byteSink.close();
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 3]), mySink.accumulated);
    expect$.Expect.isTrue(mySink.isClosed);
  };
  dart.fn(close_test.main, VoidTodynamic());
  // Exports:
  exports.close_test = close_test;
});
