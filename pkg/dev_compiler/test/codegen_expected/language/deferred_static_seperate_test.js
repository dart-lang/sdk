dart_library.library('language/deferred_static_seperate_test', null, /* Imports */[
  'dart_sdk',
  'async_helper',
  'expect'
], function load__deferred_static_seperate_test(exports, dart_sdk, async_helper, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const async_helper$ = async_helper.async_helper;
  const expect$ = expect.expect;
  const deferred_static_seperate_test = Object.create(null);
  const deferred_static_seperate_lib1 = Object.create(null);
  const deferred_static_seperate_lib2 = Object.create(null);
  let MapOfint$int = () => (MapOfint$int = dart.constFn(core.Map$(core.int, core.int)))();
  let JSArrayOfMapOfint$int = () => (JSArrayOfMapOfint$int = dart.constFn(_interceptors.JSArray$(MapOfint$int())))();
  let VoidToC = () => (VoidToC = dart.constFn(dart.definiteFunctionType(deferred_static_seperate_lib1.C, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  deferred_static_seperate_test.main = function() {
    async_helper$.asyncStart();
    expect$.Expect.throws(dart.fn(() => new deferred_static_seperate_lib1.C(), VoidToC()));
    loadLibrary().then(dart.dynamic)(dart.fn(_ => {
      loadLibrary().then(dart.dynamic)(dart.fn(_ => {
        core.print("HERE");
        expect$.Expect.equals(1, new deferred_static_seperate_lib1.C().bar());
        let x = new deferred_static_seperate_lib1.C2();
        expect$.Expect.mapEquals(dart.map([1, 2]), x.bar);
        x.bar = dart.map([2, 3]);
        expect$.Expect.mapEquals(dart.map([2, 3]), x.bar);
        expect$.Expect.equals(deferred_static_seperate_lib1.x, new deferred_static_seperate_lib1.C3().bar);
        expect$.Expect.mapEquals(dart.map([deferred_static_seperate_lib1.x, deferred_static_seperate_lib1.x]), new deferred_static_seperate_lib1.C4().bar);
        expect$.Expect.equals(1, new deferred_static_seperate_lib1.C5().bar());
        deferred_static_seperate_lib2.foo();
        async_helper$.asyncEnd();
      }, dynamicTodynamic()));
    }, dynamicTodynamic()));
  };
  dart.fn(deferred_static_seperate_test.main, VoidTovoid());
  deferred_static_seperate_lib1.ConstClass = class ConstClass extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(deferred_static_seperate_lib1.ConstClass, {
    constructors: () => ({new: dart.definiteFunctionType(deferred_static_seperate_lib1.ConstClass, [dart.dynamic])})
  });
  deferred_static_seperate_lib1.x = dart.const(new deferred_static_seperate_lib1.ConstClass(dart.const(new deferred_static_seperate_lib1.ConstClass(1))));
  deferred_static_seperate_lib1.C = class C extends core.Object {
    static foo() {
      dart.fn(() => {
      }, VoidTodynamic())();
      return 1;
    }
    bar() {
      dart.fn(() => {
      }, VoidTodynamic())();
      return 1;
    }
  };
  dart.setSignature(deferred_static_seperate_lib1.C, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['foo']
  });
  deferred_static_seperate_lib1.C1 = class C1 extends core.Object {
    new() {
      this.bar = dart.const(dart.map());
    }
  };
  deferred_static_seperate_lib1.C1.foo = dart.const(dart.map());
  deferred_static_seperate_lib1.C2 = class C2 extends core.Object {
    new() {
      this.bar = core.Map.from(dart.map([1, 2]));
    }
  };
  dart.defineLazy(deferred_static_seperate_lib1.C2, {
    get foo() {
      return core.Map.from(dart.map([1, 2]));
    },
    set foo(_) {}
  });
  deferred_static_seperate_lib1.C3 = class C3 extends core.Object {
    new() {
      this.bar = dart.const(new deferred_static_seperate_lib1.ConstClass(dart.const(new deferred_static_seperate_lib1.ConstClass(1))));
    }
  };
  deferred_static_seperate_lib1.C3.foo = dart.const(new deferred_static_seperate_lib1.ConstClass(dart.const(new deferred_static_seperate_lib1.ConstClass(1))));
  deferred_static_seperate_lib1.C4 = class C4 extends core.Object {
    new() {
      this.bar = core.Map.from(dart.map([deferred_static_seperate_lib1.x, deferred_static_seperate_lib1.x]));
    }
  };
  dart.defineLazy(deferred_static_seperate_lib1.C4, {
    get foo() {
      return core.Map.from(dart.map([deferred_static_seperate_lib1.x, deferred_static_seperate_lib1.x]));
    }
  });
  deferred_static_seperate_lib1.C5 = class C5 extends core.Object {
    bar() {
      dart.fn(() => {
      }, VoidTodynamic())();
      return 1;
    }
  };
  dart.setSignature(deferred_static_seperate_lib1.C5, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])})
  });
  deferred_static_seperate_lib1.C5.foo = dart.constList([dart.const(dart.map([1, 3]))], MapOfint$int());
  let const$;
  deferred_static_seperate_lib2.foo = function() {
    expect$.Expect.equals(1, deferred_static_seperate_lib1.C.foo());
    expect$.Expect.mapEquals(dart.map(), deferred_static_seperate_lib1.C1.foo);
    expect$.Expect.mapEquals(dart.map([1, 2]), deferred_static_seperate_lib1.C2.foo);
    deferred_static_seperate_lib1.C2.foo = dart.map([1, 2]);
    expect$.Expect.mapEquals(dart.map([1, 2]), deferred_static_seperate_lib1.C2.foo);
    expect$.Expect.equals(deferred_static_seperate_lib1.x, deferred_static_seperate_lib1.C3.foo);
    expect$.Expect.mapEquals(dart.map([deferred_static_seperate_lib1.x, deferred_static_seperate_lib1.x]), deferred_static_seperate_lib1.C4.foo);
    expect$.Expect.listEquals(JSArrayOfMapOfint$int().of([const$ || (const$ = dart.const(dart.map([1, 3])))]), deferred_static_seperate_lib1.C5.foo);
  };
  dart.fn(deferred_static_seperate_lib2.foo, VoidTodynamic());
  // Exports:
  exports.deferred_static_seperate_test = deferred_static_seperate_test;
  exports.deferred_static_seperate_lib1 = deferred_static_seperate_lib1;
  exports.deferred_static_seperate_lib2 = deferred_static_seperate_lib2;
});
