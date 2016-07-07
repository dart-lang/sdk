dart_library.library('corelib/iterable_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  iterable_test.MyIterable = class MyIterable extends collection.IterableBase {
    new() {
      super.new();
    }
    get iterator() {
      return [][dartx.iterator];
    }
  };
  dart.addSimpleTypeTests(iterable_test.MyIterable);
  dart.setSignature(iterable_test.MyIterable, {});
  dart.defineExtensionMembers(iterable_test.MyIterable, ['iterator']);
  iterable_test.main = function() {
    expect$.Expect.isTrue((() => {
      let _ = [];
      _[dartx.addAll](new iterable_test.MyIterable());
      return _;
    })()[dartx.isEmpty]);
  };
  dart.fn(iterable_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_test = iterable_test;
});
