dart_library.library('language/map_literal9_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal9_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal9_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let const$;
  let const$0;
  map_literal9_test.main = function() {
    let m1 = const$ || (const$ = dart.const(dart.map({"[object Object]": 0, "1": 1})));
    expect$.Expect.isFalse(m1[dartx.containsKey](new core.Object()));
    expect$.Expect.isNull(m1[dartx.get](new core.Object()));
    expect$.Expect.isFalse(m1[dartx.containsKey](1));
    expect$.Expect.isNull(m1[dartx.get](1));
    let m2 = const$0 || (const$0 = dart.const(dart.map({"[object Object]": 0, "1": 1, __proto__: 2})));
    expect$.Expect.isFalse(m2[dartx.containsKey](new core.Object()));
    expect$.Expect.isNull(m2[dartx.get](new core.Object()));
    expect$.Expect.isFalse(m2[dartx.containsKey](1));
    expect$.Expect.isNull(m2[dartx.get](1));
  };
  dart.fn(map_literal9_test.main, VoidTovoid());
  // Exports:
  exports.map_literal9_test = map_literal9_test;
});
