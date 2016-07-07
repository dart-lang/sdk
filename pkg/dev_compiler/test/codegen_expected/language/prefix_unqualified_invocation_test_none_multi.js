dart_library.library('language/prefix_unqualified_invocation_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__prefix_unqualified_invocation_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const prefix_unqualified_invocation_test_none_multi = Object.create(null);
  const empty_library = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  prefix_unqualified_invocation_test_none_multi.Base = class Base extends core.Object {
    p() {}
  };
  dart.setSignature(prefix_unqualified_invocation_test_none_multi.Base, {
    methods: () => ({p: dart.definiteFunctionType(dart.void, [])})
  });
  prefix_unqualified_invocation_test_none_multi.Derived = class Derived extends prefix_unqualified_invocation_test_none_multi.Base {
    f() {}
  };
  dart.setSignature(prefix_unqualified_invocation_test_none_multi.Derived, {
    methods: () => ({f: dart.definiteFunctionType(dart.void, [])})
  });
  prefix_unqualified_invocation_test_none_multi.main = function() {
    new prefix_unqualified_invocation_test_none_multi.Derived().f();
  };
  dart.fn(prefix_unqualified_invocation_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.prefix_unqualified_invocation_test_none_multi = prefix_unqualified_invocation_test_none_multi;
  exports.empty_library = empty_library;
});
