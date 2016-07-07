dart_library.library('language/const_evaluation_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_evaluation_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_evaluation_test_01_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  const_evaluation_test_01_multi.top_const = core.identical(-0.0, 0);
  const_evaluation_test_01_multi.top_final = core.identical(-0.0, 0);
  const_evaluation_test_01_multi.top_var = core.identical(-0.0, 0);
  const_evaluation_test_01_multi.C = class C extends core.Object {
    new() {
      this.instance_final = core.identical(-0.0, 0);
      this.instance_var = core.identical(-0.0, 0);
    }
    test() {
      let local_const = core.identical(-0.0, 0);
      let local_final = core.identical(-0.0, 0);
      let local_var = core.identical(-0.0, 0);
      expect$.Expect.equals(core.identical(-0.0, 0), const_evaluation_test_01_multi.top_const);
      expect$.Expect.equals(const_evaluation_test_01_multi.top_const, const_evaluation_test_01_multi.top_final);
      expect$.Expect.equals(const_evaluation_test_01_multi.top_final, const_evaluation_test_01_multi.top_var);
      expect$.Expect.equals(const_evaluation_test_01_multi.top_var, const_evaluation_test_01_multi.C.static_const);
      expect$.Expect.equals(const_evaluation_test_01_multi.C.static_const, const_evaluation_test_01_multi.C.static_final);
      expect$.Expect.equals(const_evaluation_test_01_multi.C.static_final, const_evaluation_test_01_multi.C.static_var);
      expect$.Expect.equals(const_evaluation_test_01_multi.C.static_var, this.instance_final);
      expect$.Expect.equals(this.instance_final, this.instance_var);
      expect$.Expect.equals(this.instance_var, local_const);
      expect$.Expect.equals(local_const, local_final);
      expect$.Expect.equals(local_final, local_var);
      let metadata = mirrors.reflectClass(dart.wrapType(const_evaluation_test_01_multi.C)).metadata[dartx.get](0).reflectee;
      expect$.Expect.equals(const_evaluation_test_01_multi.top_const, metadata);
      expect$.Expect.equals(local_var, metadata);
    }
  };
  dart.setSignature(const_evaluation_test_01_multi.C, {
    methods: () => ({test: dart.definiteFunctionType(dart.void, [])})
  });
  const_evaluation_test_01_multi.C.static_const = core.identical(-0.0, 0);
  const_evaluation_test_01_multi.C.static_final = core.identical(-0.0, 0);
  const_evaluation_test_01_multi.C.static_var = core.identical(-0.0, 0);
  const_evaluation_test_01_multi.main = function() {
    new const_evaluation_test_01_multi.C().test();
  };
  dart.fn(const_evaluation_test_01_multi.main, VoidTovoid());
  // Exports:
  exports.const_evaluation_test_01_multi = const_evaluation_test_01_multi;
});
