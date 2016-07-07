dart_library.library('corelib/map_contains_key_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_contains_key_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_contains_key_test = Object.create(null);
  let MapOfB$B = () => (MapOfB$B = dart.constFn(core.Map$(map_contains_key_test.B, map_contains_key_test.B)))();
  let JSArrayOfB = () => (JSArrayOfB = dart.constFn(_interceptors.JSArray$(map_contains_key_test.B)))();
  let JSArrayOfMapOfB$B = () => (JSArrayOfMapOfB$B = dart.constFn(_interceptors.JSArray$(MapOfB$B())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  map_contains_key_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(map_contains_key_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(map_contains_key_test.A, [])})
  });
  map_contains_key_test.B = class B extends map_contains_key_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(map_contains_key_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(map_contains_key_test.B, [])})
  });
  let const$;
  let const$0;
  let const$1;
  map_contains_key_test.main = function() {
    let map1 = MapOfB$B().new();
    map1[dartx.set](const$ || (const$ = dart.const(new map_contains_key_test.B())), const$0 || (const$0 = dart.const(new map_contains_key_test.B())));
    let map2 = MapOfB$B().new();
    let list = JSArrayOfB().of([const$1 || (const$1 = dart.const(new map_contains_key_test.B()))]);
    let maps = JSArrayOfMapOfB$B().of([map1, map2]);
    for (let map of maps) {
      expect$.Expect.isFalse(map[dartx.containsKey](new map_contains_key_test.A()));
    }
  };
  dart.fn(map_contains_key_test.main, VoidTodynamic());
  // Exports:
  exports.map_contains_key_test = map_contains_key_test;
});
