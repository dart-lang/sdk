dart_library.library('language/unicode_bom_middle_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unicode_bom_middle_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unicode_bom_middle_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unicode_bom_middle_test.inscrutable = function(x) {
    return x == 0 ? 0 : (dart.notNull(x) | dart.notNull(unicode_bom_middle_test.inscrutable((dart.notNull(x) & dart.notNull(x) - 1) >>> 0))) >>> 0;
  };
  dart.fn(unicode_bom_middle_test.inscrutable, intToint());
  unicode_bom_middle_test.foo = function(x) {
    if (unicode_bom_middle_test.inscrutable(1999) == 1999) return x;
    return 499;
  };
  dart.fn(unicode_bom_middle_test.foo, dynamicTodynamic());
  unicode_bom_middle_test.main = function() {
    expect$.Expect.equals(3, "x﻿x"[dartx.length]);
    expect$.Expect.equals(3, dart.dload(unicode_bom_middle_test.foo("x﻿x"), 'length'));
  };
  dart.fn(unicode_bom_middle_test.main, VoidTodynamic());
  // Exports:
  exports.unicode_bom_middle_test = unicode_bom_middle_test;
});
