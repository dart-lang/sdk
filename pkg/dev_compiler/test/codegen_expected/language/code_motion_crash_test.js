dart_library.library('language/code_motion_crash_test', null, /* Imports */[
  'dart_sdk'
], function load__code_motion_crash_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const code_motion_crash_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  code_motion_crash_test.A = class A extends core.Object {
    foo() {
      new code_motion_crash_test.A().field = 42;
    }
    _() {
      this.finalField = 42;
      this.field = 2;
    }
    new() {
      this.finalField = JSArrayOfObject().of([new code_motion_crash_test.A._(), new code_motion_crash_test.B(), new core.Object()])[dartx.get](1);
      this.field = 2;
    }
  };
  dart.defineNamedConstructor(code_motion_crash_test.A, '_');
  dart.setSignature(code_motion_crash_test.A, {
    constructors: () => ({
      _: dart.definiteFunctionType(code_motion_crash_test.A, []),
      new: dart.definiteFunctionType(code_motion_crash_test.A, [])
    }),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  code_motion_crash_test.B = class B extends core.Object {
    foo() {}
    bar() {}
  };
  dart.setSignature(code_motion_crash_test.B, {
    methods: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      bar: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  code_motion_crash_test.main = function() {
    let a = new code_motion_crash_test.A();
    if (true) {
      let b = a.finalField;
      let d = a.field;
      dart.dsend(b, 'bar');
      let c = a.finalField;
      dart.dsend(c, 'foo');
      let e = a.field;
      if (dart.notNull(d) + dart.notNull(e) != 4) dart.throw('Test failed');
    }
  };
  dart.fn(code_motion_crash_test.main, VoidTodynamic());
  // Exports:
  exports.code_motion_crash_test = code_motion_crash_test;
});
