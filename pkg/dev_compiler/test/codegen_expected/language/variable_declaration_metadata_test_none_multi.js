dart_library.library('language/variable_declaration_metadata_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__variable_declaration_metadata_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const variable_declaration_metadata_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  variable_declaration_metadata_test_none_multi.annotation = null;
  variable_declaration_metadata_test_none_multi.v1 = null;
  variable_declaration_metadata_test_none_multi.v2 = null;
  variable_declaration_metadata_test_none_multi.v3 = null;
  variable_declaration_metadata_test_none_multi.v4 = null;
  variable_declaration_metadata_test_none_multi.C = class C extends core.Object {
    new() {
      this.f1 = null;
      this.f2 = null;
      this.f3 = null;
      this.f4 = null;
    }
  };
  variable_declaration_metadata_test_none_multi.use = function(x) {
    return x;
  };
  dart.fn(variable_declaration_metadata_test_none_multi.use, dynamicTodynamic());
  variable_declaration_metadata_test_none_multi.main = function() {
    variable_declaration_metadata_test_none_multi.use(variable_declaration_metadata_test_none_multi.v1);
    variable_declaration_metadata_test_none_multi.use(variable_declaration_metadata_test_none_multi.v2);
    variable_declaration_metadata_test_none_multi.use(variable_declaration_metadata_test_none_multi.v3);
    variable_declaration_metadata_test_none_multi.use(variable_declaration_metadata_test_none_multi.v4);
    let c = new variable_declaration_metadata_test_none_multi.C();
    variable_declaration_metadata_test_none_multi.use(c.f1);
    variable_declaration_metadata_test_none_multi.use(c.f2);
    variable_declaration_metadata_test_none_multi.use(c.f3);
    variable_declaration_metadata_test_none_multi.use(c.f4);
    let l1 = null, l2 = null;
    let l3 = null, l4 = null;
    variable_declaration_metadata_test_none_multi.use(l1);
    variable_declaration_metadata_test_none_multi.use(l2);
    variable_declaration_metadata_test_none_multi.use(l3);
    variable_declaration_metadata_test_none_multi.use(l4);
    for (let i1 = 0, i2 = 0;;) {
      variable_declaration_metadata_test_none_multi.use(i1);
      variable_declaration_metadata_test_none_multi.use(i2);
      break;
    }
    for (let i3 = 0, i4 = 0;;) {
      variable_declaration_metadata_test_none_multi.use(i3);
      variable_declaration_metadata_test_none_multi.use(i4);
      break;
    }
  };
  dart.fn(variable_declaration_metadata_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.variable_declaration_metadata_test_none_multi = variable_declaration_metadata_test_none_multi;
});
