dart_library.library('lib/html/cross_domain_iframe_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__cross_domain_iframe_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const cross_domain_iframe_test = Object.create(null);
  let MessageEventTodynamic = () => (MessageEventTodynamic = dart.constFn(dart.functionType(dart.dynamic, [html.MessageEvent])))();
  let MessageEventTodynamic$ = () => (MessageEventTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [html.MessageEvent])))();
  let MessageEventTobool = () => (MessageEventTobool = dart.constFn(dart.definiteFunctionType(core.bool, [html.MessageEvent])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cross_domain_iframe_test.main = function() {
    unittest$.test('cross_domain_iframe', dart.fn(() => {
      let uri = core.Uri.parse(html.window[dartx.location][dartx.href]);
      let crossOriginPort = core.int.parse(uri.queryParameters[dartx.get]('crossOriginPort'));
      let crossOrigin = dart.str`${uri.scheme}://${uri.host}:${crossOriginPort}`;
      let crossOriginUrl = dart.str`${crossOrigin}/root_dart/tests/html/cross_domain_iframe_script.html`;
      let iframe = html.IFrameElement.new();
      iframe[dartx.src] = crossOriginUrl;
      html.document[dartx.body][dartx.append](iframe);
      html.window[dartx.onMessage].where(dart.fn(event => event[dartx.origin] == crossOrigin, MessageEventTobool())).first.then(dart.dynamic)(MessageEventTodynamic()._check(unittest$.expectAsync(dart.fn(event => {
        src__matcher__expect.expect(event[dartx.data], src__matcher__core_matchers.equals('foobar'));
        src__matcher__expect.expect(event[dartx.source], src__matcher__core_matchers.isNotNull);
      }, MessageEventTodynamic$()))));
    }, VoidTodynamic()));
  };
  dart.fn(cross_domain_iframe_test.main, VoidTodynamic());
  // Exports:
  exports.cross_domain_iframe_test = cross_domain_iframe_test;
});
