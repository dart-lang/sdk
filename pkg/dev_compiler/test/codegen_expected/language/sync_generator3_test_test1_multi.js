dart_library.library('language/sync_generator3_test_test1_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__sync_generator3_test_test1_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const sync_generator3_test_test1_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  sync_generator3_test_test1_multi.f = function() {
    return dart.syncStar(function*() {
      try {
        yield 1;
        dart.throw("three");
      } catch (e) {
        yield 2;
        yield e;
      }
 finally {
        yield 4;
      }
    }, dart.dynamic);
  };
  dart.fn(sync_generator3_test_test1_multi.f, VoidTodynamic());
  sync_generator3_test_test1_multi.test1 = function() {
    let s = dart.toString(sync_generator3_test_test1_multi.f());
    expect$.Expect.equals("(1, 2, three, 4)", s);
    core.print(s);
  };
  dart.fn(sync_generator3_test_test1_multi.test1, VoidTodynamic());
  sync_generator3_test_test1_multi.g = function() {
    return dart.syncStar(function*() {
      try {
        yield "a";
        dart.throw("pow!");
      } finally {
        yield "b";
      }
    }, dart.dynamic);
  };
  dart.fn(sync_generator3_test_test1_multi.g, VoidTodynamic());
  sync_generator3_test_test1_multi.test2 = function() {
    let i = core.Iterator._check(dart.dload(sync_generator3_test_test1_multi.g(), 'iterator'));
    expect$.Expect.isTrue(i.moveNext());
    expect$.Expect.equals("a", i.current);
    expect$.Expect.isTrue(i.moveNext());
    expect$.Expect.equals("b", i.current);
    expect$.Expect.throws(dart.fn(() => i.moveNext(), VoidTobool()), dart.fn(error => dart.equals(error, "pow!"), dynamicTobool()));
  };
  dart.fn(sync_generator3_test_test1_multi.test2, VoidTodynamic());
  sync_generator3_test_test1_multi.main = function() {
    sync_generator3_test_test1_multi.test1();
  };
  dart.fn(sync_generator3_test_test1_multi.main, VoidTodynamic());
  // Exports:
  exports.sync_generator3_test_test1_multi = sync_generator3_test_test1_multi;
});
