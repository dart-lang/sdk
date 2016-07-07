dart_library.library('language/super_setter_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_setter_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_setter_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_setter_test.Base = class Base extends core.Object {
    new() {
      this.value_ = null;
    }
    get value() {
      return this.value_;
    }
    set value(newValue) {
      this.value_ = dart.str`Base:${newValue}`;
    }
  };
  dart.setSignature(super_setter_test.Base, {
    constructors: () => ({new: dart.definiteFunctionType(super_setter_test.Base, [])})
  });
  super_setter_test.Derived = class Derived extends super_setter_test.Base {
    new() {
      super.new();
    }
    set value(newValue) {
      super.value = dart.str`Derived:${newValue}`;
    }
    get value() {
      return super.value;
    }
  };
  dart.setSignature(super_setter_test.Derived, {
    constructors: () => ({new: dart.definiteFunctionType(super_setter_test.Derived, [])})
  });
  super_setter_test.SuperSetterTest = class SuperSetterTest extends core.Object {
    static testMain() {
      let b = new super_setter_test.Derived();
      b.value = "foo";
      expect$.Expect.equals("Base:Derived:foo", b.value);
    }
  };
  dart.setSignature(super_setter_test.SuperSetterTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  super_setter_test.main = function() {
    super_setter_test.SuperSetterTest.testMain();
  };
  dart.fn(super_setter_test.main, VoidTodynamic());
  // Exports:
  exports.super_setter_test = super_setter_test;
});
