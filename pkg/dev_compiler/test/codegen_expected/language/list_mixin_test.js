dart_library.library('language/list_mixin_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_mixin_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_mixin_test = Object.create(null);
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_mixin_test.MyList = class MyList extends collection.ListBase {
    get length() {
      return 4;
    }
    set length(x) {}
    get(x) {
      return 42;
    }
    set(x, val) {
      return val;
    }
  };
  dart.addSimpleTypeTests(list_mixin_test.MyList);
  dart.setSignature(list_mixin_test.MyList, {
    methods: () => ({
      get: dart.definiteFunctionType(core.int, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_mixin_test.MyList, ['get', 'set', 'length', 'length']);
  list_mixin_test.main = function() {
    let x = new list_mixin_test.MyList();
    let z = 0;
    x.forEach(dart.fn(y => {
      z = dart.notNull(z) + dart.notNull(core.int._check(y));
    }, dynamicTovoid()));
    expect$.Expect.equals(z, 4 * 42);
  };
  dart.fn(list_mixin_test.main, VoidTodynamic());
  // Exports:
  exports.list_mixin_test = list_mixin_test;
});
