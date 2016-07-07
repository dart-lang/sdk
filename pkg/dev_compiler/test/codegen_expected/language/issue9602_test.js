dart_library.library('language/issue9602_test', null, /* Imports */[
  'dart_sdk'
], function load__issue9602_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue9602_test = Object.create(null);
  const issue9602_other = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _field = Symbol('_field');
  issue9602_other.M = class M extends core.Object {
    new() {
      this[_field] = null;
    }
  };
  issue9602_test.C = class C extends dart.mixin(core.Object, issue9602_other.M) {
    new() {
      super.new();
    }
  };
  issue9602_test.main = function() {
    new issue9602_test.C();
  };
  dart.fn(issue9602_test.main, VoidTodynamic());
  // Exports:
  exports.issue9602_test = issue9602_test;
  exports.issue9602_other = issue9602_other;
});
