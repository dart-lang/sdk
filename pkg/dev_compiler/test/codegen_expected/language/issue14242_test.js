dart_library.library('language/issue14242_test', null, /* Imports */[
  'dart_sdk'
], function load__issue14242_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue14242_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue14242_test.A = class A extends core.Object {
    new() {
      this.foo = dart.map();
      this.bar = null;
    }
  };
  issue14242_test.main = function() {
    let a = new issue14242_test.A();
    a.foo[dartx.set](dart.wrapType(core.Object), 54);
    a.bar = 42;
    if (!core.Type.is(a.foo[dartx.keys][dartx.first])) {
      dart.throw('Test failed');
    }
  };
  dart.fn(issue14242_test.main, VoidTodynamic());
  // Exports:
  exports.issue14242_test = issue14242_test;
});
