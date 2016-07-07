dart_library.library('language/regress_11800_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regress_11800_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regress_11800_test = Object.create(null);
  let ListAndintTodynamic = () => (ListAndintTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List, core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_11800_test.test = function(a, v) {
    a[dartx.set](v, v);
  };
  dart.fn(regress_11800_test.test, ListAndintTodynamic());
  regress_11800_test.main = function() {
    let list = core.List.new(2);
    for (let i = 0; i < 20; i++)
      regress_11800_test.test(list, 1);
    expect$.Expect.equals(null, list[dartx.get](0));
    expect$.Expect.equals(1, list[dartx.get](1));
  };
  dart.fn(regress_11800_test.main, VoidTodynamic());
  // Exports:
  exports.regress_11800_test = regress_11800_test;
});
