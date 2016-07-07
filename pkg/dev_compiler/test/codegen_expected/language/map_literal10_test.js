dart_library.library('language/map_literal10_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal10_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal10_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let const$;
  let const$0;
  let const$1;
  let const$2;
  map_literal10_test.main = function() {
    let m1 = const$ || (const$ = dart.const(dart.map(["__proto__", 0, 1, 1])));
    expect$.Expect.isTrue(m1[dartx.containsKey]("__proto__"));
    expect$.Expect.equals(0, m1[dartx.get]("__proto__"));
    expect$.Expect.isTrue(m1[dartx.containsKey](1));
    expect$.Expect.equals(1, m1[dartx.get](1));
    expect$.Expect.listEquals(JSArrayOfObject().of(["__proto__", 1]), m1[dartx.keys][dartx.toList]());
    let m2 = const$0 || (const$0 = dart.const(dart.map([1, 0, "__proto__", 1])));
    expect$.Expect.isTrue(m2[dartx.containsKey](1));
    expect$.Expect.equals(0, m2[dartx.get](1));
    expect$.Expect.isTrue(m2[dartx.containsKey]("__proto__"));
    expect$.Expect.equals(1, m2[dartx.get]("__proto__"));
    expect$.Expect.listEquals(JSArrayOfObject().of([1, "__proto__"]), m2[dartx.keys][dartx.toList]());
    let m3 = const$1 || (const$1 = dart.const(dart.map({"1": 0, __proto__: 1})));
    expect$.Expect.isTrue(m3[dartx.containsKey]("1"));
    expect$.Expect.equals(0, m3[dartx.get]("1"));
    expect$.Expect.isTrue(m3[dartx.containsKey]("__proto__"));
    expect$.Expect.equals(1, m3[dartx.get]("__proto__"));
    expect$.Expect.listEquals(JSArrayOfString().of(["1", "__proto__"]), m3[dartx.keys][dartx.toList]());
    let m4 = const$2 || (const$2 = dart.const(dart.map({__proto__: 1, "1": 2})));
    expect$.Expect.isTrue(m4[dartx.containsKey]("1"));
    expect$.Expect.equals(2, m4[dartx.get]("1"));
    expect$.Expect.isTrue(m4[dartx.containsKey]("__proto__"));
    expect$.Expect.equals(1, m4[dartx.get]("__proto__"));
    expect$.Expect.listEquals(JSArrayOfString().of(["__proto__", "1"]), m4[dartx.keys][dartx.toList]());
  };
  dart.fn(map_literal10_test.main, VoidTovoid());
  // Exports:
  exports.map_literal10_test = map_literal10_test;
});
