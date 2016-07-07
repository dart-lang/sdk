dart_library.library('language/import_self_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__import_self_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const import_self_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  import_self_test_none_multi._x = "The quick brown fox jumps over the dazy log";
  import_self_test_none_multi.main = function() {
    let t = "Falsches Üben von Xylophonmusik quält jeden größeren Zwerg";
    expect$.Expect.isTrue(t[dartx.endsWith]("Zwerg"));
  };
  dart.fn(import_self_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.import_self_test_none_multi = import_self_test_none_multi;
});
