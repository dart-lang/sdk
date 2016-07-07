dart_library.library('language/megamorphic_no_such_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__megamorphic_no_such_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const megamorphic_no_such_method_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  megamorphic_no_such_method_test.A0 = class A0 extends core.Object {
    test() {
      return 0;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A0, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A1 = class A1 extends core.Object {
    test() {
      return 1;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A1, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A2 = class A2 extends core.Object {
    test() {
      return 2;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A2, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A3 = class A3 extends core.Object {
    test() {
      return 3;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A3, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A4 = class A4 extends core.Object {
    test() {
      return 4;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A4, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A5 = class A5 extends core.Object {
    test() {
      return 5;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A5, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A6 = class A6 extends core.Object {
    test() {
      return 6;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A6, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A7 = class A7 extends core.Object {
    test() {
      return 7;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A7, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A8 = class A8 extends core.Object {
    test() {
      return 8;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A8, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.A9 = class A9 extends core.Object {
    test() {
      return 9;
    }
  };
  dart.setSignature(megamorphic_no_such_method_test.A9, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [])})
  });
  megamorphic_no_such_method_test.B = class B extends core.Object {};
  megamorphic_no_such_method_test.test = function(obj) {
    return dart.dsend(obj, 'test');
  };
  dart.fn(megamorphic_no_such_method_test.test, dynamicTodynamic());
  megamorphic_no_such_method_test.main = function() {
    let list = JSArrayOfObject().of([new megamorphic_no_such_method_test.A0(), new megamorphic_no_such_method_test.A1(), new megamorphic_no_such_method_test.A2(), new megamorphic_no_such_method_test.A3(), new megamorphic_no_such_method_test.A4(), new megamorphic_no_such_method_test.A5(), new megamorphic_no_such_method_test.A6(), new megamorphic_no_such_method_test.A7(), new megamorphic_no_such_method_test.A8(), new megamorphic_no_such_method_test.A9()]);
    for (let i = 0; i < 20; i++) {
      for (let obj of list) {
        megamorphic_no_such_method_test.test(obj);
      }
    }
    expect$.Expect.throws(dart.fn(() => megamorphic_no_such_method_test.test(new megamorphic_no_such_method_test.B()), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(megamorphic_no_such_method_test.main, VoidTodynamic());
  // Exports:
  exports.megamorphic_no_such_method_test = megamorphic_no_such_method_test;
});
