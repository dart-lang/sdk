dart_library.library('language/const_map_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_map_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_map_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_map_test.confuse = function(x) {
    if (dart.equals(new core.DateTime.now(), 42)) return const_map_test.confuse(2);
    return x;
  };
  dart.fn(const_map_test.confuse, dynamicTodynamic());
  let const$;
  const_map_test.main = function() {
    let m = const$ || (const$ = dart.const(dart.map([1, 42, "foo", 499], core.Object, core.int)));
    expect$.Expect.equals(42, m[dartx.get](const_map_test.confuse(1.0)));
    expect$.Expect.equals(499, m[dartx.get](const_map_test.confuse(core.String.fromCharCodes("foo"[dartx.runes]))));
  };
  dart.fn(const_map_test.main, VoidTodynamic());
  // Exports:
  exports.const_map_test = const_map_test;
});
