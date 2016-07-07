dart_library.library('language/gc_test', null, /* Imports */[
  'dart_sdk'
], function load__gc_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const gc_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  gc_test.main = function() {
    let div = null;
    for (let i = 0; i < 200; ++i) {
      let l = core.List.new(1000000);
      let m = 2;
      div = dart.fn(_ => {
        let b = l;
      }, dynamicTodynamic());
      let lSmall = core.List.new(3);
      lSmall[dartx.set](0, l);
      l[dartx.set](0, lSmall);
    }
  };
  dart.fn(gc_test.main, VoidTodynamic());
  // Exports:
  exports.gc_test = gc_test;
});
