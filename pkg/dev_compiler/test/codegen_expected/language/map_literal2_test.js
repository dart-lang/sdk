dart_library.library('language/map_literal2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  map_literal2_test.nextValCtr = null;
  dart.copyProperties(map_literal2_test, {
    get nextVal() {
      let x = map_literal2_test.nextValCtr;
      map_literal2_test.nextValCtr = dart.notNull(x) + 1;
      return x;
    }
  });
  map_literal2_test.main = function() {
    map_literal2_test.nextValCtr = 0;
    let map = dart.map({[dart.str`a${map_literal2_test.nextVal}`]: "Grey", [dart.str`a${map_literal2_test.nextVal}`]: "Poupon"}, core.String, core.String);
    expect$.Expect.equals(true, map[dartx.containsKey]("a0"));
    expect$.Expect.equals(true, map[dartx.containsKey]("a1"));
    expect$.Expect.equals("Grey", map[dartx.get]("a0"));
    expect$.Expect.equals("Poupon", map[dartx.get]("a1"));
  };
  dart.fn(map_literal2_test.main, VoidTodynamic());
  // Exports:
  exports.map_literal2_test = map_literal2_test;
});
