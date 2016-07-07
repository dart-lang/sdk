dart_library.library('language/list_tracer_closure_test', null, /* Imports */[
  'dart_sdk'
], function load__list_tracer_closure_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const list_tracer_closure_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_tracer_closure_test.main = function() {
    let a = core.List.new();
    dart.bind(a, dartx.add);
    let b = core.List.new();
    let c = core.List.new(1);
    b[dartx.add](c);
    dart.dsetindex(b[dartx.get](0), 0, 42);
    if (!(typeof c[dartx.get](0) == 'number')) {
      dart.throw('Test failed');
    }
  };
  dart.fn(list_tracer_closure_test.main, VoidTodynamic());
  // Exports:
  exports.list_tracer_closure_test = list_tracer_closure_test;
});
