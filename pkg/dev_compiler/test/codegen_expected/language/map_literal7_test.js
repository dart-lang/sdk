dart_library.library('language/map_literal7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__map_literal7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const map_literal7_test = Object.create(null);
  let MapOfString$int = () => (MapOfString$int = dart.constFn(core.Map$(core.String, core.int)))();
  let MapOfint$dynamic = () => (MapOfint$dynamic = dart.constFn(core.Map$(core.int, dart.dynamic)))();
  let MapOfdynamic$String = () => (MapOfdynamic$String = dart.constFn(core.Map$(dart.dynamic, core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let const$;
  let const$0;
  map_literal7_test.main = function() {
    let m1 = const$ || (const$ = dart.const(dart.map({"0": 0, "1": 1}, core.String, core.int)));
    expect$.Expect.isTrue(core.Map.is(m1));
    expect$.Expect.isTrue(MapOfString$int().is(m1));
    expect$.Expect.isTrue(MapOfint$dynamic().is(m1));
    expect$.Expect.isTrue(MapOfdynamic$String().is(m1));
    let m2 = const$0 || (const$0 = dart.const(dart.map({"0": 0, "1": 1}, core.String, core.int)));
    expect$.Expect.isTrue(core.Map.is(m2));
    expect$.Expect.isTrue(MapOfString$int().is(m2));
    expect$.Expect.isFalse(MapOfint$dynamic().is(m2));
    expect$.Expect.isFalse(MapOfdynamic$String().is(m2));
  };
  dart.fn(map_literal7_test.main, VoidTovoid());
  // Exports:
  exports.map_literal7_test = map_literal7_test;
});
