dart_library.library('lib/convert/json_toEncodable_reviver_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__json_toEncodable_reviver_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const json_toEncodable_reviver_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ATodynamic = () => (ATodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [json_toEncodable_reviver_test.A])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  json_toEncodable_reviver_test.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(json_toEncodable_reviver_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(json_toEncodable_reviver_test.A, [dart.dynamic])})
  });
  json_toEncodable_reviver_test.toEncodable = function(a) {
    return dart.map({A: a.x}, core.String, dart.dynamic);
  };
  dart.fn(json_toEncodable_reviver_test.toEncodable, ATodynamic());
  json_toEncodable_reviver_test.reviver = function(key, value) {
    if (core.Map.is(value) && value[dartx.length] == 1 && value[dartx.get]("A") != null) {
      return new json_toEncodable_reviver_test.A(value[dartx.get]("A"));
    }
    return value;
  };
  dart.fn(json_toEncodable_reviver_test.reviver, dynamicAnddynamicTodynamic());
  json_toEncodable_reviver_test.extendedJson = dart.const(new convert.JsonCodec({toEncodable: json_toEncodable_reviver_test.toEncodable, reviver: json_toEncodable_reviver_test.reviver}));
  json_toEncodable_reviver_test.main = function() {
    let encoded = json_toEncodable_reviver_test.extendedJson.encode(JSArrayOfObject().of([new json_toEncodable_reviver_test.A(0), dart.map({"2": new json_toEncodable_reviver_test.A(1)}, core.String, json_toEncodable_reviver_test.A)]));
    expect$.Expect.equals('[{"A":0},{"2":{"A":1}}]', encoded);
    let decoded = json_toEncodable_reviver_test.extendedJson.decode(encoded);
    expect$.Expect.isTrue(core.List.is(decoded));
    expect$.Expect.equals(2, dart.dload(decoded, 'length'));
    expect$.Expect.isTrue(json_toEncodable_reviver_test.A.is(dart.dindex(decoded, 0)));
    expect$.Expect.equals(0, dart.dload(dart.dindex(decoded, 0), 'x'));
    expect$.Expect.isTrue(core.Map.is(dart.dindex(decoded, 1)));
    expect$.Expect.isNotNull(dart.dindex(dart.dindex(decoded, 1), "2"));
    expect$.Expect.isTrue(json_toEncodable_reviver_test.A.is(dart.dindex(dart.dindex(decoded, 1), "2")));
    expect$.Expect.equals(1, dart.dload(dart.dindex(dart.dindex(decoded, 1), "2"), 'x'));
    let a = json_toEncodable_reviver_test.extendedJson.decode(json_toEncodable_reviver_test.extendedJson.encode(new json_toEncodable_reviver_test.A(499)));
    expect$.Expect.isTrue(json_toEncodable_reviver_test.A.is(a));
    expect$.Expect.equals(499, dart.dload(a, 'x'));
    json_toEncodable_reviver_test.testInvalidMap();
  };
  dart.fn(json_toEncodable_reviver_test.main, VoidTodynamic());
  json_toEncodable_reviver_test.testInvalidMap = function() {
    let map = dart.map(["a", 42, "b", 42, 37, 42], core.Object, core.int);
    let enc = new convert.JsonEncoder(dart.fn(_ => "fixed", dynamicToString()));
    let res = enc.convert(map);
    expect$.Expect.equals('"fixed"', res);
    enc = new convert.JsonEncoder.withIndent(" ", dart.fn(_ => "fixed", dynamicToString()));
    res = enc.convert(map);
    expect$.Expect.equals('"fixed"', res);
  };
  dart.fn(json_toEncodable_reviver_test.testInvalidMap, VoidTovoid());
  // Exports:
  exports.json_toEncodable_reviver_test = json_toEncodable_reviver_test;
});
