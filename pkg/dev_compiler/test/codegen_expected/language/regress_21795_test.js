dart_library.library('language/regress_21795_test', null, /* Imports */[
  'dart_sdk'
], function load__regress_21795_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_21795_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_21795_test.foo = function(t) {
    try {
      if (dart.equals(t, 123)) dart.throw(42);
    } finally {
    }
  };
  dart.fn(regress_21795_test.foo, dynamicTodynamic());
  regress_21795_test.bar = function() {
    try {
      return 42;
    } finally {
    }
  };
  dart.fn(regress_21795_test.bar, VoidTodynamic());
  regress_21795_test.A = class A extends core.Object {
    test(t) {
      try {
        regress_21795_test.foo(t);
      } finally {
        if (dart.equals(t, 0)) {
          try {
          } catch (err) {
            let st = dart.stackTrace(err);
          }

        }
      }
    }
  };
  dart.setSignature(regress_21795_test.A, {
    methods: () => ({test: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  regress_21795_test.main = function() {
    let a = new regress_21795_test.A();
    for (let i = 0; i < 10000; ++i)
      a.test(0);
    try {
      a.test(123);
    } catch (e) {
      let s = dart.stackTrace(e);
      if (s.toString()[dartx.indexOf]("foo") == -1) {
        core.print(s);
        dart.throw("Expected foo in stacktrace!");
      }
    }

  };
  dart.fn(regress_21795_test.main, VoidTodynamic());
  // Exports:
  exports.regress_21795_test = regress_21795_test;
});
