dart_library.library('language/reg_ex2_test', null, /* Imports */[
  'dart_sdk'
], function load__reg_ex2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const reg_ex2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_ex2_test.RegEx2Test = class RegEx2Test extends core.Object {
    static testMain() {
      let helloPattern = core.RegExp.new("with (hello)");
      let s = "this is a string with hello somewhere";
      let match = helloPattern.firstMatch(s);
      if (match != null) {
        core.print("got match");
        let groupCount = match.groupCount;
        core.print(dart.str`groupCount is ${groupCount}`);
        core.print(dart.str`group 0 is ${match.group(0)}`);
        core.print(dart.str`group 1 is ${match.group(1)}`);
      } else {
        core.print("match not round");
      }
      core.print("done");
    }
  };
  dart.setSignature(reg_ex2_test.RegEx2Test, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  reg_ex2_test.main = function() {
    reg_ex2_test.RegEx2Test.testMain();
  };
  dart.fn(reg_ex2_test.main, VoidTodynamic());
  // Exports:
  exports.reg_ex2_test = reg_ex2_test;
});
