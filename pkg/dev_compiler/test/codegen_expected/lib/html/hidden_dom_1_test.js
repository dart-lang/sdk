dart_library.library('lib/html/hidden_dom_1_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__hidden_dom_1_test(exports, dart_sdk, unittest) {
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
  const hidden_dom_1_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.functionType(dart.dynamic, [])))();
  let VoidTodynamic$ = () => (VoidTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let FnTodynamic = () => (FnTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [VoidTodynamic()])))();
  hidden_dom_1_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('test1', dart.fn(() => {
      html.document[dartx.body][dartx.children][dartx.add](html.Element.html('<div id=\'div1\'>\nHello World!\n</div>'));
      let e = html.document[dartx.query]('#div1');
      src__matcher__expect.expect(e, src__matcher__core_matchers.isNotNull);
      hidden_dom_1_test.checkNoSuchMethod(dart.fn(() => {
        dart.dput(hidden_dom_1_test.confuse(e), 'onfocus', null);
      }, VoidTodynamic$()));
    }, VoidTodynamic$()));
  };
  dart.fn(hidden_dom_1_test.main, VoidTodynamic$());
  hidden_dom_1_test.Decoy = class Decoy extends core.Object {
    set onfocus(x) {
      dart.throw('dead code');
    }
  };
  hidden_dom_1_test.confuse = function(x) {
    return dart.test(hidden_dom_1_test.opaqueTrue()) ? x : dart.test(hidden_dom_1_test.opaqueTrue()) ? new core.Object() : new hidden_dom_1_test.Decoy();
  };
  dart.fn(hidden_dom_1_test.confuse, dynamicTodynamic());
  hidden_dom_1_test.opaqueTrue = function() {
    return true;
  };
  dart.fn(hidden_dom_1_test.opaqueTrue, VoidTodynamic$());
  hidden_dom_1_test.checkNoSuchMethod = function(action) {
    let ex = null;
    try {
      action();
    } catch (e) {
      ex = e;
    }

    if (ex == null) src__matcher__expect.expect(false, src__matcher__core_matchers.isTrue, {reason: 'Action should have thrown exception'});
    src__matcher__expect.expect(ex, src__matcher__error_matchers.isNoSuchMethodError);
  };
  dart.fn(hidden_dom_1_test.checkNoSuchMethod, FnTodynamic());
  // Exports:
  exports.hidden_dom_1_test = hidden_dom_1_test;
});
