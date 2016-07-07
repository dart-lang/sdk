dart_library.library('language/reg_exp2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp2_test.RegExp2Test = class RegExp2Test extends core.Object {
    static findImageTag_(text, extensions) {
      let re = core.RegExp.new(dart.str`src="(http://\\S+\\.(${extensions}))"`);
      core.print(dart.str`REGEXP findImageTag_ ${extensions} text: \n${text}`);
      let match = re.firstMatch(text);
      core.print(dart.str`REGEXP findImageTag_ ${extensions} SUCCESS`);
      if (match != null) {
        return match.get(1);
      } else {
        return null;
      }
    }
    static testMain() {
      let text = '<img src="http://cdn.archinect.net/images/514x/c0/c0p3qo202oxp0e6z.jpg" width="514" height="616" border="0" title="" alt=""><em><p>My last entry was in December of 2009. I suppose I never was particularly good about updating this thing, but it seems a bit ridiculous that I couldn\'t be bothered to post once about the many, many things that have gone on since then. My apologies. I guess I could start by saying that the world looks like a very different place than it did back in second year.</p></em>\n\n';
      let extensions = 'jpg|jpeg|png';
      let tag = reg_exp2_test.RegExp2Test.findImageTag_(text, extensions);
      expect$.Expect.isNotNull(tag);
    }
  };
  dart.setSignature(reg_exp2_test.RegExp2Test, {
    statics: () => ({
      findImageTag_: dart.definiteFunctionType(core.String, [core.String, core.String]),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['findImageTag_', 'testMain']
  });
  reg_exp2_test.main = function() {
    reg_exp2_test.RegExp2Test.testMain();
  };
  dart.fn(reg_exp2_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp2_test = reg_exp2_test;
});
