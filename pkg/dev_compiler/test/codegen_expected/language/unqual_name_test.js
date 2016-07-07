dart_library.library('language/unqual_name_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unqual_name_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unqual_name_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unqual_name_test.B = class B extends core.Object {
    new(x, y) {
      this.b = y;
    }
    get_b() {
      return this.really_really_get_it();
    }
    really_really_get_it() {
      return 5;
    }
  };
  dart.setSignature(unqual_name_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(unqual_name_test.B, [dart.dynamic, dart.dynamic])}),
    methods: () => ({
      get_b: dart.definiteFunctionType(dart.dynamic, []),
      really_really_get_it: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  unqual_name_test.UnqualNameTest = class UnqualNameTest extends core.Object {
    static eleven() {
      return 11;
    }
    static testMain() {
      let o = new unqual_name_test.B(3, 5);
      expect$.Expect.equals(11, unqual_name_test.UnqualNameTest.eleven());
      expect$.Expect.equals(5, o.get_b());
      let a = 1, x = null, b = a + 3;
      expect$.Expect.equals(5, a + b);
    }
  };
  dart.setSignature(unqual_name_test.UnqualNameTest, {
    statics: () => ({
      eleven: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['eleven', 'testMain']
  });
  unqual_name_test.main = function() {
    unqual_name_test.UnqualNameTest.testMain();
  };
  dart.fn(unqual_name_test.main, VoidTodynamic());
  // Exports:
  exports.unqual_name_test = unqual_name_test;
});
