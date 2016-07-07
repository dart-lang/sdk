dart_library.library('language/built_in_identifier_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__built_in_identifier_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const built_in_identifier_test_01_multi = Object.create(null);
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  built_in_identifier_test_01_multi.PseudoKWTest = class PseudoKWTest extends core.Object {
    static testMain() {
      let abstract = 0;
      let as = 0;
      let dynamic = 0;
      let export$ = 0;
      let external = 0;
      let factory = 0;
      let get = 0;
      let implements$ = 0;
      let import$ = 0;
      let library = 0;
      let operator = 0;
      let part = 0;
      let set = 0;
      let static$ = 0;
      let typedef = 0;
      let native = 0;
      {
        function factory(set) {
          return;
        }
        dart.fn(factory, dynamicTovoid());
      }
      get:
        while (import$ > 0) {
          break get;
        }
      return static$ + library * operator;
    }
  };
  dart.setSignature(built_in_identifier_test_01_multi.PseudoKWTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  built_in_identifier_test_01_multi.typedef = function(x) {
    return dart.str`typedef ${x}`;
  };
  dart.fn(built_in_identifier_test_01_multi.typedef, dynamicTodynamic());
  built_in_identifier_test_01_multi.static = function(abstract) {
    return dart.equals(abstract, true);
  };
  dart.fn(built_in_identifier_test_01_multi.static, dynamicTodynamic());
  built_in_identifier_test_01_multi.A = class A extends core.Object {
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
    static static() {
      return 1;
    }
    static check() {
      let o = new built_in_identifier_test_01_multi.A();
      o.set(55);
      expect$.Expect.equals(50, o.get());
      built_in_identifier_test_01_multi.A.static();
    }
  };
  dart.setSignature(built_in_identifier_test_01_multi.A, {
    methods: () => ({
      set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      get: dart.definiteFunctionType(dart.dynamic, [])
    }),
    statics: () => ({
      static: dart.definiteFunctionType(dart.dynamic, []),
      check: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['static', 'check']
  });
  built_in_identifier_test_01_multi.B = class B extends core.Object {
    new() {
      this.set = 100;
    }
    get get() {
      return this.set;
    }
    set get(get) {
      return this.set = dart.asInt(2 * dart.notNull(core.num._check(dart.dload(get, 'get'))));
    }
    static() {
      let set = new built_in_identifier_test_01_multi.B();
      set.get = set;
      expect$.Expect.equals(200, set.get);
    }
    operator() {
      return 1;
    }
  };
  dart.setSignature(built_in_identifier_test_01_multi.B, {
    methods: () => ({
      static: dart.definiteFunctionType(dart.dynamic, []),
      operator: dart.definiteFunctionType(core.int, [])
    })
  });
  built_in_identifier_test_01_multi.C = class C extends core.Object {
    static get set() {
      return 111;
    }
    static set set(set) {}
  };
  built_in_identifier_test_01_multi.C.operator = 5;
  built_in_identifier_test_01_multi.C.get = null;
  built_in_identifier_test_01_multi.main = function() {
    built_in_identifier_test_01_multi.PseudoKWTest.testMain();
    built_in_identifier_test_01_multi.A.check();
    new built_in_identifier_test_01_multi.B().static();
    expect$.Expect.equals(1, new built_in_identifier_test_01_multi.B().operator());
    expect$.Expect.equals(1, built_in_identifier_test_01_multi.A.static());
    built_in_identifier_test_01_multi.typedef("T");
    expect$.Expect.equals("typedef T", built_in_identifier_test_01_multi.typedef("T"));
    built_in_identifier_test_01_multi.static("true");
    expect$.Expect.equals(false, built_in_identifier_test_01_multi.static("true"));
    expect$.Expect.equals(5, built_in_identifier_test_01_multi.C.operator);
    expect$.Expect.equals(null, built_in_identifier_test_01_multi.C.get);
    built_in_identifier_test_01_multi.C.set = 0;
    expect$.Expect.equals(111, built_in_identifier_test_01_multi.C.set);
  };
  dart.fn(built_in_identifier_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.built_in_identifier_test_01_multi = built_in_identifier_test_01_multi;
});
