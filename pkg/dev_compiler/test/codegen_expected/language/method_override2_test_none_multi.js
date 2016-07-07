dart_library.library('language/method_override2_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__method_override2_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const method_override2_test_none_multi = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  method_override2_test_none_multi.I = class I extends core.Object {};
  method_override2_test_none_multi.J = class J extends method_override2_test_none_multi.I {};
  method_override2_test_none_multi.K = class K extends method_override2_test_none_multi.J {};
  method_override2_test_none_multi.C = class C extends core.Object {
    m(opts) {
      let a = opts && 'a' in opts ? opts.a : null;
      let b = opts && 'b' in opts ? opts.b : null;
      core.print(dart.str`${a} ${b}`);
    }
  };
  method_override2_test_none_multi.C[dart.implements] = () => [method_override2_test_none_multi.I];
  dart.setSignature(method_override2_test_none_multi.C, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [], {a: dart.dynamic, b: dart.dynamic})})
  });
  method_override2_test_none_multi.D = class D extends core.Object {
    m(opts) {
      let c = opts && 'c' in opts ? opts.c : null;
      let d = opts && 'd' in opts ? opts.d : null;
      core.print(dart.str`${c} ${d}`);
    }
  };
  dart.setSignature(method_override2_test_none_multi.D, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [], {c: dart.dynamic, d: dart.dynamic})})
  });
  method_override2_test_none_multi.main = function() {
    let c = new method_override2_test_none_multi.C();
    c.m({a: "hello", b: "world"});
    let d = new method_override2_test_none_multi.D();
    d.m({c: "hello", d: "world"});
    core.print(dart.str`${method_override2_test_none_multi.I.is(c)} ${method_override2_test_none_multi.I.is(d)} ${method_override2_test_none_multi.I.is(d)} ${method_override2_test_none_multi.J.is(d)}`);
  };
  dart.fn(method_override2_test_none_multi.main, VoidToint());
  // Exports:
  exports.method_override2_test_none_multi = method_override2_test_none_multi;
});
