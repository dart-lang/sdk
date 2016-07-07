dart_library.library('corelib/list_index_of_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_index_of_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_index_of_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListOfintTovoid = () => (ListOfintTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [ListOfint()])))();
  list_index_of_test.main = function() {
    list_index_of_test.test(ListOfint().new(5));
    let l = ListOfint().new();
    l[dartx.length] = 5;
    list_index_of_test.test(l);
  };
  dart.fn(list_index_of_test.main, VoidTodynamic());
  list_index_of_test.test = function(list) {
    list[dartx.set](0, 1);
    list[dartx.set](1, 2);
    list[dartx.set](2, 3);
    list[dartx.set](3, 4);
    list[dartx.set](4, 1);
    expect$.Expect.equals(3, list[dartx.indexOf](4, 0));
    expect$.Expect.equals(0, list[dartx.indexOf](1, 0));
    expect$.Expect.equals(4, list[dartx.lastIndexOf](1, dart.notNull(list[dartx.length]) - 1));
    expect$.Expect.equals(4, list[dartx.indexOf](1, 1));
    expect$.Expect.equals(-1, list[dartx.lastIndexOf](4, 2));
    expect$.Expect.equals(3, list[dartx.indexOf](4, 2));
    expect$.Expect.equals(3, list[dartx.indexOf](4, -5));
    expect$.Expect.equals(-1, list[dartx.indexOf](4, 50));
    expect$.Expect.equals(-1, list[dartx.lastIndexOf](4, 2));
    expect$.Expect.equals(-1, list[dartx.lastIndexOf](4, -5));
    expect$.Expect.equals(3, list[dartx.lastIndexOf](4, 50));
  };
  dart.fn(list_index_of_test.test, ListOfintTovoid());
  // Exports:
  exports.list_index_of_test = list_index_of_test;
});
