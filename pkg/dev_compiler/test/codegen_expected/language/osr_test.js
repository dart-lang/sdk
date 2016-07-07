dart_library.library('language/osr_test', null, /* Imports */[
  'dart_sdk'
], function load__osr_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const osr_test = Object.create(null);
  let MyList = () => (MyList = dart.constFn(osr_test.MyList$()))();
  let __ToList = () => (__ToList = dart.constFn(dart.functionType(core.List, [], [core.int])))();
  let __ToList$ = () => (__ToList$ = dart.constFn(dart.definiteFunctionType(core.List, [], [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let FnTodynamic = () => (FnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [__ToList()])))();
  let dynamicAnddynamicToint = () => (dynamicAnddynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic, dart.dynamic])))();
  let intAndintTovoid = () => (intAndintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  osr_test.create = function(length) {
    if (length === void 0) length = null;
    return new osr_test.MyList(length);
  };
  dart.fn(osr_test.create, __ToList$());
  osr_test.main = function() {
    osr_test.test(osr_test.create);
  };
  dart.fn(osr_test.main, VoidTodynamic());
  const _list = Symbol('_list');
  osr_test.MyList$ = dart.generic(E => {
    let ListOfE = () => (ListOfE = dart.constFn(core.List$(E)))();
    class MyList extends collection.ListBase$(E) {
      new(length) {
        if (length === void 0) length = null;
        this[_list] = length == null ? ListOfE().new() : ListOfE().new(length);
      }
      get(index) {
        return this[_list][dartx.get](index);
      }
      set(index, value) {
        E._check(value);
        this[_list][dartx.set](index, value);
        return value;
      }
      get length() {
        return this[_list][dartx.length];
      }
      set length(newLength) {
        this[_list][dartx.length] = newLength;
      }
    }
    dart.setSignature(MyList, {
      constructors: () => ({new: dart.definiteFunctionType(osr_test.MyList$(E), [], [core.int])}),
      methods: () => ({
        get: dart.definiteFunctionType(E, [core.int]),
        set: dart.definiteFunctionType(dart.void, [core.int, E])
      })
    });
    dart.defineExtensionMembers(MyList, ['get', 'set', 'length', 'length']);
    return MyList;
  });
  osr_test.MyList = MyList();
  osr_test.test = function(create) {
    osr_test.sort_A01_t02_test(create);
  };
  dart.fn(osr_test.test, FnTodynamic());
  osr_test.sort_A01_t02_test = function(create) {
    function c(a, b) {
      return dart.test(dart.dsend(a, '<', b)) ? -1 : dart.equals(a, b) ? 0 : 1;
    }
    dart.fn(c, dynamicAnddynamicToint());
    let maxlen = 7;
    let prevLength = 0;
    for (let length = 1; length < maxlen; ++length) {
      if (prevLength == length) {
        dart.throw("No progress made");
      }
      prevLength = length;
      let a = create(length);
      let expected = create(length);
      for (let i = 0; i < length; ++i) {
        expected[dartx.set](i, i);
        a[dartx.set](i, i);
      }
      function swap(i, j) {
        let t = a[dartx.get](i);
        a[dartx.set](i, a[dartx.get](j));
        a[dartx.set](j, t);
      }
      dart.fn(swap, intAndintTovoid());
      function check() {
        return;
        let a_copy = core.List.new(length);
        a_copy[dartx.setRange](0, length, a);
        a_copy[dartx.sort](c);
      }
      dart.fn(check, VoidTovoid());
      function permute(n) {
        if (n == 1) {
          check();
        } else {
          for (let i = 0; i < dart.notNull(n); i++) {
            permute(dart.notNull(n) - 1);
            if (n[dartx['%']](2) == 1) {
              swap(0, dart.notNull(n) - 1);
            } else {
              swap(i, dart.notNull(n) - 1);
            }
          }
        }
      }
      dart.fn(permute, intTovoid());
      permute(length);
    }
  };
  dart.fn(osr_test.sort_A01_t02_test, FnTodynamic());
  // Exports:
  exports.osr_test = osr_test;
});
