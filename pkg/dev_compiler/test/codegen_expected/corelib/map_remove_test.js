dart_library.library('corelib/map_remove_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_remove_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_remove_test = Object.create(null);
  let MapOfB$B = () => (MapOfB$B = dart.constFn(core.Map$(map_remove_test.B, map_remove_test.B)))();
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(map_remove_test.B)))();
  let JSArrayOfMapOfB$B = () => (JSArrayOfMapOfB$B = dart.constFn(_interceptors.JSArray$(MapOfB$B())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  map_remove_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(map_remove_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(map_remove_test.A, [])})
  });
  map_remove_test.B = class B extends map_remove_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(map_remove_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(map_remove_test.B, [])})
  });
  let const$;
  let const$0;
  let const$1;
  map_remove_test.main = function() {
    let map1 = MapOfB$B().new();
    map1[dartx.set](const$ || (const$ = dart.const(new map_remove_test.B())), const$0 || (const$0 = dart.const(new map_remove_test.B())));
    let map2 = MapOfB$B().new();
    let list = JSArrayOfB().of([const$1 || (const$1 = dart.const(new map_remove_test.B()))]);
    let maps = JSArrayOfMapOfB$B().of([map1, map2]);
    for (let map of maps) {
      expect$.Expect.isNull(map[dartx.remove](new map_remove_test.A()));
    }
  };
  dart.fn(map_remove_test.main, VoidTodynamic());
  // Exports:
  exports.map_remove_test = map_remove_test;
});
