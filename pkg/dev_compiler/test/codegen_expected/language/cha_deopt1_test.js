dart_library.library('language/cha_deopt1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cha_deopt1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cha_deopt1_test = Object.create(null);
  const cha_deopt1_lib = Object.create(null);
  const cha_deopt1_deferred_lib = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cha_deopt1_test.loaded = false;
  cha_deopt1_test.main = function() {
    for (let i = 0; i < 2000; i++)
      cha_deopt1_test.bla();
    expect$.Expect.equals(42, cha_deopt1_test.bla());
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      cha_deopt1_test.loaded = true;
      expect$.Expect.equals("good horse", cha_deopt1_test.bla());
    }, dynamicTodynamic()));
  };
  dart.fn(cha_deopt1_test.main, VoidTodynamic());
  cha_deopt1_test.make_t = function() {
    try {
      if (dart.test(cha_deopt1_test.loaded)) {
        return cha_deopt1_deferred_lib.make_u();
      } else {
        return new cha_deopt1_lib.T();
      }
    } catch (e) {
    }

  };
  dart.fn(cha_deopt1_test.make_t, VoidTodynamic());
  cha_deopt1_test.bla = function() {
    let x = new cha_deopt1_test.X();
    x.test(cha_deopt1_lib.T._check(cha_deopt1_test.make_t()));
    return x.fld.m();
  };
  dart.fn(cha_deopt1_test.bla, VoidTodynamic());
  cha_deopt1_test.X = class X extends core.Object {
    new() {
      this.fld = new cha_deopt1_lib.T();
    }
    test(t) {
      if (t != null) {
        let tmp = t;
        this.fld = tmp;
      }
    }
  };
  dart.setSignature(cha_deopt1_test.X, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [cha_deopt1_lib.T])})
  });
  cha_deopt1_lib.T = class T extends core.Object {
    m() {
      return 42;
    }
  };
  dart.setSignature(cha_deopt1_lib.T, {
    methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
  });
  cha_deopt1_deferred_lib.U = class U extends cha_deopt1_lib.T {
    m() {
      return "good horse";
    }
  };
  cha_deopt1_deferred_lib.make_u = function() {
    return new cha_deopt1_deferred_lib.U();
  };
  dart.fn(cha_deopt1_deferred_lib.make_u, VoidTodynamic());
  // Exports:
  exports.cha_deopt1_test = cha_deopt1_test;
  exports.cha_deopt1_lib = cha_deopt1_lib;
  exports.cha_deopt1_deferred_lib = cha_deopt1_deferred_lib;
});
