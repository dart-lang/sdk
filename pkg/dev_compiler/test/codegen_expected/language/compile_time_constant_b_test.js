dart_library.library('language/compile_time_constant_b_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compile_time_constant_b_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compile_time_constant_b_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringAndintTovoid = () => (StringAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, core.int])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  compile_time_constant_b_test.m1 = dart.const(dart.map({__proto__: 400 + 99}, core.String, core.int));
  compile_time_constant_b_test.m2 = dart.const(dart.map({a: 499, b: 42}, core.String, core.int));
  compile_time_constant_b_test.m3 = dart.const(dart.map({__proto__: 499}, core.String, core.int));
  compile_time_constant_b_test.isUnsupportedError = function(o) {
    return core.UnsupportedError.is(o);
  };
  dart.fn(compile_time_constant_b_test.isUnsupportedError, dynamicTobool());
  compile_time_constant_b_test.main = function() {
    expect$.Expect.equals(499, compile_time_constant_b_test.m1[dartx.get]('__proto__'));
    expect$.Expect.equals(null, compile_time_constant_b_test.m1[dartx.get]('b'));
    expect$.Expect.listEquals(JSArrayOfString().of(['__proto__']), compile_time_constant_b_test.m1[dartx.keys][dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([499]), compile_time_constant_b_test.m1[dartx.values][dartx.toList]());
    expect$.Expect.isTrue(compile_time_constant_b_test.m1[dartx.containsKey]('__proto__'));
    expect$.Expect.isFalse(compile_time_constant_b_test.m1[dartx.containsKey]('toString'));
    expect$.Expect.isTrue(compile_time_constant_b_test.m1[dartx.containsValue](499));
    expect$.Expect.isFalse(compile_time_constant_b_test.m1[dartx.containsValue](null));
    let seenKeys = [];
    let seenValues = [];
    compile_time_constant_b_test.m1[dartx.forEach](dart.fn((key, value) => {
      seenKeys[dartx.add](key);
      seenValues[dartx.add](value);
    }, StringAndintTovoid()));
    expect$.Expect.listEquals(JSArrayOfString().of(['__proto__']), seenKeys);
    expect$.Expect.listEquals(JSArrayOfint().of([499]), seenValues);
    expect$.Expect.isFalse(compile_time_constant_b_test.m1[dartx.isEmpty]);
    expect$.Expect.equals(1, compile_time_constant_b_test.m1[dartx.length]);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m1[dartx.remove]('__proto__'), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m1[dartx.remove]('b'), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m1[dartx.clear](), VoidTovoid()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m1[dartx.set]('b', 42), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m1[dartx.set]('__proto__', 499), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m1[dartx.putIfAbsent]('__proto__', dart.fn(() => 499, VoidToint())), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m1[dartx.putIfAbsent]('z', dart.fn(() => 499, VoidToint())), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.equals(499, compile_time_constant_b_test.m2[dartx.get]('a'));
    expect$.Expect.equals(42, compile_time_constant_b_test.m2[dartx.get]('b'));
    expect$.Expect.equals(null, compile_time_constant_b_test.m2[dartx.get]('c'));
    expect$.Expect.equals(null, compile_time_constant_b_test.m2[dartx.get]('__proto__'));
    expect$.Expect.listEquals(JSArrayOfString().of(['a', 'b']), compile_time_constant_b_test.m2[dartx.keys][dartx.toList]());
    expect$.Expect.listEquals(JSArrayOfint().of([499, 42]), compile_time_constant_b_test.m2[dartx.values][dartx.toList]());
    expect$.Expect.isTrue(compile_time_constant_b_test.m2[dartx.containsKey]('a'));
    expect$.Expect.isTrue(compile_time_constant_b_test.m2[dartx.containsKey]('b'));
    expect$.Expect.isFalse(compile_time_constant_b_test.m2[dartx.containsKey]('toString'));
    expect$.Expect.isFalse(compile_time_constant_b_test.m2[dartx.containsKey]('__proto__'));
    expect$.Expect.isTrue(compile_time_constant_b_test.m2[dartx.containsValue](499));
    expect$.Expect.isTrue(compile_time_constant_b_test.m2[dartx.containsValue](42));
    expect$.Expect.isFalse(compile_time_constant_b_test.m2[dartx.containsValue](null));
    seenKeys = [];
    seenValues = [];
    compile_time_constant_b_test.m2[dartx.forEach](dart.fn((key, value) => {
      seenKeys[dartx.add](key);
      seenValues[dartx.add](value);
    }, StringAndintTovoid()));
    expect$.Expect.listEquals(JSArrayOfString().of(['a', 'b']), seenKeys);
    expect$.Expect.listEquals(JSArrayOfint().of([499, 42]), seenValues);
    expect$.Expect.isFalse(compile_time_constant_b_test.m2[dartx.isEmpty]);
    expect$.Expect.equals(2, compile_time_constant_b_test.m2[dartx.length]);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.remove]('a'), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.remove]('b'), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.remove]('__proto__'), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.clear](), VoidTovoid()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.set]('a', 499), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.set]('b', 42), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.set]('__proto__', 499), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.putIfAbsent]('a', dart.fn(() => 499, VoidToint())), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.putIfAbsent]('__proto__', dart.fn(() => 499, VoidToint())), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.throws(dart.fn(() => compile_time_constant_b_test.m2[dartx.set]('a', 499), VoidToint()), compile_time_constant_b_test.isUnsupportedError);
    expect$.Expect.isTrue(core.identical(compile_time_constant_b_test.m1, compile_time_constant_b_test.m3));
  };
  dart.fn(compile_time_constant_b_test.main, VoidTodynamic());
  // Exports:
  exports.compile_time_constant_b_test = compile_time_constant_b_test;
});
