dart_library.library('corelib/list_literal_is_growable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_literal_is_growable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_literal_is_growable_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_literal_is_growable_test.main = function() {
    let l = [];
    l[dartx.add](1);
    expect$.Expect.equals(1, l[dartx.length]);
    expect$.Expect.equals(1, l[dartx.get](0));
  };
  dart.fn(list_literal_is_growable_test.main, VoidTodynamic());
  // Exports:
  exports.list_literal_is_growable_test = list_literal_is_growable_test;
});
