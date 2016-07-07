dart_library.library('language/list_literal3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__list_literal3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const list_literal3_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let ListOfdouble = () => (ListOfdouble = dart.constFn(core.List$(core.double)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let const$;
  let const$0;
  let const$1;
  let const$2;
  let const$3;
  let const$4;
  let const$5;
  list_literal3_test.ListLiteral3Test = class ListLiteral3Test extends core.Object {
    static testMain() {
      let joke = const$ || (const$ = dart.constList(["knock", "knock"], core.String));
      expect$.Expect.identical(joke, list_literal3_test.ListLiteral3Test.canonicalJoke);
      expect$.Expect.identical(joke[dartx.get](0), joke[dartx.get](1));
      expect$.Expect.identical(joke[dartx.get](0), list_literal3_test.ListLiteral3Test.canonicalJoke[dartx.get](0));
      expect$.Expect.throws(dart.fn(() => {
        joke[dartx.set](0, "sock");
      }, VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      expect$.Expect.identical(joke[dartx.get](0), joke[dartx.get](1));
      let lame_joke = JSArrayOfString().of(["knock", "knock"]);
      expect$.Expect.identical(joke[dartx.get](1), lame_joke[dartx.get](1));
      expect$.Expect.equals(false, core.identical(joke, lame_joke));
      lame_joke[dartx.set](1, "who");
      expect$.Expect.identical("who", lame_joke[dartx.get](1));
      let a = const$2 || (const$2 = dart.constList([const$0 || (const$0 = dart.constList([1, 2], core.int)), const$1 || (const$1 = dart.constList([1, 2], core.int))], ListOfint()));
      expect$.Expect.identical(a[dartx.get](0), a[dartx.get](1));
      expect$.Expect.identical(a[dartx.get](0)[dartx.get](0), a[dartx.get](1)[dartx.get](0));
      expect$.Expect.throws(dart.fn(() => {
        a[dartx.get](0)[dartx.set](0, 42);
      }, VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
      let b = const$5 || (const$5 = dart.constList([const$3 || (const$3 = dart.constList([1.0, 2.0], core.double)), const$4 || (const$4 = dart.constList([1.0, 2.0], core.double))], ListOfdouble()));
      expect$.Expect.identical(b[dartx.get](0), b[dartx.get](1));
      expect$.Expect.equals(true, b[dartx.get](0)[dartx.get](0) == 1.0);
      expect$.Expect.identical(b[dartx.get](0)[dartx.get](0), b[dartx.get](1)[dartx.get](0));
      expect$.Expect.throws(dart.fn(() => {
        b[dartx.get](0)[dartx.set](0, 42.0);
      }, VoidTovoid()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    }
  };
  dart.setSignature(list_literal3_test.ListLiteral3Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  list_literal3_test.ListLiteral3Test.canonicalJoke = dart.constList(["knock", "knock"], core.String);
  list_literal3_test.main = function() {
    list_literal3_test.ListLiteral3Test.testMain();
  };
  dart.fn(list_literal3_test.main, VoidTodynamic());
  // Exports:
  exports.list_literal3_test = list_literal3_test;
});
