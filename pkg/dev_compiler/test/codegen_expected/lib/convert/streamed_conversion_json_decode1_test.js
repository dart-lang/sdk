dart_library.library('lib/convert/streamed_conversion_json_decode1_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__streamed_conversion_json_decode1_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const streamed_conversion_json_decode1_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.functionType(dart.void, [core.String])))();
  let StreamOfObject = () => (StreamOfObject = dart.constFn(async.Stream$(core.Object)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ListOfStringToStreamOfObject = () => (ListOfStringToStreamOfObject = dart.constFn(dart.definiteFunctionType(StreamOfObject(), [ListOfString()])))();
  let StringToStreamOfObject = () => (StringToStreamOfObject = dart.constFn(dart.definiteFunctionType(StreamOfObject(), [core.String])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTovoid = () => (dynamicAnddynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic])))();
  let ListOfObjectToIterable = () => (ListOfObjectToIterable = dart.constFn(dart.definiteFunctionType(core.Iterable, [ListOfObject()])))();
  dart.defineLazy(streamed_conversion_json_decode1_test, {
    get TESTS() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([5, '5']), JSArrayOfObject().of([-42, '-42']), JSArrayOfObject().of([3.14, '3.14']), JSArrayOfObject().of([true, 'true']), JSArrayOfObject().of([false, 'false']), JSArrayOfObject().of([null, 'null']), JSArrayOfObject().of(['quote"or\'', '"quote\\"or\'"']), JSArrayOfObject().of(['', '""']), JSArrayOfObject().of([[], "[]"]), JSArrayOfObject().of([JSArrayOfObject().of([3, -4.5, true, "hi", false]), '[3,-4.5,true,"hi",false]']), JSArrayOfObject().of([[null], "[null]"]), JSArrayOfObject().of([JSArrayOfList().of([[null]]), "[[null]]"]), JSArrayOfObject().of([JSArrayOfListOfint().of([JSArrayOfint().of([3])]), "[[3]]"]), JSArrayOfObject().of([dart.map(), "{}"]), JSArrayOfObject().of([dart.map({x: 3, y: 4.5, z: "hi", u: true, v: false}, core.String, core.Object), '{"x":3,"y":4.5,"z":"hi","u":true,"v":false}']), JSArrayOfObject().of([dart.map({x: null}, core.String, dart.dynamic), '{"x":null}']), JSArrayOfObject().of([dart.map({x: dart.map()}, core.String, core.Map), '{"x":{}}']), JSArrayOfObject().of([dart.map({"hi there": 499, "'": -0.0}, core.String, core.num), '{"hi there":499,"\'":-0.0}']), JSArrayOfObject().of(['\\foo', '"\\\\foo"'])]);
    }
  });
  streamed_conversion_json_decode1_test.isJsonEqual = function(o1, o2) {
    if (dart.equals(o1, o2)) return true;
    if (core.List.is(o1) && core.List.is(o2)) {
      if (o1[dartx.length] != o2[dartx.length]) return false;
      for (let i = 0; i < dart.notNull(o1[dartx.length]); i++) {
        if (!dart.test(streamed_conversion_json_decode1_test.isJsonEqual(o1[dartx.get](i), o2[dartx.get](i)))) return false;
      }
      return true;
    }
    if (core.Map.is(o1) && core.Map.is(o2)) {
      if (o1[dartx.length] != o2[dartx.length]) return false;
      for (let key of o1[dartx.keys]) {
        expect$.Expect.isTrue(typeof key == 'string');
        if (!dart.test(o2[dartx.containsKey](key))) return false;
        if (!dart.test(streamed_conversion_json_decode1_test.isJsonEqual(o1[dartx.get](key), o2[dartx.get](key)))) return false;
      }
      return true;
    }
    return false;
  };
  dart.fn(streamed_conversion_json_decode1_test.isJsonEqual, dynamicAnddynamicTobool());
  streamed_conversion_json_decode1_test.createStream = function(chunks) {
    let decoder = new convert.JsonDecoder(null);
    let controller = null;
    controller = async.StreamController.new({onListen: dart.fn(() => {
        chunks[dartx.forEach](StringTovoid()._check(dart.dload(controller, 'add')));
        dart.dsend(controller, 'close');
      }, VoidTovoid())});
    return StreamOfObject()._check(dart.dsend(dart.dload(controller, 'stream'), 'transform', decoder));
  };
  dart.fn(streamed_conversion_json_decode1_test.createStream, ListOfStringToStreamOfObject());
  streamed_conversion_json_decode1_test.decode = function(str) {
    return streamed_conversion_json_decode1_test.createStream(JSArrayOfString().of([str]));
  };
  dart.fn(streamed_conversion_json_decode1_test.decode, StringToStreamOfObject());
  streamed_conversion_json_decode1_test.decode2 = function(str) {
    return streamed_conversion_json_decode1_test.createStream(str[dartx.split](""));
  };
  dart.fn(streamed_conversion_json_decode1_test.decode2, StringToStreamOfObject());
  streamed_conversion_json_decode1_test.checkIsJsonEqual = function(expected, stream) {
    async_helper$.asyncStart();
    dart.dsend(dart.dload(stream, 'single'), 'then', dart.fn(o => {
      expect$.Expect.isTrue(streamed_conversion_json_decode1_test.isJsonEqual(expected, o));
      async_helper$.asyncEnd();
    }, dynamicTodynamic()));
  };
  dart.fn(streamed_conversion_json_decode1_test.checkIsJsonEqual, dynamicAnddynamicTovoid());
  streamed_conversion_json_decode1_test.main = function() {
    let tests = streamed_conversion_json_decode1_test.TESTS[dartx.expand](dart.dynamic)(dart.fn(test => {
      let object = test[dartx.get](0);
      let string = test[dartx.get](1);
      let longString = "                                                        " + "                                                        " + dart.str`${string}` + "                                                        " + "                                                        ";
      return JSArrayOfListOfObject().of([test, JSArrayOfObject().of([object, longString])]);
    }, ListOfObjectToIterable()));
    for (let test of streamed_conversion_json_decode1_test.TESTS) {
      let o = test[dartx.get](0);
      let string = test[dartx.get](1);
      streamed_conversion_json_decode1_test.checkIsJsonEqual(o, streamed_conversion_json_decode1_test.decode(core.String._check(string)));
      streamed_conversion_json_decode1_test.checkIsJsonEqual(o, streamed_conversion_json_decode1_test.decode2(core.String._check(string)));
    }
  };
  dart.fn(streamed_conversion_json_decode1_test.main, VoidTovoid());
  // Exports:
  exports.streamed_conversion_json_decode1_test = streamed_conversion_json_decode1_test;
});
