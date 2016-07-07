dart_library.library('language/cast2_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cast2_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cast2_test_01_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cast2_test_01_multi.C = class C extends core.Object {
    new() {
      this.foo = 42;
      this.val = 0;
    }
    inc() {
      this.val = dart.notNull(this.val) + 1;
    }
  };
  dart.setSignature(cast2_test_01_multi.C, {
    methods: () => ({inc: dart.definiteFunctionType(dart.void, [])})
  });
  cast2_test_01_multi.D = class D extends cast2_test_01_multi.C {
    new() {
      this.bar = 37;
      super.new();
    }
  };
  cast2_test_01_multi.main = function() {
    let oc = new cast2_test_01_multi.C();
    let od = new cast2_test_01_multi.D();
    dart.dload(oc, 'bar');
    oc.inc();
    expect$.Expect.equals(1, oc.val);
    oc.inc();
    expect$.Expect.equals(2, oc.val);
  };
  dart.fn(cast2_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.cast2_test_01_multi = cast2_test_01_multi;
});
