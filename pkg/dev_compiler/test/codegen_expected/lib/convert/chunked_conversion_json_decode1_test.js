dart_library.library('lib/convert/chunked_conversion_json_decode1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__chunked_conversion_json_decode1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const chunked_conversion_json_decode1_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let StringToObject = () => (StringToObject = dart.constFn(dart.definiteFunctionType(core.Object, [core.String])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let ListOfObjectToIterable = () => (ListOfObjectToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [ListOfObject()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(chunked_conversion_json_decode1_test, {
    get TESTS() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([5, '5']), JSArrayOfObject().of([-42, '-42']), JSArrayOfObject().of([3.14, '3.14']), JSArrayOfObject().of([true, 'true']), JSArrayOfObject().of([false, 'false']), JSArrayOfObject().of([null, 'null']), JSArrayOfObject().of(['quote"or\'', '"quote\\"or\'"']), JSArrayOfObject().of(['', '""']), JSArrayOfObject().of([[], "[]"]), JSArrayOfObject().of([JSArrayOfObject().of([3, -4.5, true, "hi", false]), '[3,-4.5,true,"hi",false]']), JSArrayOfObject().of([[null], "[null]"]), JSArrayOfObject().of([JSArrayOfList().of([[null]]), "[[null]]"]), JSArrayOfObject().of([JSArrayOfListOfint().of([JSArrayOfint().of([3])]), "[[3]]"]), JSArrayOfObject().of([dart.map(), "{}"]), JSArrayOfObject().of([dart.map({x: 3, y: 4.5, z: "hi", u: true, v: false}, core.String, core.Object), '{"x":3,"y":4.5,"z":"hi","u":true,"v":false}']), JSArrayOfObject().of([dart.map({x: null}, core.String, dart.dynamic), '{"x":null}']), JSArrayOfObject().of([dart.map({x: dart.map()}, core.String, core.Map), '{"x":{}}']), JSArrayOfObject().of([dart.map({"hi there": 499, "'": -0.0}, core.String, core.num), '{"hi there":499,"\'":-0.0}']), JSArrayOfObject().of(['\\foo', '"\\\\foo"'])]);
    }
  });
  chunked_conversion_json_decode1_test.isJsonEqual = function(o1, o2) {
    if (dart.equals(o1, o2)) return true;
    if (core.List.is(o1) && core.List.is(o2)) {
      if (o1[dartx.length] != o2[dartx.length]) return false;
      for (let i = 0; i < dart.notNull(o1[dartx.length]); i++) {
        if (!dart.test(chunked_conversion_json_decode1_test.isJsonEqual(o1[dartx.get](i), o2[dartx.get](i)))) return false;
      }
      return true;
    }
    if (core.Map.is(o1) && core.Map.is(o2)) {
      if (o1[dartx.length] != o2[dartx.length]) return false;
      for (let key of o1[dartx.keys]) {
        expect$.Expect.isTrue(typeof key == 'string');
        if (!dart.test(o2[dartx.containsKey](key))) return false;
        if (!dart.test(chunked_conversion_json_decode1_test.isJsonEqual(o1[dartx.get](key), o2[dartx.get](key)))) return false;
      }
      return true;
    }
    return false;
  };
  dart.fn(chunked_conversion_json_decode1_test.isJsonEqual, dynamicAnddynamicTobool());
  chunked_conversion_json_decode1_test.decode = function(str) {
    let result = null;
    let decoder = new convert.JsonDecoder(null);
    let objectSink = convert.ChunkedConversionSink.withCallback(dart.fn(x => result = x[dartx.single], ListTovoid()));
    let stringConversionSink = decoder.startChunkedConversion(objectSink);
    stringConversionSink.add(str);
    stringConversionSink.close();
    return result;
  };
  dart.fn(chunked_conversion_json_decode1_test.decode, StringToObject());
  chunked_conversion_json_decode1_test.decode2 = function(str) {
    let result = null;
    let decoder = new convert.JsonDecoder(null);
    let objectSink = convert.ChunkedConversionSink.withCallback(dart.fn(x => result = x[dartx.single], ListTovoid()));
    let stringConversionSink = decoder.startChunkedConversion(objectSink);
    let stringSink = stringConversionSink.asStringSink();
    stringSink.write(str);
    stringSink.close();
    return result;
  };
  dart.fn(chunked_conversion_json_decode1_test.decode2, StringToObject());
  chunked_conversion_json_decode1_test.decode3 = function(str) {
    let result = null;
    let decoder = new convert.JsonDecoder(null);
    let objectSink = convert.ChunkedConversionSink.withCallback(dart.fn(x => result = x[dartx.single], ListTovoid()));
    let stringConversionSink = decoder.startChunkedConversion(objectSink);
    let stringSink = stringConversionSink.asStringSink();
    str[dartx.codeUnits][dartx.forEach](dart.bind(stringSink, 'writeCharCode'));
    stringSink.close();
    return result;
  };
  dart.fn(chunked_conversion_json_decode1_test.decode3, StringToObject());
  chunked_conversion_json_decode1_test.decode4 = function(str) {
    let result = null;
    let decoder = new convert.JsonDecoder(null);
    let objectSink = convert.ChunkedConversionSink.withCallback(dart.fn(x => result = x[dartx.single], ListTovoid()));
    let stringConversionSink = decoder.startChunkedConversion(objectSink);
    let stringSink = stringConversionSink.asStringSink();
    str[dartx.runes].forEach(dart.bind(stringSink, 'writeCharCode'));
    stringSink.close();
    return result;
  };
  dart.fn(chunked_conversion_json_decode1_test.decode4, StringToObject());
  chunked_conversion_json_decode1_test.decode5 = function(str) {
    let result = null;
    let decoder = new convert.JsonDecoder(null);
    let objectSink = convert.ChunkedConversionSink.withCallback(dart.fn(x => result = x[dartx.single], ListTovoid()));
    let stringConversionSink = decoder.startChunkedConversion(objectSink);
    let inputByteSink = stringConversionSink.asUtf8Sink(false);
    let tmpBytes = convert.UTF8.encode(str);
    inputByteSink.add(ListOfint()._check(tmpBytes));
    inputByteSink.close();
    return result;
  };
  dart.fn(chunked_conversion_json_decode1_test.decode5, StringToObject());
  chunked_conversion_json_decode1_test.decode6 = function(str) {
    let result = null;
    let decoder = new convert.JsonDecoder(null);
    let objectSink = convert.ChunkedConversionSink.withCallback(dart.fn(x => result = x[dartx.single], ListTovoid()));
    let stringConversionSink = decoder.startChunkedConversion(objectSink);
    let inputByteSink = stringConversionSink.asUtf8Sink(false);
    let tmpBytes = convert.UTF8.encode(str);
    tmpBytes[dartx.forEach](dart.fn(b => inputByteSink.addSlice(JSArrayOfint().of([0, b, 1]), 1, 2, false), intTovoid()));
    inputByteSink.close();
    return result;
  };
  dart.fn(chunked_conversion_json_decode1_test.decode6, StringToObject());
  chunked_conversion_json_decode1_test.decode7 = function(str) {
    let result = null;
    let decoder = new convert.JsonDecoder(null);
    let objectSink = convert.ChunkedConversionSink.withCallback(dart.fn(x => result = x[dartx.single], ListTovoid()));
    let stringConversionSink = decoder.startChunkedConversion(objectSink);
    stringConversionSink.addSlice("1" + dart.notNull(str) + "2", 1, dart.notNull(str[dartx.length]) + 1, false);
    stringConversionSink.close();
    return result;
  };
  dart.fn(chunked_conversion_json_decode1_test.decode7, StringToObject());
  chunked_conversion_json_decode1_test.main = function() {
    let tests = chunked_conversion_json_decode1_test.TESTS[dartx.expand](dart.dynamic)(dart.fn(test => {
      let object = test[dartx.get](0);
      let string = test[dartx.get](1);
      let longString = "                                                        " + "                                                        " + dart.str`${string}` + "                                                        " + "                                                        ";
      return JSArrayOfListOfObject().of([test, JSArrayOfObject().of([object, longString])]);
    }, ListOfObjectToIterable()));
    for (let test of chunked_conversion_json_decode1_test.TESTS) {
      let o = test[dartx.get](0);
      let string = test[dartx.get](1);
      expect$.Expect.isTrue(chunked_conversion_json_decode1_test.isJsonEqual(o, chunked_conversion_json_decode1_test.decode(core.String._check(string))));
      expect$.Expect.isTrue(chunked_conversion_json_decode1_test.isJsonEqual(o, chunked_conversion_json_decode1_test.decode2(core.String._check(string))));
      expect$.Expect.isTrue(chunked_conversion_json_decode1_test.isJsonEqual(o, chunked_conversion_json_decode1_test.decode3(core.String._check(string))));
      expect$.Expect.isTrue(chunked_conversion_json_decode1_test.isJsonEqual(o, chunked_conversion_json_decode1_test.decode4(core.String._check(string))));
      expect$.Expect.isTrue(chunked_conversion_json_decode1_test.isJsonEqual(o, chunked_conversion_json_decode1_test.decode5(core.String._check(string))));
      expect$.Expect.isTrue(chunked_conversion_json_decode1_test.isJsonEqual(o, chunked_conversion_json_decode1_test.decode6(core.String._check(string))));
      expect$.Expect.isTrue(chunked_conversion_json_decode1_test.isJsonEqual(o, chunked_conversion_json_decode1_test.decode7(core.String._check(string))));
    }
  };
  dart.fn(chunked_conversion_json_decode1_test.main, VoidTodynamic());
  // Exports:
  exports.chunked_conversion_json_decode1_test = chunked_conversion_json_decode1_test;
});
