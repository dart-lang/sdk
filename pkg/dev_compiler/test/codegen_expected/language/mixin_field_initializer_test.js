dart_library.library('language/mixin_field_initializer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_field_initializer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_field_initializer_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_field_initializer_test.S = class S extends core.Object {
    new() {
      this.s1 = mixin_field_initializer_test.S.good_stuff();
    }
    static good_stuff() {
      return "Speyburn";
    }
  };
  dart.setSignature(mixin_field_initializer_test.S, {
    statics: () => ({good_stuff: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['good_stuff']
  });
  mixin_field_initializer_test.good_stuff = function() {
    return "Glenfiddich";
  };
  dart.fn(mixin_field_initializer_test.good_stuff, VoidTodynamic());
  mixin_field_initializer_test.M = class M extends core.Object {
    new() {
      this.m1 = mixin_field_initializer_test.M.good_stuff();
    }
    static good_stuff() {
      return "Macallen";
    }
  };
  dart.setSignature(mixin_field_initializer_test.M, {
    statics: () => ({good_stuff: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['good_stuff']
  });
  mixin_field_initializer_test.A = class A extends dart.mixin(mixin_field_initializer_test.S, mixin_field_initializer_test.M) {
    new() {
      super.new();
    }
    static good_stuff() {
      return "Ardberg";
    }
  };
  mixin_field_initializer_test.main = function() {
    let a = new mixin_field_initializer_test.A();
    expect$.Expect.equals("Macallen", a.m1);
    expect$.Expect.equals("Speyburn", a.s1);
    let m = new mixin_field_initializer_test.M();
    expect$.Expect.equals("Macallen", m.m1);
  };
  dart.fn(mixin_field_initializer_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_field_initializer_test = mixin_field_initializer_test;
});
