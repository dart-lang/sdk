dart_library.library('corelib/strings_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__strings_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const strings_test = Object.create(null);
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  strings_test.StringsTest = class StringsTest extends core.Object {
    new() {
    }
    toString() {
      return "Strings Tester";
    }
    static testCreation() {
      let s = "Hello";
      let l = ListOfint().new(s[dartx.length]);
      for (let i = 0; i < dart.notNull(l[dartx.length]); i++) {
        l[dartx.set](i, s[dartx.codeUnitAt](i));
      }
      let s2 = core.String.fromCharCodes(l);
      expect$.Expect.equals(s, s2);
    }
    static testMain() {
      strings_test.StringsTest.testCreation();
    }
  };
  dart.setSignature(strings_test.StringsTest, {
    constructors: () => ({new: dart.definiteFunctionType(strings_test.StringsTest, [])}),
    statics: () => ({
      testCreation: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['testCreation', 'testMain']
  });
  strings_test.main = function() {
    strings_test.StringsTest.testMain();
  };
  dart.fn(strings_test.main, VoidTodynamic());
  // Exports:
  exports.strings_test = strings_test;
});
