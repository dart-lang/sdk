dart_library.library('corelib/iterable_join_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__iterable_join_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const iterable_join_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfIC = () => (JSArrayOfIC = dart.constFn(_interceptors.JSArray$(iterable_join_test.IC)))();
  let JSArrayOfStringable = () => (JSArrayOfStringable = dart.constFn(_interceptors.JSArray$(iterable_join_test.Stringable)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let StringAndIterable__Todynamic = () => (StringAndIterable__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.Iterable], [core.String])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let ICToIC = () => (ICToIC = dart.constFn(dart.definiteFunctionType(iterable_join_test.IC, [iterable_join_test.IC])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let intToString = () => (intToString = dart.constFn(dart.definiteFunctionType(core.String, [core.int])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  iterable_join_test.IC = class IC extends core.Object {
    new() {
      this.count = 0;
    }
    toString() {
      return dart.str`${(() => {
        let x = this.count;
        this.count = dart.notNull(x) + 1;
        return x;
      })()}`;
    }
  };
  iterable_join_test.testJoin = function(expect, iterable, separator) {
    if (separator === void 0) separator = null;
    if (separator != null) {
      expect$.Expect.equals(expect, iterable[dartx.join](separator));
    } else {
      expect$.Expect.equals(expect, iterable[dartx.join]());
    }
  };
  dart.fn(iterable_join_test.testJoin, StringAndIterable__Todynamic());
  let const$;
  iterable_join_test.testCollections = function() {
    iterable_join_test.testJoin("", [], ",");
    iterable_join_test.testJoin("", [], "");
    iterable_join_test.testJoin("", []);
    iterable_join_test.testJoin("", core.Set.new(), ",");
    iterable_join_test.testJoin("", core.Set.new(), "");
    iterable_join_test.testJoin("", core.Set.new());
    iterable_join_test.testJoin("42", JSArrayOfint().of([42]), ",");
    iterable_join_test.testJoin("42", JSArrayOfint().of([42]), "");
    iterable_join_test.testJoin("42", JSArrayOfint().of([42]));
    iterable_join_test.testJoin("42", (() => {
      let _ = core.Set.new();
      _.add(42);
      return _;
    })(), ",");
    iterable_join_test.testJoin("42", (() => {
      let _ = core.Set.new();
      _.add(42);
      return _;
    })(), "");
    iterable_join_test.testJoin("42", (() => {
      let _ = core.Set.new();
      _.add(42);
      return _;
    })());
    iterable_join_test.testJoin("a,b,c,d", JSArrayOfString().of(["a", "b", "c", "d"]), ",");
    iterable_join_test.testJoin("abcd", JSArrayOfString().of(["a", "b", "c", "d"]), "");
    iterable_join_test.testJoin("abcd", JSArrayOfString().of(["a", "b", "c", "d"]));
    iterable_join_test.testJoin("null,b,c,d", JSArrayOfString().of([null, "b", "c", "d"]), ",");
    iterable_join_test.testJoin("1,2,3,4", JSArrayOfint().of([1, 2, 3, 4]), ",");
    let ic = new iterable_join_test.IC();
    iterable_join_test.testJoin("0,1,2,3", JSArrayOfIC().of([ic, ic, ic, ic]), ",");
    let set = core.Set.new();
    set.add(1);
    set.add(2);
    set.add(3);
    let perm = core.Set.new();
    perm.add("123");
    perm.add("132");
    perm.add("213");
    perm.add("231");
    perm.add("312");
    perm.add("321");
    let setString = set.join();
    expect$.Expect.isTrue(perm.contains(setString), dart.str`set: ${setString}`);
    function testArray(array) {
      iterable_join_test.testJoin("1,3,5,7,9", core.Iterable._check(dart.dsend(array, 'where', dart.fn(i => dart.dload(i, 'isOdd'), dynamicTodynamic()))), ",");
      iterable_join_test.testJoin("0,2,4,6,8,10,12,14,16,18", core.Iterable._check(dart.dsend(array, 'map', dart.fn(i => dart.dsend(i, '*', 2), dynamicTodynamic()))), ",");
      iterable_join_test.testJoin("5,6,7,8,9", core.Iterable._check(dart.dsend(array, 'skip', 5)), ",");
      iterable_join_test.testJoin("5,6,7,8,9", core.Iterable._check(dart.dsend(array, 'skipWhile', dart.fn(i => dart.dsend(i, '<', 5), dynamicTodynamic()))), ",");
      iterable_join_test.testJoin("0,1,2,3,4", core.Iterable._check(dart.dsend(array, 'take', 5)), ",");
      iterable_join_test.testJoin("0,1,2,3,4", core.Iterable._check(dart.dsend(array, 'takeWhile', dart.fn(i => dart.dsend(i, '<', 5), dynamicTodynamic()))), ",");
    }
    dart.fn(testArray, dynamicTovoid());
    testArray(JSArrayOfint().of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
    let fixedArray = core.List.new(10);
    for (let i = 0; i < 10; i++) {
      fixedArray[dartx.set](i, i);
    }
    testArray(fixedArray);
    testArray(const$ || (const$ = dart.constList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], core.int)));
    iterable_join_test.testJoin("a,b,c,d", JSArrayOfString().of(["a", "b", "c", "d"])[dartx.map](core.String)(dart.fn(x => x, StringToString())), ",");
    iterable_join_test.testJoin("abcd", JSArrayOfString().of(["a", "b", "c", "d"])[dartx.map](core.String)(dart.fn(x => x, StringToString())), "");
    iterable_join_test.testJoin("abcd", JSArrayOfString().of(["a", "b", "c", "d"])[dartx.map](core.String)(dart.fn(x => x, StringToString())));
    iterable_join_test.testJoin("null,b,c,d", JSArrayOfString().of([null, "b", "c", "d"])[dartx.map](core.String)(dart.fn(x => x, StringToString())), ",");
    iterable_join_test.testJoin("1,2,3,4", JSArrayOfint().of([1, 2, 3, 4])[dartx.map](core.int)(dart.fn(x => x, intToint())), ",");
    iterable_join_test.testJoin("4,5,6,7", JSArrayOfIC().of([ic, ic, ic, ic])[dartx.map](iterable_join_test.IC)(dart.fn(x => x, ICToIC())), ",");
  };
  dart.fn(iterable_join_test.testCollections, VoidTodynamic());
  iterable_join_test.testStringVariants = function() {
    iterable_join_test.testJoin("axbxcxd", JSArrayOfString().of(["a", "b", "c", "d"]), "x");
    iterable_join_test.testJoin("a b c d", JSArrayOfString().of(["a", "b", "c", "d"]), " ");
    iterable_join_test.testJoin("abcd", JSArrayOfString().of(["a", "b", "c", "d"]), "");
    iterable_join_test.testJoin("abcd", JSArrayOfString().of(["a", "b", "c", "d"]));
    iterable_join_test.testJoin("axbxcx ", JSArrayOfString().of(["a", "b", "c", " "]), "x");
    iterable_join_test.testJoin("a b c  ", JSArrayOfString().of(["a", "b", "c", " "]), " ");
    iterable_join_test.testJoin("abc ", JSArrayOfString().of(["a", "b", "c", " "]), "");
    iterable_join_test.testJoin("abc ", JSArrayOfString().of(["a", "b", "c", " "]));
    iterable_join_test.testJoin("ax"[dartx['*']](255) + "a", core.List.generate(256, dart.fn(_ => "a", intToString())), "x");
    iterable_join_test.testJoin("a"[dartx['*']](256), core.List.generate(256, dart.fn(_ => "a", intToString())));
    iterable_join_test.testJoin("a "[dartx['*']](255) + "a", core.List.generate(256, dart.fn(_ => "a", intToString())), " ");
    iterable_join_test.testJoin(" "[dartx['*']](256), core.List.generate(256, dart.fn(_ => " ", intToString())));
    iterable_join_test.testJoin(" x"[dartx['*']](255) + " ", core.List.generate(256, dart.fn(_ => " ", intToString())), "x");
    let o1 = new iterable_join_test.Stringable("x");
    let o2 = new iterable_join_test.Stringable("﻿");
    iterable_join_test.testJoin("xa"[dartx['*']](3) + "x", JSArrayOfStringable().of([o1, o1, o1, o1]), "a");
    iterable_join_test.testJoin("x"[dartx['*']](4), JSArrayOfStringable().of([o1, o1, o1, o1]), "");
    iterable_join_test.testJoin("x"[dartx['*']](4), JSArrayOfStringable().of([o1, o1, o1, o1]));
    iterable_join_test.testJoin("﻿x"[dartx['*']](3) + "﻿", JSArrayOfStringable().of([o2, o2, o2, o2]), "x");
    iterable_join_test.testJoin("﻿"[dartx['*']](4), JSArrayOfStringable().of([o2, o2, o2, o2]), "");
    iterable_join_test.testJoin("﻿"[dartx['*']](4), JSArrayOfStringable().of([o2, o2, o2, o2]));
    iterable_join_test.testJoin("a x﻿", JSArrayOfObject().of(["a", " ", o1, o2]));
    iterable_join_test.testJoin("a ﻿x", JSArrayOfObject().of(["a", " ", o2, o1]));
    iterable_join_test.testJoin("ax ﻿", JSArrayOfObject().of(["a", o1, " ", o2]));
    iterable_join_test.testJoin("ax﻿ ", JSArrayOfObject().of(["a", o1, o2, " "]));
    iterable_join_test.testJoin("a﻿x ", JSArrayOfObject().of(["a", o2, o1, " "]));
    iterable_join_test.testJoin("a﻿ x", JSArrayOfObject().of(["a", o2, " ", o1]));
    iterable_join_test.testJoin(" ax﻿", JSArrayOfObject().of([" ", "a", o1, o2]));
    iterable_join_test.testJoin(" a﻿x", JSArrayOfObject().of([" ", "a", o2, o1]));
    iterable_join_test.testJoin("xa ﻿", JSArrayOfObject().of([o1, "a", " ", o2]));
    iterable_join_test.testJoin("xa﻿ ", JSArrayOfObject().of([o1, "a", o2, " "]));
    iterable_join_test.testJoin("﻿ax ", JSArrayOfObject().of([o2, "a", o1, " "]));
    iterable_join_test.testJoin("﻿a x", JSArrayOfObject().of([o2, "a", " ", o1]));
    iterable_join_test.testJoin(" xa﻿", JSArrayOfObject().of([" ", o1, "a", o2]));
    iterable_join_test.testJoin(" ﻿ax", JSArrayOfObject().of([" ", o2, "a", o1]));
    iterable_join_test.testJoin("x a﻿", JSArrayOfObject().of([o1, " ", "a", o2]));
    iterable_join_test.testJoin("x﻿a ", JSArrayOfObject().of([o1, o2, "a", " "]));
    iterable_join_test.testJoin("﻿xa ", JSArrayOfObject().of([o2, o1, "a", " "]));
    iterable_join_test.testJoin("﻿ ax", JSArrayOfObject().of([o2, " ", "a", o1]));
    iterable_join_test.testJoin(" x﻿a", JSArrayOfObject().of([" ", o1, o2, "a"]));
    iterable_join_test.testJoin(" ﻿xa", JSArrayOfObject().of([" ", o2, o1, "a"]));
    iterable_join_test.testJoin("x ﻿a", JSArrayOfObject().of([o1, " ", o2, "a"]));
    iterable_join_test.testJoin("x﻿ a", JSArrayOfObject().of([o1, o2, " ", "a"]));
    iterable_join_test.testJoin("﻿x a", JSArrayOfObject().of([o2, o1, " ", "a"]));
    iterable_join_test.testJoin("﻿ xa", JSArrayOfObject().of([o2, " ", o1, "a"]));
  };
  dart.fn(iterable_join_test.testStringVariants, VoidTovoid());
  iterable_join_test.Stringable = class Stringable extends core.Object {
    new(value) {
      this.value = value;
    }
    toString() {
      return this.value;
    }
  };
  dart.setSignature(iterable_join_test.Stringable, {
    constructors: () => ({new: dart.definiteFunctionType(iterable_join_test.Stringable, [core.String])})
  });
  iterable_join_test.main = function() {
    iterable_join_test.testCollections();
    iterable_join_test.testStringVariants();
  };
  dart.fn(iterable_join_test.main, VoidTodynamic());
  // Exports:
  exports.iterable_join_test = iterable_join_test;
});
