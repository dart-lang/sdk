dart_library.library('language/built_in_identifier_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__built_in_identifier_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const built_in_identifier_test_none_multi = Object.create(null);
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  built_in_identifier_test_none_multi.PseudoKWTest = class PseudoKWTest extends core.Object {
    static testMain() {
      let as = 0;
      let dynamic = 0;
      let export$ = 0;
      let factory = 0;
      let get = 0;
      let implements$ = 0;
      let import$ = 0;
      let library = 0;
      let operator = 0;
      let part = 0;
      let set = 0;
      let typedef = 0;
      let native = 0;
      {
        function factory(set) {
        }
        dart.fn(factory, dynamicTovoid());
      }
      get:
        while (import$ > 0) {
          break get;
        }
      return library * operator;
    }
  };
  dart.setSignature(built_in_identifier_test_none_multi.PseudoKWTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  built_in_identifier_test_none_multi.A = class A extends core.Object {
    new() {
      this.typedef = 0;
      this.operator = "smooth";
    }
    set(x) {
      this.typedef = core.int._check(x);
    }
    get() {
      return dart.notNull(this.typedef) - 5;
    }
    static check() {
      let o = new built_in_identifier_test_none_multi.A();
      o.set(55);
      expect$.Expect.equals(50, o.get());
    }
  };
  dart.setSignature(built_in_identifier_test_none_multi.A, {
    methods: () => ({
      set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      get: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({check: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['check']
  });
  built_in_identifier_test_none_multi.B = class B extends core.Object {
    new() {
      this.set = 100;
    }
    get get() {
      return this.set;
    }
    set get(get) {
      return this.set = dart.asInt(2 * dart.notNull(core.num._check(dart.dload(get, 'get'))));
    }
    operator() {
      return 1;
    }
  };
  dart.setSignature(built_in_identifier_test_none_multi.B, {
    methods: () => ({operator: dart.definiteFunctionType(core.int, [])})
  });
  built_in_identifier_test_none_multi.C = class C extends core.Object {
    static get set() {
      return 111;
    }
    static set set(set) {}
  };
  built_in_identifier_test_none_multi.C.operator = 5;
  built_in_identifier_test_none_multi.C.get = null;
  built_in_identifier_test_none_multi.main = function() {
    built_in_identifier_test_none_multi.PseudoKWTest.testMain();
    built_in_identifier_test_none_multi.A.check();
    expect$.Expect.equals(1, new built_in_identifier_test_none_multi.B().operator());
    expect$.Expect.equals(5, built_in_identifier_test_none_multi.C.operator);
    expect$.Expect.equals(null, built_in_identifier_test_none_multi.C.get);
    built_in_identifier_test_none_multi.C.set = 0;
    expect$.Expect.equals(111, built_in_identifier_test_none_multi.C.set);
  };
  dart.fn(built_in_identifier_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.built_in_identifier_test_none_multi = built_in_identifier_test_none_multi;
});
