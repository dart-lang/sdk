dart_library.library('language/top_level_func_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__top_level_func_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const top_level_func_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  let ListOfintToint = () => (ListOfintToint = dart.constFn(dart.definiteFunctionType(core.int, [ListOfint()])))();
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  top_level_func_test.TopLevelFuncTest = class TopLevelFuncTest extends core.Object {
    static testMain() {
      let z = JSArrayOfint().of([1, 10, 100, 1000]);
      expect$.Expect.equals(top_level_func_test.Sum(z), 1111);
      let w = top_level_func_test.Window;
      expect$.Expect.equals(w, "window");
      expect$.Expect.equals(null, top_level_func_test.rgb);
      top_level_func_test.Color = "ff0000";
      expect$.Expect.equals(top_level_func_test.rgb, "#ff0000");
      top_level_func_test.CheckColor("#ff0000");
      expect$.Expect.equals("5", top_level_func_test.digits[dartx.get](5));
      let e1 = top_level_func_test.Enumerator;
      let e2 = top_level_func_test.Enumerator;
      expect$.Expect.equals(0, dart.dcall(e1));
      expect$.Expect.equals(1, dart.dcall(e1));
      expect$.Expect.equals(2, dart.dcall(e1));
      expect$.Expect.equals(0, dart.dcall(e2));
    }
  };
  dart.setSignature(top_level_func_test.TopLevelFuncTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  top_level_func_test.CheckColor = function(expected) {
    expect$.Expect.equals(expected, top_level_func_test.rgb);
  };
  dart.fn(top_level_func_test.CheckColor, StringTovoid());
  top_level_func_test.Sum = function(v) {
    let s = 0;
    for (let i = 0; i < dart.notNull(v[dartx.length]); i++) {
      s = dart.notNull(s) + dart.notNull(v[dartx.get](i));
    }
    return s;
  };
  dart.fn(top_level_func_test.Sum, ListOfintToint());
  dart.copyProperties(top_level_func_test, {
    get Window() {
      return "win" + "dow";
    }
  });
  top_level_func_test.rgb = null;
  dart.copyProperties(top_level_func_test, {
    set Color(col) {
      top_level_func_test.rgb = dart.str`#${col}`;
    }
  });
  dart.copyProperties(top_level_func_test, {
    get digits() {
      return JSArrayOfString().of(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
    }
  });
  dart.copyProperties(top_level_func_test, {
    get Enumerator() {
      let k = 0;
      return dart.fn(() => k++, VoidToint());
    }
  });
  top_level_func_test.main = function() {
    top_level_func_test.TopLevelFuncTest.testMain();
  };
  dart.fn(top_level_func_test.main, VoidTodynamic());
  // Exports:
  exports.top_level_func_test = top_level_func_test;
});
