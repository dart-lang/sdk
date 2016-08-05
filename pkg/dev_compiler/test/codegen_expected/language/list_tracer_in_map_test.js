dart_library.library('language/list_tracer_in_map_test', null, /* Imports */[
  'dart_sdk'
], function load__list_tracer_in_map_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const list_tracer_in_map_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dart.defineLazy(list_tracer_in_map_test, {
    get b() {
      return JSArrayOfint().of([42]);
    },
    set b(_) {}
  });
  dart.defineLazy(list_tracer_in_map_test, {
    get a() {
      return dart.map({foo: list_tracer_in_map_test.b}, core.String, ListOfint());
    },
    set a(_) {}
  });
  list_tracer_in_map_test.main = function() {
    list_tracer_in_map_test.a[dartx.get]('foo')[dartx.clear]();
    if (list_tracer_in_map_test.b[dartx.length] != 0) dart.throw('Test failed');
  };
  dart.fn(list_tracer_in_map_test.main, VoidTodynamic());
  // Exports:
  exports.list_tracer_in_map_test = list_tracer_in_map_test;
});
