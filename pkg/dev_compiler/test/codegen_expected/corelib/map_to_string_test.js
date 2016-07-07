dart_library.library('corelib/map_to_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_to_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_to_string_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  map_to_string_test.main = function() {
    let m = core.Map.new();
    m[dartx.set](0, 0);
    m[dartx.set](1, 1);
    m[dartx.set](2, m);
    expect$.Expect.equals('{0: 0, 1: 1, 2: {...}}', dart.toString(m));
    let err = new map_to_string_test.ThrowOnToString();
    m[dartx.set](1, err);
    expect$.Expect.throws(dart.bind(m, 'toString', dart.toString), dart.fn(e => dart.equals(e, "Bad!"), dynamicTobool()));
    m[dartx.set](1, 1);
    expect$.Expect.equals('{0: 0, 1: 1, 2: {...}}', dart.toString(m));
    m[dartx.set](err, 1);
    expect$.Expect.throws(dart.bind(m, 'toString', dart.toString), dart.fn(e => dart.equals(e, "Bad!"), dynamicTobool()));
    m[dartx.remove](err);
  };
  dart.fn(map_to_string_test.main, VoidTovoid());
  map_to_string_test.ThrowOnToString = class ThrowOnToString extends core.Object {
    toString() {
      dart.throw("Bad!");
    }
  };
  // Exports:
  exports.map_to_string_test = map_to_string_test;
});
