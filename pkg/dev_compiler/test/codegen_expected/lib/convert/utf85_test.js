dart_library.library('lib/convert/utf85_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__utf85_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const utf85_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  utf85_test.main = function() {
    for (let i = 0; i <= 1114111; i++) {
      if (i == convert.UNICODE_BOM_CHARACTER_RUNE) continue;
      expect$.Expect.equals(i, convert.UTF8.decode(convert.UTF8.encode(core.String.fromCharCode(i)))[dartx.runes].first);
    }
  };
  dart.fn(utf85_test.main, VoidTodynamic());
  // Exports:
  exports.utf85_test = utf85_test;
});
