dart_library.library('language/list_length_tracer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_length_tracer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_length_tracer_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_length_tracer_test.a = 42;
  list_length_tracer_test.b = null;
  let const$;
  list_length_tracer_test.main = function() {
    expect$.Expect.throws(dart.fn(() => dart.dload(list_length_tracer_test.b, 'length'), VoidTovoid()));
    list_length_tracer_test.b = const$ || (const$ = dart.constList([42], core.int));
  };
  dart.fn(list_length_tracer_test.main, VoidTodynamic());
  // Exports:
  exports.list_length_tracer_test = list_length_tracer_test;
});
