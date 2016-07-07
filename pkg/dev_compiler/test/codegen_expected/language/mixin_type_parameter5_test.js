dart_library.library('language/mixin_type_parameter5_test', null, /* Imports */[
  'dart_sdk'
], function load__mixin_type_parameter5_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_type_parameter5_test = Object.create(null);
  let MixinA = () => (MixinA = dart.constFn(mixin_type_parameter5_test.MixinA$()))();
  let MixinB = () => (MixinB = dart.constFn(mixin_type_parameter5_test.MixinB$()))();
  let MixinC = () => (MixinC = dart.constFn(mixin_type_parameter5_test.MixinC$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_type_parameter5_test.MixinA$ = dart.generic(T => {
    class MixinA extends core.Object {
      new() {
        this.intField = null;
      }
    }
    dart.addTypeTests(MixinA);
    return MixinA;
  });
  mixin_type_parameter5_test.MixinA = MixinA();
  mixin_type_parameter5_test.MixinB$ = dart.generic(S => {
    class MixinB extends core.Object {
      new() {
        this.stringField = null;
      }
    }
    dart.addTypeTests(MixinB);
    return MixinB;
  });
  mixin_type_parameter5_test.MixinB = MixinB();
  mixin_type_parameter5_test.MixinC$ = dart.generic((U, V) => {
    class MixinC extends core.Object {
      new() {
        this.listField = null;
        this.mapField = null;
      }
    }
    dart.addTypeTests(MixinC);
    return MixinC;
  });
  mixin_type_parameter5_test.MixinC = MixinC();
  mixin_type_parameter5_test.C = class C extends dart.mixin(core.Object, mixin_type_parameter5_test.MixinA$(core.int), mixin_type_parameter5_test.MixinB$(core.String), mixin_type_parameter5_test.MixinC$(core.List, core.Map)) {
    new() {
      super.new();
    }
  };
  mixin_type_parameter5_test.main = function() {
    let c = new mixin_type_parameter5_test.C();
    c.intField = 0;
    c.stringField = '';
    c.listField = [];
    c.mapField = dart.map();
  };
  dart.fn(mixin_type_parameter5_test.main, VoidTovoid());
  // Exports:
  exports.mixin_type_parameter5_test = mixin_type_parameter5_test;
});
