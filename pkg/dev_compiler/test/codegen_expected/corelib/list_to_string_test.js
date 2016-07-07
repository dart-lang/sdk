dart_library.library('corelib/list_to_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_to_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_to_string_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_to_string_test.MyList = class MyList extends collection.ListBase {
    new(list) {
      this.list = list;
    }
    get length() {
      return core.int._check(dart.dload(this.list, 'length'));
    }
    set length(val) {
      dart.dput(this.list, 'length', val);
    }
    get(index) {
      return dart.dindex(this.list, index);
    }
    set(index, val) {
      (() => {
        return dart.dsetindex(this.list, index, val);
      })();
      return val;
    }
  };
  dart.addSimpleTypeTests(list_to_string_test.MyList);
  dart.setSignature(list_to_string_test.MyList, {
    constructors: () => ({new: dart.definiteFunctionType(list_to_string_test.MyList, [dart.dynamic])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, dart.dynamic])
    })
  });
  dart.defineExtensionMembers(list_to_string_test.MyList, ['get', 'set', 'length', 'length']);
  let const$;
  let const$0;
  let const$1;
  list_to_string_test.main = function() {
    expect$.Expect.equals("[]", dart.toString([]));
    expect$.Expect.equals("[1]", dart.toString(JSArrayOfint().of([1])));
    expect$.Expect.equals("[1, 2]", dart.toString(JSArrayOfint().of([1, 2])));
    expect$.Expect.equals("[]", dart.toString(const$ || (const$ = dart.constList([], dart.dynamic))));
    expect$.Expect.equals("[1]", dart.toString(const$0 || (const$0 = dart.constList([1], core.int))));
    expect$.Expect.equals("[1, 2]", dart.toString(const$1 || (const$1 = dart.constList([1, 2], core.int))));
    expect$.Expect.equals("[]", new list_to_string_test.MyList([]).toString());
    expect$.Expect.equals("[1]", new list_to_string_test.MyList(JSArrayOfint().of([1])).toString());
    expect$.Expect.equals("[1, 2]", new list_to_string_test.MyList(JSArrayOfint().of([1, 2])).toString());
  };
  dart.fn(list_to_string_test.main, VoidTodynamic());
  // Exports:
  exports.list_to_string_test = list_to_string_test;
});
