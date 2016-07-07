dart_library.library('lib/convert/codec2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__codec2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const codec2_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  codec2_test.main = function() {
    let RAW = '["122ç",50,50,231]';
    let ENCODED = const$ || (const$ = dart.constList([91, 34, 49, 50, 50, 195, 167, 34, 44, 53, 48, 44, 53, 48, 44, 50, 51, 49, 93], core.int));
    expect$.Expect.listEquals(ENCODED, convert.UTF8.encode(RAW));
    expect$.Expect.equals(RAW, convert.UTF8.decode(ENCODED));
    expect$.Expect.listEquals([], convert.UTF8.encode(""));
    expect$.Expect.equals("", convert.UTF8.decode(JSArrayOfint().of([])));
    let JSON_ENCODED = RAW;
    expect$.Expect.equals(JSON_ENCODED, convert.JSON.encode(JSArrayOfObject().of(["122ç", 50, 50, 231])));
    expect$.Expect.listEquals(JSArrayOfObject().of(["122ç", 50, 50, 231]), core.List._check(convert.JSON.decode(JSON_ENCODED)));
    let decoded = convert.JSON.decode('{"p": 5}', {reviver: dart.fn((k, v) => {
        if (k == null) return v;
        return dart.dsend(v, '*', 2);
      }, dynamicAnddynamicTodynamic())});
    expect$.Expect.equals(10, dart.dindex(decoded, "p"));
    let jsonWithReviver = new convert.JsonCodec.withReviver(dart.fn((k, v) => {
      if (k == null) return v;
      return dart.dsend(v, '*', 2);
    }, dynamicAnddynamicTodynamic()));
    decoded = jsonWithReviver.decode('{"p": 5}');
    expect$.Expect.equals(10, dart.dindex(decoded, "p"));
    let JSON_TO_BYTES = convert.JSON.fuse(convert.UTF8);
    let bytes = ListOfint()._check(JSON_TO_BYTES.encode(JSArrayOfString().of(["json-object"])));
    decoded = JSON_TO_BYTES.decode(bytes);
    expect$.Expect.isTrue(core.List.is(decoded));
    expect$.Expect.equals("json-object", core.List.as(decoded)[dartx.get](0));
  };
  dart.fn(codec2_test.main, VoidTodynamic());
  // Exports:
  exports.codec2_test = codec2_test;
});
