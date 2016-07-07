dart_library.library('language/mixin_illegal_superclass_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__mixin_illegal_superclass_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const mixin_illegal_superclass_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_illegal_superclass_test_none_multi.S0 = class S0 extends core.Object {};
  mixin_illegal_superclass_test_none_multi.S1 = class S1 extends core.Object {};
  mixin_illegal_superclass_test_none_multi.S2 = class S2 extends mixin_illegal_superclass_test_none_multi.S0 {};
  mixin_illegal_superclass_test_none_multi.M0 = class M0 extends core.Object {};
  mixin_illegal_superclass_test_none_multi.M1 = class M1 extends core.Object {};
  mixin_illegal_superclass_test_none_multi.M2 = class M2 extends mixin_illegal_superclass_test_none_multi.M0 {};
  mixin_illegal_superclass_test_none_multi.C00 = class C00 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S0, mixin_illegal_superclass_test_none_multi.M0) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C01 = class C01 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S0, mixin_illegal_superclass_test_none_multi.M1) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C03 = class C03 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S0, mixin_illegal_superclass_test_none_multi.M0, mixin_illegal_superclass_test_none_multi.M1) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C10 = class C10 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S1, mixin_illegal_superclass_test_none_multi.M0) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C11 = class C11 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S1, mixin_illegal_superclass_test_none_multi.M1) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C13 = class C13 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S1, mixin_illegal_superclass_test_none_multi.M0, mixin_illegal_superclass_test_none_multi.M1) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C20 = class C20 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S2, mixin_illegal_superclass_test_none_multi.M0) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C21 = class C21 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S2, mixin_illegal_superclass_test_none_multi.M1) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.C23 = class C23 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S2, mixin_illegal_superclass_test_none_multi.M0, mixin_illegal_superclass_test_none_multi.M1) {
    new() {
      super.new();
    }
  };
  mixin_illegal_superclass_test_none_multi.D00 = class D00 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S0, mixin_illegal_superclass_test_none_multi.M0) {};
  mixin_illegal_superclass_test_none_multi.D01 = class D01 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S0, mixin_illegal_superclass_test_none_multi.M1) {};
  mixin_illegal_superclass_test_none_multi.D03 = class D03 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S0, mixin_illegal_superclass_test_none_multi.M0, mixin_illegal_superclass_test_none_multi.M1) {};
  mixin_illegal_superclass_test_none_multi.D10 = class D10 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S1, mixin_illegal_superclass_test_none_multi.M0) {};
  mixin_illegal_superclass_test_none_multi.D11 = class D11 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S1, mixin_illegal_superclass_test_none_multi.M1) {};
  mixin_illegal_superclass_test_none_multi.D13 = class D13 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S1, mixin_illegal_superclass_test_none_multi.M0, mixin_illegal_superclass_test_none_multi.M1) {};
  mixin_illegal_superclass_test_none_multi.D20 = class D20 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S2, mixin_illegal_superclass_test_none_multi.M0) {};
  mixin_illegal_superclass_test_none_multi.D21 = class D21 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S2, mixin_illegal_superclass_test_none_multi.M1) {};
  mixin_illegal_superclass_test_none_multi.D23 = class D23 extends dart.mixin(mixin_illegal_superclass_test_none_multi.S2, mixin_illegal_superclass_test_none_multi.M0, mixin_illegal_superclass_test_none_multi.M1) {};
  mixin_illegal_superclass_test_none_multi.main = function() {
    new mixin_illegal_superclass_test_none_multi.C00();
    new mixin_illegal_superclass_test_none_multi.C01();
    new mixin_illegal_superclass_test_none_multi.C03();
    new mixin_illegal_superclass_test_none_multi.C10();
    new mixin_illegal_superclass_test_none_multi.C11();
    new mixin_illegal_superclass_test_none_multi.C13();
    new mixin_illegal_superclass_test_none_multi.C20();
    new mixin_illegal_superclass_test_none_multi.C21();
    new mixin_illegal_superclass_test_none_multi.C23();
    new mixin_illegal_superclass_test_none_multi.D00();
    new mixin_illegal_superclass_test_none_multi.D01();
    new mixin_illegal_superclass_test_none_multi.D03();
    new mixin_illegal_superclass_test_none_multi.D10();
    new mixin_illegal_superclass_test_none_multi.D11();
    new mixin_illegal_superclass_test_none_multi.D13();
    new mixin_illegal_superclass_test_none_multi.D20();
    new mixin_illegal_superclass_test_none_multi.D21();
    new mixin_illegal_superclass_test_none_multi.D23();
  };
  dart.fn(mixin_illegal_superclass_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.mixin_illegal_superclass_test_none_multi = mixin_illegal_superclass_test_none_multi;
});
