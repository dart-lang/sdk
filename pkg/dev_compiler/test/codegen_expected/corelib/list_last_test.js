dart_library.library('corelib/list_last_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_last_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_last_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  list_last_test.test = function(list) {
    if (dart.test(list[dartx.isEmpty])) {
      expect$.Expect.throws(dart.fn(() => list[dartx.last], VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    } else {
      expect$.Expect.equals(list[dartx.get](dart.notNull(list[dartx.length]) - 1), list[dartx.last]);
    }
  };
  dart.fn(list_last_test.test, ListTovoid());
  let const$;
  let const$0;
  list_last_test.main = function() {
    list_last_test.test(JSArrayOfint().of([1, 2, 3]));
    list_last_test.test(const$ || (const$ = dart.constList(["foo", "bar"], core.String)));
    list_last_test.test([]);
    list_last_test.test(const$0 || (const$0 = dart.constList([], dart.dynamic)));
  };
  dart.fn(list_last_test.main, VoidTodynamic());
  // Exports:
  exports.list_last_test = list_last_test;
});
