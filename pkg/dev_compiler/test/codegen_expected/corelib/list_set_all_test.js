dart_library.library('corelib/list_set_all_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_set_all_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_set_all_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListAndintAndIterableTodynamic = () => (ListAndintAndIterableTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List, core.int, core.Iterable])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let FunctionTovoid = () => (FunctionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Function])))();
  list_set_all_test.test = function(list, index, iterable) {
    let copy = list[dartx.toList]();
    list[dartx.setAll](index, iterable);
    expect$.Expect.equals(copy[dartx.length], list[dartx.length]);
    for (let i = 0; i < dart.notNull(index); i++) {
      expect$.Expect.equals(copy[dartx.get](i), list[dartx.get](i));
    }
    let iterableList = iterable[dartx.toList]();
    for (let i = 0; i < dart.notNull(iterableList[dartx.length]); i++) {
      expect$.Expect.equals(iterableList[dartx.get](i), list[dartx.get](i + dart.notNull(index)));
    }
    for (let i = dart.notNull(index) + dart.notNull(iterableList[dartx.length]); i < dart.notNull(copy[dartx.length]); i++) {
      expect$.Expect.equals(copy[dartx.get](i), list[dartx.get](i));
    }
  };
  dart.fn(list_set_all_test.test, ListAndintAndIterableTodynamic());
  list_set_all_test.MyList = class MyList extends collection.ListBase {
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
  dart.addSimpleTypeTests(list_set_all_test.MyList);
  dart.setSignature(list_set_all_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(list_set_all_test.MyList, [core.List])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_set_all_test.MyList, [
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
  list_set_all_test.main = function() {
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 0, JSArrayOfint().of([4, 5]));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 1, JSArrayOfint().of([4, 5]));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 2, JSArrayOfint().of([4]));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 3, []);
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 0, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 1, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 2, JSArrayOfint().of([4])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 3, [][dartx.map](dart.dynamic)(dart.fn(x => x, dynamicTodynamic())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 0, const$ || (const$ = dart.constList([4, 5], core.int)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 1, const$0 || (const$0 = dart.constList([4, 5], core.int)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 2, const$1 || (const$1 = dart.constList([4], core.int)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 3, const$2 || (const$2 = dart.constList([], dart.dynamic)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 0, core.Iterable.generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 1, core.Iterable.generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 2, core.Iterable.generate(1, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 3, core.Iterable.generate(0, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 0, JSArrayOfint().of([4, 5]));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, JSArrayOfint().of([4, 5]));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 2, JSArrayOfint().of([4]));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 3, []);
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 0, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 2, JSArrayOfint().of([4])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 3, [][dartx.map](dart.dynamic)(dart.fn(x => x, dynamicTodynamic())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 0, const$3 || (const$3 = dart.constList([4, 5], core.int)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, const$4 || (const$4 = dart.constList([4, 5], core.int)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 2, const$5 || (const$5 = dart.constList([4], core.int)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 3, const$6 || (const$6 = dart.constList([], dart.dynamic)));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 0, core.Iterable.generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, core.Iterable.generate(2, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 2, core.Iterable.generate(1, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 3, core.Iterable.generate(0, dart.fn(x => dart.notNull(x) + 4, intToint())));
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, JSArrayOfint().of([4, 5]));
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, JSArrayOfint().of([4, 5]));
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, JSArrayOfint().of([4]));
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, []);
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 0, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, JSArrayOfint().of([4, 5])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 2, JSArrayOfint().of([4])[dartx.map](core.int)(dart.fn(x => x, intToint())));
    list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 3, [][dartx.map](dart.dynamic)(dart.fn(x => x, dynamicTodynamic())));
    list_set_all_test.expectRE(dart.fn(() => list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), -1, JSArrayOfint().of([4, 5])), VoidTodynamic()));
    list_set_all_test.expectRE(dart.fn(() => list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), -1, JSArrayOfint().of([4, 5])), VoidTodynamic()));
    list_set_all_test.expectRE(dart.fn(() => list_set_all_test.test(JSArrayOfint().of([1, 2, 3]), 1, JSArrayOfint().of([4, 5, 6])), VoidTodynamic()));
    list_set_all_test.expectRE(dart.fn(() => list_set_all_test.test(JSArrayOfint().of([1, 2, 3])[dartx.toList]({growable: false}), 1, JSArrayOfint().of([4, 5, 6])), VoidTodynamic()));
    list_set_all_test.expectRE(dart.fn(() => list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), -1, JSArrayOfint().of([4, 5])), VoidTodynamic()));
    list_set_all_test.expectRE(dart.fn(() => list_set_all_test.test(new list_set_all_test.MyList(JSArrayOfint().of([1, 2, 3])), 1, JSArrayOfint().of([4, 5, 6])), VoidTodynamic()));
    list_set_all_test.expectUE(dart.fn(() => list_set_all_test.test(const$7 || (const$7 = dart.constList([1, 2, 3], core.int)), 0, JSArrayOfint().of([4, 5])), VoidTodynamic()));
    list_set_all_test.expectUE(dart.fn(() => list_set_all_test.test(const$8 || (const$8 = dart.constList([1, 2, 3], core.int)), -1, JSArrayOfint().of([4, 5])), VoidTodynamic()));
    list_set_all_test.expectUE(dart.fn(() => list_set_all_test.test(const$9 || (const$9 = dart.constList([1, 2, 3], core.int)), 1, JSArrayOfint().of([4, 5, 6])), VoidTodynamic()));
  };
  dart.fn(list_set_all_test.main, VoidTodynamic());
  list_set_all_test.expectRE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.RangeError.is(e), dynamicTobool()));
  };
  dart.fn(list_set_all_test.expectRE, FunctionTovoid());
  list_set_all_test.expectUE = function(f) {
    expect$.Expect.throws(VoidTovoid()._check(f), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(list_set_all_test.expectUE, FunctionTovoid());
  // Exports:
  exports.list_set_all_test = list_set_all_test;
});
