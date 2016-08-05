dart_library.library('lib/convert/chunked_conversion_json_encode1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__chunked_conversion_json_encode1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const chunked_conversion_json_encode1_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let SinkOfString = () => (SinkOfString = dart.constFn(core.Sink$(core.String)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let ObjectToString = () => (ObjectToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Object])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(chunked_conversion_json_encode1_test, {
    get TESTS() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([5, '5']), JSArrayOfObject().of([-42, '-42']), JSArrayOfObject().of([3.14, '3.14']), JSArrayOfObject().of([true, 'true']), JSArrayOfObject().of([false, 'false']), JSArrayOfObject().of([null, 'null']), JSArrayOfObject().of(['quote"or\'', '"quote\\"or\'"']), JSArrayOfObject().of(['', '""']), JSArrayOfObject().of([[], "[]"]), JSArrayOfObject().of([JSArrayOfObject().of([3, -4.5, true, "hi", false]), '[3,-4.5,true,"hi",false]']), JSArrayOfObject().of([[null], "[null]"]), JSArrayOfObject().of([JSArrayOfList().of([[null]]), "[[null]]"]), JSArrayOfObject().of([JSArrayOfListOfint().of([JSArrayOfint().of([3])]), "[[3]]"]), JSArrayOfObject().of([dart.map(), "{}"]), JSArrayOfObject().of([dart.map({x: 3, y: 4.5, z: "hi", u: true, v: false}, core.String, core.Object), '{"x":3,"y":4.5,"z":"hi","u":true,"v":false}']), JSArrayOfObject().of([dart.map({x: null}, core.String, dart.dynamic), '{"x":null}']), JSArrayOfObject().of([dart.map({x: dart.map()}, core.String, core.Map), '{"x":{}}']), JSArrayOfObject().of([dart.map({"hi there": 499, "'": -0.0}, core.String, core.num), '{"hi there":499,"\'":0}']), JSArrayOfObject().of(['\\foo', '"\\\\foo"'])]);
    }
  });
  chunked_conversion_json_encode1_test.MyStringConversionSink = class MyStringConversionSink extends convert.StringConversionSinkBase {
    new(callback) {
      this.buffer = new core.StringBuffer();
      this.callback = callback;
    }
    addSlice(str, start, end, isLast) {
      this.buffer.write(str[dartx.substring](start, end));
      if (dart.test(isLast)) this.close();
    }
    close() {
      dart.dcall(this.callback, dart.toString(this.buffer));
    }
  };
  dart.setSignature(chunked_conversion_json_encode1_test.MyStringConversionSink, {
    constructors: () => ({new: dart.definiteFunctionType(chunked_conversion_json_encode1_test.MyStringConversionSink, [dart.dynamic])}),
    methods: () => ({
      addSlice: dart.definiteFunctionType(dart.void, [core.String, core.int, core.int, core.bool]),
      close: dart.definiteFunctionType(dart.void, [])
    })
  });
  chunked_conversion_json_encode1_test.encode = function(o) {
    let result = null;
    let encoder = new convert.JsonEncoder();
    let stringSink = new chunked_conversion_json_encode1_test.MyStringConversionSink(dart.fn(x => result = x, dynamicTodynamic()));
    let objectSink = new convert.JsonEncoder().startChunkedConversion(SinkOfString()._check(stringSink));
    objectSink.add(o);
    objectSink.close();
    return core.String._check(result);
  };
  dart.fn(chunked_conversion_json_encode1_test.encode, ObjectToString());
  chunked_conversion_json_encode1_test.encode2 = function(o) {
    let result = null;
    let encoder = new convert.JsonEncoder();
    let stringSink = convert.StringConversionSink.withCallback(dart.fn(x => result = x, StringToString()));
    let objectSink = encoder.startChunkedConversion(SinkOfString()._check(stringSink));
    objectSink.add(o);
    objectSink.close();
    return core.String._check(result);
  };
  dart.fn(chunked_conversion_json_encode1_test.encode2, ObjectToString());
  chunked_conversion_json_encode1_test.main = function() {
    for (let test of chunked_conversion_json_encode1_test.TESTS) {
      let o = test[dartx.get](0);
      let expected = test[dartx.get](1);
      expect$.Expect.equals(expected, chunked_conversion_json_encode1_test.encode(o));
      expect$.Expect.equals(expected, chunked_conversion_json_encode1_test.encode2(o));
    }
  };
  dart.fn(chunked_conversion_json_encode1_test.main, VoidTodynamic());
  // Exports:
  exports.chunked_conversion_json_encode1_test = chunked_conversion_json_encode1_test;
});
