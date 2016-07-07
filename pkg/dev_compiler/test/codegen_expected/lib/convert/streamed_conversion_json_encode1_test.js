dart_library.library('lib/convert/streamed_conversion_json_encode1_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__streamed_conversion_json_encode1_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const convert = dart_sdk.convert;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const streamed_conversion_json_encode1_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfList = () => (JSArrayOfList = dart.constFn(_interceptors.JSArray$(core.List)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfListOfint = () => (JSArrayOfListOfint = dart.constFn(_interceptors.JSArray$(ListOfint())))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let StreamOfString = () => (StreamOfString = dart.constFn(async.Stream$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ObjectToStreamOfString = () => (ObjectToStreamOfString = dart.constFn(dart.definiteFunctionType(StreamOfString(), [core.Object])))();
  let ListTodynamic = () => (ListTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List])))();
  let StringAndObjectTovoid = () => (StringAndObjectTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, core.Object])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  dart.defineLazy(streamed_conversion_json_encode1_test, {
    get TESTS() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([5, '5']), JSArrayOfObject().of([-42, '-42']), JSArrayOfObject().of([3.14, '3.14']), JSArrayOfObject().of([true, 'true']), JSArrayOfObject().of([false, 'false']), JSArrayOfObject().of([null, 'null']), JSArrayOfObject().of(['quote"or\'', '"quote\\"or\'"']), JSArrayOfObject().of(['', '""']), JSArrayOfObject().of([[], "[]"]), JSArrayOfObject().of([JSArrayOfObject().of([3, -4.5, true, "hi", false]), '[3,-4.5,true,"hi",false]']), JSArrayOfObject().of([[null], "[null]"]), JSArrayOfObject().of([JSArrayOfList().of([[null]]), "[[null]]"]), JSArrayOfObject().of([JSArrayOfListOfint().of([JSArrayOfint().of([3])]), "[[3]]"]), JSArrayOfObject().of([dart.map(), "{}"]), JSArrayOfObject().of([dart.map({x: 3, y: 4.5, z: "hi", u: true, v: false}), '{"x":3,"y":4.5,"z":"hi","u":true,"v":false}']), JSArrayOfObject().of([dart.map({x: null}), '{"x":null}']), JSArrayOfObject().of([dart.map({x: dart.map()}), '{"x":{}}']), JSArrayOfObject().of([dart.map({"hi there": 499, "'": -0.0}), '{"hi there":499,"\'":0}']), JSArrayOfObject().of(['\\foo', '"\\\\foo"'])]);
    }
  });
  streamed_conversion_json_encode1_test.encode = function(o) {
    let encoder = new convert.JsonEncoder();
    let controller = null;
    controller = async.StreamController.new({onListen: dart.fn(() => {
        controller.add(o);
        controller.close();
      }, VoidTovoid())});
    return controller.stream.transform(core.String)(encoder);
  };
  dart.fn(streamed_conversion_json_encode1_test.encode, ObjectToStreamOfString());
  streamed_conversion_json_encode1_test.testNoPause = function(expected, o) {
    async_helper$.asyncStart();
    let stream = streamed_conversion_json_encode1_test.encode(o);
    stream.toList().then(dart.dynamic)(dart.fn(list => {
      let buffer = new core.StringBuffer();
      buffer.writeAll(list);
      expect$.Expect.stringEquals(expected, buffer.toString());
      async_helper$.asyncEnd();
    }, ListTodynamic()));
  };
  dart.fn(streamed_conversion_json_encode1_test.testNoPause, StringAndObjectTovoid());
  streamed_conversion_json_encode1_test.testWithPause = function(expected, o) {
    async_helper$.asyncStart();
    let stream = streamed_conversion_json_encode1_test.encode(o);
    let buffer = new core.StringBuffer();
    let sub = null;
    sub = stream.listen(dart.fn(x => {
      buffer.write(x);
      dart.dsend(sub, 'pause', async.Future.delayed(core.Duration.ZERO));
    }, dynamicTovoid()), {onDone: dart.fn(() => {
        expect$.Expect.stringEquals(expected, buffer.toString());
        async_helper$.asyncEnd();
      }, VoidTovoid())});
  };
  dart.fn(streamed_conversion_json_encode1_test.testWithPause, StringAndObjectTovoid());
  streamed_conversion_json_encode1_test.main = function() {
    for (let test of streamed_conversion_json_encode1_test.TESTS) {
      let o = test[dartx.get](0);
      let expected = test[dartx.get](1);
      streamed_conversion_json_encode1_test.testNoPause(core.String._check(expected), o);
      streamed_conversion_json_encode1_test.testWithPause(core.String._check(expected), o);
    }
  };
  dart.fn(streamed_conversion_json_encode1_test.main, VoidTovoid());
  // Exports:
  exports.streamed_conversion_json_encode1_test = streamed_conversion_json_encode1_test;
});
