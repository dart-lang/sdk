dart_library.library('language/mixin_regress_13688_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_regress_13688_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_regress_13688_test = Object.create(null);
  let ComparableMixin = () => (ComparableMixin = dart.constFn(mixin_regress_13688_test.ComparableMixin$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_regress_13688_test.ComparableMixin$ = dart.generic(E => {
    class ComparableMixin extends core.Object {
      e() {
        return dart.wrapType(E);
      }
    }
    dart.addTypeTests(ComparableMixin);
    dart.setSignature(ComparableMixin, {
      methods: () => ({e: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return ComparableMixin;
  });
  mixin_regress_13688_test.ComparableMixin = ComparableMixin();
  mixin_regress_13688_test.KUID = class KUID extends dart.mixin(core.Object, mixin_regress_13688_test.ComparableMixin$(mixin_regress_13688_test.KUID)) {};
  mixin_regress_13688_test.main = function() {
    let kuid = new mixin_regress_13688_test.KUID();
    expect$.Expect.equals(dart.toString(kuid.runtimeType), dart.toString(kuid.e()));
  };
  dart.fn(mixin_regress_13688_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_regress_13688_test = mixin_regress_13688_test;
});
