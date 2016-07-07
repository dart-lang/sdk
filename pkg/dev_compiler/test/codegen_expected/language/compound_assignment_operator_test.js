dart_library.library('language/compound_assignment_operator_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__compound_assignment_operator_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const compound_assignment_operator_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  const _f = Symbol('_f');
  compound_assignment_operator_test.Indexed = class Indexed extends core.Object {
    new() {
      this[_f] = core.List.new(10);
      this.count = 0;
      dart.dsetindex(this[_f], 0, 100);
      dart.dsetindex(this[_f], 1, 200);
    }
    get(i) {
      this.count = dart.dsend(this.count, '+', 1);
      return this[_f];
    }
  };
  dart.setSignature(compound_assignment_operator_test.Indexed, {
    constructors: () => ({new: dart.definiteFunctionType(compound_assignment_operator_test.Indexed, [])}),
    methods: () => ({get: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  compound_assignment_operator_test.result = null;
  compound_assignment_operator_test.A = class A extends core.Object {
    get field() {
      dart.dsend(compound_assignment_operator_test.result, 'add', 1);
      return 1;
    }
    set field(value) {}
    static get static_field() {
      dart.dsend(compound_assignment_operator_test.result, 'add', 0);
      return 1;
    }
    static set static_field(value) {
      dart.dsend(compound_assignment_operator_test.result, 'add', 1);
    }
  };
  compound_assignment_operator_test.CompoundAssignmentOperatorTest = class CompoundAssignmentOperatorTest extends core.Object {
    static testIndexed() {
      let indexed = new compound_assignment_operator_test.Indexed();
      expect$.Expect.equals(0, indexed.count);
      let tmp = indexed.get(0);
      expect$.Expect.equals(1, indexed.count);
      expect$.Expect.equals(100, dart.dindex(indexed.get(4), 0));
      expect$.Expect.equals(2, indexed.count);
      expect$.Expect.equals(100, (() => {
        let o = indexed.get(4), i = 0, x = dart.dindex(o, i);
        dart.dsetindex(o, i, dart.dsend(x, '+', 1));
        return x;
      })());
      expect$.Expect.equals(3, indexed.count);
      expect$.Expect.equals(101, dart.dindex(indexed.get(4), 0));
      expect$.Expect.equals(4, indexed.count);
      let o = indexed.get(4), i$ = 0;
      dart.dsetindex(o, i$, dart.dsend(dart.dindex(o, i$), '+', 10));
      expect$.Expect.equals(5, indexed.count);
      expect$.Expect.equals(111, dart.dindex(indexed.get(4), 0));
      let i = 0;
      let o$ = indexed.get(3), i$0 = i++;
      dart.dsetindex(o$, i$0, dart.dsend(dart.dindex(o$, i$0), '+', 1));
      expect$.Expect.equals(1, i);
    }
    static testIndexedMore() {
      compound_assignment_operator_test.result = [];
      function array() {
        dart.dsend(compound_assignment_operator_test.result, 'add', 0);
        return JSArrayOfint().of([0]);
      }
      dart.fn(array, VoidTodynamic());
      function index() {
        dart.dsend(compound_assignment_operator_test.result, 'add', 1);
        return 0;
      }
      dart.fn(index, VoidTodynamic());
      function middle() {
        dart.dsend(compound_assignment_operator_test.result, 'add', 2);
      }
      dart.fn(middle, VoidTodynamic());
      function sequence(a, b, c) {
        dart.dsend(compound_assignment_operator_test.result, 'add', 3);
      }
      dart.fn(sequence, dynamicAnddynamicAnddynamicTodynamic());
      sequence((() => {
        let o = array(), i = index();
        return dart.dsetindex(o, i, dart.dsend(dart.dindex(o, i), '+', 1));
      })(), middle(), (() => {
        let o = array(), i = index();
        return dart.dsetindex(o, i, dart.dsend(dart.dindex(o, i), '+', 1));
      })());
      expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 0, 1, 3]), core.List._check(compound_assignment_operator_test.result));
    }
    static testIndexedMoreMore() {
      compound_assignment_operator_test.result = [];
      function middle() {
        dart.dsend(compound_assignment_operator_test.result, 'add', 2);
      }
      dart.fn(middle, VoidTodynamic());
      function obj() {
        dart.dsend(compound_assignment_operator_test.result, 'add', 0);
        return new compound_assignment_operator_test.A();
      }
      dart.fn(obj, VoidTodynamic());
      function sequence(a, b, c) {
        dart.dsend(compound_assignment_operator_test.result, 'add', 3);
      }
      dart.fn(sequence, dynamicAnddynamicAnddynamicTodynamic());
      sequence((() => {
        let o = obj();
        return dart.dput(o, 'field', dart.dsend(dart.dload(o, 'field'), '+', 1));
      })(), middle(), (() => {
        let o = obj();
        return dart.dput(o, 'field', dart.dsend(dart.dload(o, 'field'), '+', 1));
      })());
      expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 0, 1, 3]), core.List._check(compound_assignment_operator_test.result));
      compound_assignment_operator_test.result = [];
      sequence((() => {
        let x = compound_assignment_operator_test.A.static_field;
        compound_assignment_operator_test.A.static_field = dart.dsend(x, '+', 1);
        return x;
      })(), middle(), (() => {
        let x = compound_assignment_operator_test.A.static_field;
        compound_assignment_operator_test.A.static_field = dart.dsend(x, '+', 1);
        return x;
      })());
      expect$.Expect.listEquals(JSArrayOfint().of([0, 1, 2, 0, 1, 3]), core.List._check(compound_assignment_operator_test.result));
    }
    static testMain() {
      for (let i = 0; i < 20; i++) {
        compound_assignment_operator_test.CompoundAssignmentOperatorTest.testIndexed();
        compound_assignment_operator_test.CompoundAssignmentOperatorTest.testIndexedMore();
        compound_assignment_operator_test.CompoundAssignmentOperatorTest.testIndexedMoreMore();
      }
    }
  };
  dart.setSignature(compound_assignment_operator_test.CompoundAssignmentOperatorTest, {
    statics: () => ({
      testIndexed: dart.definiteFunctionType(dart.void, []),
      testIndexedMore: dart.definiteFunctionType(dart.dynamic, []),
      testIndexedMoreMore: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testIndexed', 'testIndexedMore', 'testIndexedMoreMore', 'testMain']
  });
  compound_assignment_operator_test.main = function() {
    compound_assignment_operator_test.CompoundAssignmentOperatorTest.testMain();
  };
  dart.fn(compound_assignment_operator_test.main, VoidTodynamic());
  // Exports:
  exports.compound_assignment_operator_test = compound_assignment_operator_test;
});
