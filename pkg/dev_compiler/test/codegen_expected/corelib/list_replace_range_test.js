dart_library.library('corelib/list_replace_range_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_replace_range_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_replace_range_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let IterableOfint = () => (IterableOfint = dart.constFn(core.Iterable$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListAndintAndint__Todynamic = () => (ListAndintAndint__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List, core.int, core.int, core.Iterable])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  list_replace_range_test.test = function(list, start, end, iterable) {
    let copy = list[dartx.toList]();
    list[dartx.replaceRange](start, end, iterable);
    let iterableList = iterable[dartx.toList]();
    expect$.Expect.equals(dart.notNull(copy[dartx.length]) + dart.notNull(iterableList[dartx.length]) - (dart.notNull(end) - dart.notNull(start)), list[dartx.length]);
    for (let i = 0; i < dart.notNull(start); i++) {
      expect$.Expect.equals(copy[dartx.get](i), list[dartx.get](i));
    }
    for (let i = 0; i < dart.notNull(iterableList[dartx.length]); i++) {
      expect$.Expect.equals(iterableList[dartx.get](i), list[dartx.get](i + dart.notNull(start)));
    }
    let removedLength = dart.notNull(end) - dart.notNull(start);
    for (let i = end; dart.notNull(i) < dart.notNull(copy[dartx.length]); i = dart.notNull(i) + 1) {
      expect$.Expect.equals(copy[dartx.get](i), list[dartx.get](dart.notNull(i) + dart.notNull(iterableList[dartx.length]) - removedLength));
    }
  };
  dart.fn(list_replace_range_test.test, ListAndintAndint__Todynamic());
  list_replace_range_test.MyList = class MyList extends collection.ListBase {
    new(list) {
      this.list = list;
    }
    get length() {
      return this.list[dartx.length];
    }
    set length(value) {
      this.list[dartx.length] = value;
    }
    get(index) {
      return this.list[dartx.get](index);
    }
    set(index, val) {
      this.list[dartx.set](index, val);
      return val;
    }
    toString() {
      return dart.toString(this.list);
    }
  };
  dart.addSimpleTypeTests(list_replace_range_test.MyList);
  dart.setSignature(list_replace_range_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(list_replace_range_test.MyList, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_replace_range_test.MyList, [
    'get',
    'set',
    'toString',
    'length',
    'length'
  ]);
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  let const$6;
  let const$7;
  let const$8;
  let const$9;
  let const$10;
  let const$11;
  let const$12;
  let const$13;
  let const$14;
  let const$15;
  let const$16;
  let const$17;
  list_replace_range_test.main = function() {
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 1, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 1, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 3, 3, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 3, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, JSArrayOfint().of([4]));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 3, []);
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 1, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 1, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 3, 3, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 3, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, JSArrayOfint().of([4])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 3, [][dartx.map](dart.dynamic)(dart.fn(x => x, dynamicTodynamic())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 1, const$ || (const$ = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 1, const$0 || (const$0 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, const$1 || (const$1 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 3, 3, const$2 || (const$2 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 3, const$3 || (const$3 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, const$4 || (const$4 = dart.constList([4], core.int)));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 3, const$5 || (const$5 = dart.constList([], dart.dynamic)));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 1, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 1, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 3, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 1, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 1, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, 3, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 3, JSArrayOfint().of([4, 5]));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, JSArrayOfint().of([4]));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 3, []);
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 1, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 1, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, 3, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 3, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, JSArrayOfint().of([4])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 3, [][dartx.map](dart.dynamic)(dart.fn(x => x, dynamicTodynamic())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 1, const$6 || (const$6 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 1, const$7 || (const$7 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, const$8 || (const$8 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, 3, const$9 || (const$9 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 3, const$10 || (const$10 = dart.constList([4, 5], core.int)));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, const$11 || (const$11 = dart.constList([4], core.int)));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 3, const$12 || (const$12 = dart.constList([], dart.dynamic)));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 1, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 1, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 3, IterableOfint().generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), -1, 0, []), VoidTodynamic()));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 2, 1, []), VoidTodynamic()));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 0, -1, []), VoidTodynamic()));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3]), 1, 4, []), VoidTodynamic()));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), -1, 0, []), VoidTodynamic()));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, 1, []), VoidTodynamic()));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, -1, []), VoidTodynamic()));
    list_replace_range_test.expectRE(dart.fn(() => list_replace_range_test.test(new list_replace_range_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, 4, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 2, 3, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), -1, 0, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 2, 1, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 0, -1, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, 4, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(const$13 || (const$13 = dart.constList([1, 2, 3], core.int)), 2, 3, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(const$14 || (const$14 = dart.constList([1, 2, 3], core.int)), -1, 0, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(const$15 || (const$15 = dart.constList([1, 2, 3], core.int)), 2, 1, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(const$16 || (const$16 = dart.constList([1, 2, 3], core.int)), 0, -1, []), VoidTodynamic()));
    list_replace_range_test.expectUE(dart.fn(() => list_replace_range_test.test(const$17 || (const$17 = dart.constList([1, 2, 3], core.int)), 1, 4, []), VoidTodynamic()));
  };
  dart.fn(list_replace_range_test.main, VoidTodynamic());
  list_replace_range_test.expectRE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(list_replace_range_test.expectRE, FunctionTovoid());
  list_replace_range_test.expectUE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(list_replace_range_test.expectUE, FunctionTovoid());
  // Exports:
  exports.list_replace_range_test = list_replace_range_test;
});
