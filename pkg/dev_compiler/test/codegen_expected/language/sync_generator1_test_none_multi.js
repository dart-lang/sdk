dart_library.library('language/sync_generator1_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__sync_generator1_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const sync_generator1_test_none_multi = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  sync_generator1_test_none_multi.sum10 = function() {
    return dart.syncStar(function*() {
      let s = 0;
      for (let k = 1; k <= 10; k++) {
        s = s + k;
        yield s;
      }
    }, dart.dynamic);
  };
  dart.fn(sync_generator1_test_none_multi.sum10, VoidTodynamic());
  sync_generator1_test_none_multi.Range = class Range extends core.Object {
    new(start, end) {
      this.start = start;
      this.end = end;
    }
    elements() {
      return dart.syncStar((function*() {
        let e = this.start;
        while (dart.notNull(e) <= dart.notNull(this.end)) {
          let x = e;
          e = dart.notNull(x) + 1;
          yield x;
        }
      }).bind(this), dart.dynamic);
    }
    get yield() {
      return dart.syncStar((function*() {
        let e = this.start;
        while (dart.notNull(e) <= dart.notNull(this.end)) {
          let x = e;
          e = dart.notNull(x) + 1;
          yield x;
        }
      }).bind(this), dart.dynamic);
    }
  };
  dart.setSignature(sync_generator1_test_none_multi.Range, {
    constructors: () => ({new: dart.definiteFunctionType(sync_generator1_test_none_multi.Range, [core.int, core.int])}),
    methods: () => ({elements: dart.definiteFunctionType(dart.dynamic, [])})
  });
  dart.copyProperties(sync_generator1_test_none_multi, {
    get sync() {
      return dart.syncStar(function*() {
        yield "sync";
      }, dart.dynamic);
    }
  });
  sync_generator1_test_none_multi.einsZwei = function() {
    return dart.syncStar(function*() {
      yield 1;
      yield* JSArrayOfint().of([2, 3]);
      yield* [];
      yield 5;
      yield JSArrayOfint().of([6]);
    }, dart.dynamic);
  };
  dart.fn(sync_generator1_test_none_multi.einsZwei, VoidTodynamic());
  sync_generator1_test_none_multi.dreiVier = function() {
    return dart.syncStar(function*() {
    }, dart.dynamic);
  };
  dart.fn(sync_generator1_test_none_multi.dreiVier, VoidTodynamic());
  sync_generator1_test_none_multi.main = function() {
    for (let i = 0; i < 10; i++) {
      let sums = sync_generator1_test_none_multi.sum10();
      core.print(sums);
      expect$.Expect.isTrue(core.Iterable.is(sums));
      expect$.Expect.equals(10, dart.dload(sums, 'length'));
      expect$.Expect.equals(1, dart.dload(sums, 'first'));
      expect$.Expect.equals(55, dart.dload(sums, 'last'));
      let q = "";
      for (let n of core.Iterable._check(dart.dsend(sums, 'take', 3))) {
        q = q + dart.str`${n} `;
      }
      expect$.Expect.equals("1 3 6 ", q);
      let r = new sync_generator1_test_none_multi.Range(10, 12);
      let elems1 = r.elements();
      core.print(elems1);
      let elems2 = r.yield;
      core.print(elems2);
      let i = dart.dload(elems1, 'iterator');
      expect$.Expect.isTrue(core.Iterator.is(i));
      dart.dsend(elems2, 'forEach', dart.fn(e => {
        expect$.Expect.isTrue(dart.dsend(i, 'moveNext'));
        expect$.Expect.equals(e, dart.dload(i, 'current'));
      }, dynamicTodynamic()));
      core.print(sync_generator1_test_none_multi.sync);
      expect$.Expect.equals("sync", dart.dload(sync_generator1_test_none_multi.sync, 'single'));
      core.print(sync_generator1_test_none_multi.einsZwei());
      expect$.Expect.equals("(1, 2, 3, 5, [6])", dart.toString(sync_generator1_test_none_multi.einsZwei()));
    }
  };
  dart.fn(sync_generator1_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.sync_generator1_test_none_multi = sync_generator1_test_none_multi;
});
