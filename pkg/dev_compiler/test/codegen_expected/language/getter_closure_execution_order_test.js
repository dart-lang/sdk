dart_library.library('language/getter_closure_execution_order_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__getter_closure_execution_order_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const getter_closure_execution_order_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  getter_closure_execution_order_test.counter = 0;
  getter_closure_execution_order_test.Test1 = class Test1 extends core.Object {
    get a() {
      expect$.Expect.equals(1, getter_closure_execution_order_test.counter);
      getter_closure_execution_order_test.counter = dart.notNull(getter_closure_execution_order_test.counter) + 1;
      return dart.fn(c => {
      }, dynamicTodynamic());
    }
    b() {
      expect$.Expect.equals(0, getter_closure_execution_order_test.counter);
      getter_closure_execution_order_test.counter = dart.notNull(getter_closure_execution_order_test.counter) + 1;
      return 1;
    }
  };
  dart.setSignature(getter_closure_execution_order_test.Test1, {
    methods: () => ({b: dart.definiteFunctionType(dart.dynamic, [])})
  });
  getter_closure_execution_order_test.Test2 = class Test2 extends core.Object {
    static get a() {
      expect$.Expect.equals(0, getter_closure_execution_order_test.counter);
      getter_closure_execution_order_test.counter = dart.notNull(getter_closure_execution_order_test.counter) + 1;
      return dart.fn(c => {
      }, dynamicTodynamic());
    }
    static b() {
      expect$.Expect.equals(1, getter_closure_execution_order_test.counter);
      getter_closure_execution_order_test.counter = dart.notNull(getter_closure_execution_order_test.counter) + 1;
      return 1;
    }
  };
  dart.setSignature(getter_closure_execution_order_test.Test2, {
    statics: () => ({b: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['b']
  });
  dart.copyProperties(getter_closure_execution_order_test, {
    get a() {
      expect$.Expect.equals(0, getter_closure_execution_order_test.counter);
      getter_closure_execution_order_test.counter = dart.notNull(getter_closure_execution_order_test.counter) + 1;
      return dart.fn(c => {
      }, dynamicTodynamic());
    }
  });
  getter_closure_execution_order_test.b = function() {
    expect$.Expect.equals(1, getter_closure_execution_order_test.counter);
    getter_closure_execution_order_test.counter = dart.notNull(getter_closure_execution_order_test.counter) + 1;
    return 1;
  };
  dart.fn(getter_closure_execution_order_test.b, VoidTodynamic());
  getter_closure_execution_order_test.main = function() {
    let failures = [];
    try {
      getter_closure_execution_order_test.counter = 0;
      let o = new getter_closure_execution_order_test.Test1();
      dart.dsend(o, 'a', o.b());
      expect$.Expect.equals(2, getter_closure_execution_order_test.counter);
    } catch (exc) {
      let stack = dart.stackTrace(exc);
      failures[dartx.add](exc);
      failures[dartx.add](stack);
    }

    try {
      getter_closure_execution_order_test.counter = 0;
      dart.dsend(getter_closure_execution_order_test.Test2, 'a', getter_closure_execution_order_test.Test2.b());
      expect$.Expect.equals(2, getter_closure_execution_order_test.counter);
    } catch (exc) {
      let stack = dart.stackTrace(exc);
      failures[dartx.add](exc);
      failures[dartx.add](stack);
    }

    try {
      getter_closure_execution_order_test.counter = 0;
      dart.dcall(getter_closure_execution_order_test.a, getter_closure_execution_order_test.b());
      expect$.Expect.equals(2, getter_closure_execution_order_test.counter);
    } catch (exc) {
      let stack = dart.stackTrace(exc);
      failures[dartx.add](exc);
      failures[dartx.add](stack);
    }

    if (failures[dartx.length] != 0) {
      for (let msg of failures) {
        core.print(dart.toString(msg));
      }
      dart.throw(dart.str`${(dart.notNull(failures[dartx.length]) / 2)[dartx.truncate]()} tests failed.`);
    }
  };
  dart.fn(getter_closure_execution_order_test.main, VoidTodynamic());
  // Exports:
  exports.getter_closure_execution_order_test = getter_closure_execution_order_test;
});
