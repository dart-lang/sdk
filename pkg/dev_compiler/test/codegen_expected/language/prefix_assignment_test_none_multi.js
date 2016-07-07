dart_library.library('language/prefix_assignment_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__prefix_assignment_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const prefix_assignment_test_none_multi = Object.create(null);
  const empty_library = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  prefix_assignment_test_none_multi.Base = class Base extends core.Object {
    new() {
      this.p = null;
    }
  };
  prefix_assignment_test_none_multi.Derived = class Derived extends prefix_assignment_test_none_multi.Base {
    new() {
      super.new();
    }
    f() {}
  };
  dart.setSignature(prefix_assignment_test_none_multi.Derived, {
    methods: () => ({f: dart.definiteFunctionType(dart.void, [])})
  });
  prefix_assignment_test_none_multi.main = function() {
    new prefix_assignment_test_none_multi.Derived().f();
  };
  dart.fn(prefix_assignment_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.prefix_assignment_test_none_multi = prefix_assignment_test_none_multi;
  exports.empty_library = empty_library;
});
