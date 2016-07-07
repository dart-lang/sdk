dart_library.library('language/type_variable_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__type_variable_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const type_variable_closure_test = Object.create(null);
  let C = () => (C = dart.constFn(type_variable_closure_test.C$()))();
  let COfint = () => (COfint = dart.constFn(type_variable_closure_test.C$(core.int)))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_variable_closure_test.C$ = dart.generic(T => {
    let dynamicToT = () => (dynamicToT = dart.constFn(dart.definiteFunctionType(T, [dart.dynamic])))();
    class C extends core.Object {
      foo() {
        this.x = null;
        this.x = dart.fn(a => T.is(a), dynamicTobool());
      }
      bar() {
        this.x = null;
        this.x = dart.fn(a => !T.is(a), dynamicTobool());
      }
      baz() {
        this.x = null;
        this.x = dart.fn(a => T.as(a), dynamicToT());
      }
    }
    dart.addTypeTests(C);
    dart.defineNamedConstructor(C, 'foo');
    dart.defineNamedConstructor(C, 'bar');
    dart.defineNamedConstructor(C, 'baz');
    dart.setSignature(C, {
      constructors: () => ({
        foo: dart.definiteFunctionType(type_variable_closure_test.C$(T), []),
        bar: dart.definiteFunctionType(type_variable_closure_test.C$(T), []),
        baz: dart.definiteFunctionType(type_variable_closure_test.C$(T), [])
      })
    });
    return C;
  });
  type_variable_closure_test.C = C();
  type_variable_closure_test.main = function() {
    expect$.Expect.isTrue(dart.dsend(new (COfint()).foo(), 'x', 1));
    expect$.Expect.isFalse(dart.dsend(new (COfint()).foo(), 'x', '1'));
    expect$.Expect.isFalse(dart.dsend(new (COfint()).bar(), 'x', 1));
    expect$.Expect.isTrue(dart.dsend(new (COfint()).bar(), 'x', '1'));
    expect$.Expect.equals(dart.dsend(new (COfint()).baz(), 'x', 1), 1);
    expect$.Expect.throws(dart.fn(() => dart.dsend(new (COfint()).baz(), 'x', '1'), VoidTovoid()));
  };
  dart.fn(type_variable_closure_test.main, VoidTodynamic());
  // Exports:
  exports.type_variable_closure_test = type_variable_closure_test;
});
