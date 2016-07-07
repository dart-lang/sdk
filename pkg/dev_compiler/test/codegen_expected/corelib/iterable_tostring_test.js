dart_library.library('corelib/iterable_tostring_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_tostring_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_tostring_test = Object.create(null);
  let intTodynamic = () => (intTodynamic = dart.constFn(dart.functionType(dart.dynamic, [core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let int__ToString = () => (int__ToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int], [dart.dynamic])))();
  let dynamicToString = () => (dynamicToString = dart.constFn(dart.definiteFunctionType(core.String, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  iterable_tostring_test.mkIt = function(len, func) {
    if (func === void 0) func = null;
    let list = null;
    if (func == null) {
      list = core.List.generate(len, dart.fn(x => x, intToint()));
    } else {
      list = core.List.generate(len, intTodynamic()._check(func));
    }
    return new iterable_tostring_test.MyIterable(core.Iterable._check(list)).toString();
  };
  dart.fn(iterable_tostring_test.mkIt, int__ToString());
  const _base = Symbol('_base');
  iterable_tostring_test.MyIterable = class MyIterable extends collection.IterableBase {
    new(base) {
      this[_base] = base;
      super.new();
    }
    get iterator() {
      return this[_base][dartx.iterator];
    }
  };
  dart.addSimpleTypeTests(iterable_tostring_test.MyIterable);
  dart.setSignature(iterable_tostring_test.MyIterable, {
    constructors: () => ({new: dart.definiteFunctionType(iterable_tostring_test.MyIterable, [core.Iterable])})
  });
  dart.defineExtensionMembers(iterable_tostring_test.MyIterable, ['iterator']);
  iterable_tostring_test.main = function() {
    expect$.Expect.equals("()", iterable_tostring_test.mkIt(0));
    expect$.Expect.equals("(0)", iterable_tostring_test.mkIt(1));
    expect$.Expect.equals("(0, 1)", iterable_tostring_test.mkIt(2));
    expect$.Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8)", iterable_tostring_test.mkIt(9));
    expect$.Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1" + "2, 13, 14, 15, 16, 17, 18, ..., 98, 99)", iterable_tostring_test.mkIt(100));
    expect$.Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1" + "2, 13, 14, 15, 16, 17, 18)", iterable_tostring_test.mkIt(19));
    expect$.Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1" + "2, 13, 14, 15, 16, 17, 18, 19)", iterable_tostring_test.mkIt(20));
    expect$.Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1" + "2, 13, 14, 15, 16, 17, 18, 19, 20)", iterable_tostring_test.mkIt(21));
    expect$.Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1" + "2, 13, 14, 15, 16, 17, 18, 19, 20, ...)", iterable_tostring_test.mkIt(101));
    expect$.Expect.equals("(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 1" + "2, 13, ..., 18, xxxxxxxxxxxxxxxxxxxx)", iterable_tostring_test.mkIt(20, dart.fn(x => dart.equals(x, 19) ? "xxxxxxxxxxxxxxxxxxxx" : dart.str`${x}`, dynamicToString())));
    expect$.Expect.equals("(xxxxxxxxxxxxxxxxx, xxxxxxxxxxxxxxxxx, x" + "xxxxxxxxxxxxxxxx, ..., 18, xxxxxxxxxxxxx" + "xxxx)", iterable_tostring_test.mkIt(20, dart.fn(x => dart.test(dart.dsend(x, '<', 3)) || dart.equals(x, 19) ? "xxxxxxxxxxxxxxxxx" : dart.str`${x}`, dynamicToString())));
    expect$.Expect.equals("(xxxxxxxxxxxxxxxxx, xxxxxxxxxxxxxxxxx, x" + "xxxxxxxxxxxxxxxx, ..., xxxxxxxxxxxxxxxxx" + ", 19)", iterable_tostring_test.mkIt(20, dart.fn(x => dart.test(dart.dsend(x, '<', 3)) || dart.equals(x, 18) ? "xxxxxxxxxxxxxxxxx" : dart.str`${x}`, dynamicToString())));
    expect$.Expect.equals("(xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx," + " xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx," + " xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx," + " ..., 98, 99)", iterable_tostring_test.mkIt(100, dart.fn(x => dart.test(dart.dsend(x, '<', 3)) ? "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" : dart.str`${x}`, dynamicToString())));
    expect$.Expect.equals("(, , , , , , , , , , , , , , , , , , , ," + " , , , , , , , , , , , , , , , ..., , )", iterable_tostring_test.mkIt(100, dart.fn(_ => "", dynamicToString())));
  };
  dart.fn(iterable_tostring_test.main, VoidTovoid());
  // Exports:
  exports.iterable_tostring_test = iterable_tostring_test;
});
