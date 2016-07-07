dart_library.library('language/unicode_hash_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unicode_hash_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unicode_hash_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unicode_hash_test.main = function() {
    expect$.Expect.equals("𐐒", "𐐒");
    expect$.Expect.equals(dart.hashCode("𐐒"), dart.hashCode("𐐒"));
  };
  dart.fn(unicode_hash_test.main, VoidTodynamic());
  // Exports:
  exports.unicode_hash_test = unicode_hash_test;
});
