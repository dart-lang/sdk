dart_library.library('language/operator_index_evaluation_order_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__operator_index_evaluation_order_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const operator_index_evaluation_order_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let dynamicToB = () => (dynamicToB = dart.constFn(dart.definiteFunctionType(operator_index_evaluation_order_test.B, [dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  operator_index_evaluation_order_test.B = class B extends core.Object {
    new(trace) {
      this.trace = trace;
      this.value = 100;
    }
    get(index) {
      this.trace[dartx.add](-3);
      this.trace[dartx.add](index);
      this.trace[dartx.add](this.value);
      this.value = dart.notNull(this.value) + 1;
      return this;
    }
    set(index, value) {
      this.trace[dartx.add](-5);
      this.trace[dartx.add](index);
      this.trace[dartx.add](dart.dload(value, 'value'));
      this.value = dart.notNull(this.value) + 1;
      return value;
    }
    ['+'](value) {
      this.trace[dartx.add](-4);
      this.trace[dartx.add](this.value);
      this.trace[dartx.add](value);
      this.value = dart.notNull(this.value) + 1;
      return this;
    }
  };
  dart.setSignature(operator_index_evaluation_order_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(operator_index_evaluation_order_test.B, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic]),
      set: dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic]),
      '+': dart.definiteFunctionType(dart.dynamic, [core.int])
    })
  });
  operator_index_evaluation_order_test.getB = function(trace) {
    dart.dsend(trace, 'add', -1);
    return new operator_index_evaluation_order_test.B(core.List._check(trace));
  };
  dart.fn(operator_index_evaluation_order_test.getB, dynamicToB());
  operator_index_evaluation_order_test.getIndex = function(trace) {
    dart.dsend(trace, 'add', -2);
    return 42;
  };
  dart.fn(operator_index_evaluation_order_test.getIndex, dynamicToint());
  operator_index_evaluation_order_test.main = function() {
    let trace = core.List.new();
    let o = operator_index_evaluation_order_test.getB(trace), i = operator_index_evaluation_order_test.getIndex(trace);
    o.set(i, dart.dsend(o.get(i), '+', 37));
    expect$.Expect.listEquals(JSArrayOfint().of([-1, -2, -3, 42, 100, -4, 101, 37, -5, 42, 102]), trace);
  };
  dart.fn(operator_index_evaluation_order_test.main, VoidTodynamic());
  // Exports:
  exports.operator_index_evaluation_order_test = operator_index_evaluation_order_test;
});
