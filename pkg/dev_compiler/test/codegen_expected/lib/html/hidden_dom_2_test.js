dart_library.library('lib/html/hidden_dom_2_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__hidden_dom_2_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__error_matchers = unittest.src__matcher__error_matchers;
  const hidden_dom_2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let FnTodynamic = () => (FnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidTodynamic()])))();
  hidden_dom_2_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('test1', dart.fn(() => {
      html.document[dartx.body][dartx.children][dartx.add](html.Element.html('<div id=\'div1\'>\nHello World!\n</div>'));
      let e = html.document[dartx.query]('#div1');
      let e2 = html.Element.html("<div id='xx'>XX</div>");
      src__matcher__expect.expect(e, src__matcher__core_matchers.isNotNull);
      hidden_dom_2_test.checkNoSuchMethod(dart.fn(() => {
        dart.dsend(hidden_dom_2_test.confuse(e), 'appendChild', e2);
      }, VoidTodynamic$()));
    }, VoidTodynamic$()));
  };
  dart.fn(hidden_dom_2_test.main, VoidTodynamic$());
  hidden_dom_2_test.Decoy = class Decoy extends core.Object {
    appendChild(x) {
      dart.throw('dead code');
    }
  };
  dart.setSignature(hidden_dom_2_test.Decoy, {
    methods: () => ({appendChild: dart.definiteFunctionType(dart.void, [dart.dynamic])})
  });
  hidden_dom_2_test.confuse = function(x) {
    return dart.test(hidden_dom_2_test.opaqueTrue()) ? x : dart.test(hidden_dom_2_test.opaqueTrue()) ? new core.Object() : new hidden_dom_2_test.Decoy();
  };
  dart.fn(hidden_dom_2_test.confuse, dynamicTodynamic());
  hidden_dom_2_test.opaqueTrue = function() {
    return true;
  };
  dart.fn(hidden_dom_2_test.opaqueTrue, VoidTodynamic$());
  hidden_dom_2_test.checkNoSuchMethod = function(action) {
    let ex = null;
    let threw = false;
    try {
      action();
    } catch (e) {
      threw = true;
      ex = e;
    }

    if (!threw) src__matcher__expect.expect(false, src__matcher__core_matchers.isTrue, {reason: 'Action should have thrown exception'});
    src__matcher__expect.expect(ex, src__matcher__error_matchers.isNoSuchMethodError);
  };
  dart.fn(hidden_dom_2_test.checkNoSuchMethod, FnTodynamic());
  // Exports:
  exports.hidden_dom_2_test = hidden_dom_2_test;
});
