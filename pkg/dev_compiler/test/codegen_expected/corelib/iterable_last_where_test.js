dart_library.library('corelib/iterable_last_where_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_last_where_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_last_where_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let intTobool = () => (intTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.int])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringTobool = () => (StringTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.String])))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  iterable_last_where_test.main = function() {
    let list1 = JSArrayOfint().of([1, 2, 3]);
    let list2 = const$ || (const$ = dart.constList([4, 5, 6], core.int));
    let list3 = JSArrayOfString().of([]);
    let set1 = SetOfint().new();
    set1.add(11);
    set1.add(12);
    set1.add(13);
    let set2 = core.Set.new();
    expect$.Expect.equals(2, list1[dartx.lastWhere](dart.fn(x => x[dartx.isEven], intTobool())));
    expect$.Expect.equals(3, list1[dartx.lastWhere](dart.fn(x => x[dartx.isOdd], intTobool())));
    expect$.Expect.throws(dart.fn(() => list1[dartx.lastWhere](dart.fn(x => dart.notNull(x) > 3, intTobool())), VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(null, list1[dartx.lastWhere](dart.fn(x => dart.notNull(x) > 3, intTobool()), {orElse: dart.fn(() => null, VoidToint())}));
    expect$.Expect.equals(499, list1[dartx.lastWhere](dart.fn(x => dart.notNull(x) > 3, intTobool()), {orElse: dart.fn(() => 499, VoidToint())}));
    expect$.Expect.equals(6, list2[dartx.lastWhere](dart.fn(x => x[dartx.isEven], intTobool())));
    expect$.Expect.equals(5, list2[dartx.lastWhere](dart.fn(x => x[dartx.isOdd], intTobool())));
    expect$.Expect.throws(dart.fn(() => list2[dartx.lastWhere](dart.fn(x => x == 0, intTobool())), VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(null, list2[dartx.lastWhere](dart.fn(x => false, intTobool()), {orElse: dart.fn(() => null, VoidToint())}));
    expect$.Expect.equals(499, list2[dartx.lastWhere](dart.fn(x => false, intTobool()), {orElse: dart.fn(() => 499, VoidToint())}));
    expect$.Expect.throws(dart.fn(() => list3[dartx.lastWhere](dart.fn(x => dart.equals(x, 0), StringTobool())), VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => list3[dartx.lastWhere](dart.fn(x => true, StringTobool())), VoidToString()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(null, list3[dartx.lastWhere](dart.fn(x => true, StringTobool()), {orElse: dart.fn(() => null, VoidToString())}));
    expect$.Expect.equals("str", list3[dartx.lastWhere](dart.fn(x => false, StringTobool()), {orElse: dart.fn(() => "str", VoidToString())}));
    expect$.Expect.equals(12, set1.lastWhere(dart.fn(x => x[dartx.isEven], intTobool())));
    let odd = set1.lastWhere(dart.fn(x => x[dartx.isOdd], intTobool()));
    expect$.Expect.isTrue(odd == 11 || odd == 13);
    expect$.Expect.throws(dart.fn(() => set1.lastWhere(dart.fn(x => false, intTobool())), VoidToint()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(null, set1.lastWhere(dart.fn(x => false, intTobool()), {orElse: dart.fn(() => null, VoidToint())}));
    expect$.Expect.equals(499, set1.lastWhere(dart.fn(x => false, intTobool()), {orElse: dart.fn(() => 499, VoidToint())}));
    expect$.Expect.throws(dart.fn(() => set2.lastWhere(dart.fn(x => false, dynamicTobool())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => set2.lastWhere(dart.fn(x => true, dynamicTobool())), VoidTovoid()), dart.fn(e => core.StateError.is(e), dynamicTobool()));
    expect$.Expect.equals(null, set2.lastWhere(dart.fn(x => true, dynamicTobool()), {orElse: dart.fn(() => null, VoidTodynamic())}));
    expect$.Expect.equals(499, set2.lastWhere(dart.fn(x => false, dynamicTobool()), {orElse: dart.fn(() => 499, VoidToint())}));
  };
  dart.fn(iterable_last_where_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_last_where_test = iterable_last_where_test;
});
