dart_library.library('language/mixin_regress_11398_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_regress_11398_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_regress_11398_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_regress_11398_test.main = function() {
    let hva = new mixin_regress_11398_test.HasValueA();
    hva.value = '42';
    expect$.Expect.equals('42', hva.value);
    let hvb = new mixin_regress_11398_test.HasValueB();
    hvb.value = '87';
    expect$.Expect.equals('87', hvb.value);
    let hvc = new mixin_regress_11398_test.HasValueC();
    hvc.value = '99';
    expect$.Expect.equals('99', hvc.value);
  };
  dart.fn(mixin_regress_11398_test.main, VoidTovoid());
  mixin_regress_11398_test.Delegate = class Delegate extends core.Object {};
  mixin_regress_11398_test.DelegateMixin = class DelegateMixin extends core.Object {
    invoke(value) {
      return value;
    }
  };
  dart.setSignature(mixin_regress_11398_test.DelegateMixin, {
    methods: () => ({invoke: dart.definiteFunctionType(core.String, [core.String])})
  });
  const _value = Symbol('_value');
  mixin_regress_11398_test.HasValueMixin = class HasValueMixin extends core.Object {
    new() {
      this[_value] = null;
    }
    set value(value) {
      this[_value] = this.invoke(value);
    }
    get value() {
      return this[_value];
    }
  };
  mixin_regress_11398_test.HasValueMixin[dart.implements] = () => [mixin_regress_11398_test.Delegate];
  mixin_regress_11398_test.HasValueA = class HasValueA extends dart.mixin(core.Object, mixin_regress_11398_test.HasValueMixin, mixin_regress_11398_test.DelegateMixin) {
    new() {
      super.new();
    }
  };
  mixin_regress_11398_test.HasValueB = class HasValueB extends dart.mixin(core.Object, mixin_regress_11398_test.DelegateMixin, mixin_regress_11398_test.HasValueMixin) {
    new() {
      super.new();
    }
  };
  mixin_regress_11398_test.HasValueC = class HasValueC extends dart.mixin(core.Object, mixin_regress_11398_test.HasValueMixin) {
    new() {
      super.new();
    }
    invoke(value) {
      return value;
    }
  };
  dart.setSignature(mixin_regress_11398_test.HasValueC, {
    methods: () => ({invoke: dart.definiteFunctionType(core.String, [core.String])})
  });
  // Exports:
  exports.mixin_regress_11398_test = mixin_regress_11398_test;
});
