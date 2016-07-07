dart_library.library('language/field_increment_bailout_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_increment_bailout_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_increment_bailout_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_increment_bailout_test.N = class N extends core.Object {
    new(outgoing, incoming) {
      this.outgoing = outgoing;
      this.incoming = incoming;
    }
  };
  dart.setSignature(field_increment_bailout_test.N, {
    constructors: () => ({new: dart.definiteFunctionType(field_increment_bailout_test.N, [dart.dynamic, dart.dynamic])})
  });
  field_increment_bailout_test.A = class A extends core.Object {
    new(node) {
      this.node = node;
      this.list = dart.dload(node, 'outgoing');
      this.offset = 0;
    }
    next() {
      let edge = dart.dindex(this.list, (() => {
        let x = this.offset;
        this.offset = dart.notNull(x) + 1;
        return x;
      })());
      if (dart.equals(this.list, dart.dload(this.node, 'outgoing'))) {
        this.list = dart.dload(this.node, 'incoming');
        this.offset = 0;
      } else
        this.list = null;
      return edge;
    }
  };
  dart.setSignature(field_increment_bailout_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(field_increment_bailout_test.A, [dart.dynamic])}),
    methods: () => ({next: dart.definiteFunctionType(dart.dynamic, [])})
  });
  field_increment_bailout_test.L = class L extends core.Object {
    new(list) {
      this.list = list;
    }
    noSuchMethod(mirror) {
      return mirrors.reflect(this.list).delegate(mirror);
    }
  };
  dart.setSignature(field_increment_bailout_test.L, {
    constructors: () => ({new: dart.definiteFunctionType(field_increment_bailout_test.L, [dart.dynamic])})
  });
  field_increment_bailout_test.main = function() {
    let o = new field_increment_bailout_test.A(new field_increment_bailout_test.N(new field_increment_bailout_test.L(JSArrayOfint().of([1])), new field_increment_bailout_test.L(JSArrayOfint().of([2]))));
    for (let i = 1; i <= 2; i++)
      expect$.Expect.equals(i, o.next());
    expect$.Expect.equals(null, o.list);
  };
  dart.fn(field_increment_bailout_test.main, VoidTodynamic());
  // Exports:
  exports.field_increment_bailout_test = field_increment_bailout_test;
});
