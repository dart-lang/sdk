dart_library.library('lib/html/history_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__history_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const history_test = Object.create(null);
  let PopStateEventTodynamic = () => (PopStateEventTodynamic = dart.constFn(dart.functionType(dart.dynamic, [html.PopStateEvent])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let const$;
  history_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported_state', dart.fn(() => {
      unittest$.test('supportsState', dart.fn(() => {
        src__matcher__expect.expect(html.History[dartx.supportsState], true);
      }, VoidTodynamic()));
    }, VoidTovoid$()));
    unittest$.group('supported_HashChangeEvent', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.HashChangeEvent[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid$()));
    let expectation = dart.test(html.History[dartx.supportsState]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
    unittest$.group('history', dart.fn(() => {
      unittest$.test('pushState', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          html.window[dartx.history][dartx.pushState](null, html.document[dartx.title], '?dummy');
          let length = html.window[dartx.history][dartx.length];
          html.window[dartx.history][dartx.pushState](null, html.document[dartx.title], '?foo=bar');
          src__matcher__expect.expect(html.window[dartx.location][dartx.href][dartx.endsWith]('foo=bar'), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('pushState with data', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          html.window[dartx.history][dartx.pushState](dart.map({one: 1}), html.document[dartx.title], '?dummy');
          src__matcher__expect.expect(html.window[dartx.history][dartx.state], src__matcher__core_matchers.equals(dart.map({one: 1})));
          html.window[dartx.history][dartx.pushState](null, html.document[dartx.title], '?foo=bar');
          src__matcher__expect.expect(html.window[dartx.location][dartx.href][dartx.endsWith]('foo=bar'), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('back', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          html.window[dartx.history][dartx.pushState](null, html.document[dartx.title], '?dummy1');
          html.window[dartx.history][dartx.pushState](null, html.document[dartx.title], '?dummy2');
          let length = html.window[dartx.history][dartx.length];
          src__matcher__expect.expect(html.window[dartx.location][dartx.href][dartx.endsWith]('dummy2'), src__matcher__core_matchers.isTrue);
          async.Timer.new(const$ || (const$ = dart.const(new core.Duration({milliseconds: 100}))), VoidTovoid()._check(unittest$.expectAsync(dart.fn(() => {
            html.window[dartx.onPopState].first.then(dart.dynamic)(PopStateEventTodynamic()._check(unittest$.expectAsync(dart.fn(_ => {
              src__matcher__expect.expect(html.window[dartx.history][dartx.length], length);
              src__matcher__expect.expect(html.window[dartx.location][dartx.href][dartx.endsWith]('dummy1'), src__matcher__core_matchers.isTrue);
            }, dynamicTodynamic()))));
            html.window[dartx.history][dartx.back]();
          }, VoidTodynamic()))));
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('replaceState', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          let length = html.window[dartx.history][dartx.length];
          html.window[dartx.history][dartx.replaceState](null, html.document[dartx.title], '?foo=baz');
          src__matcher__expect.expect(html.window[dartx.history][dartx.length], length);
          src__matcher__expect.expect(html.window[dartx.location][dartx.href][dartx.endsWith]('foo=baz'), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('popstatevent', dart.fn(() => {
        src__matcher__expect.expect(dart.fn(() => {
          let event = html.Event.eventType('PopStateEvent', 'popstate');
          src__matcher__expect.expect(html.PopStateEvent.is(event), true);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('hashchangeevent', dart.fn(() => {
        let expectation = dart.test(html.HashChangeEvent[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let event = html.HashChangeEvent.new('change', {oldUrl: 'old', newUrl: 'new'});
          src__matcher__expect.expect(html.HashChangeEvent.is(event), true);
          src__matcher__expect.expect(event[dartx.oldUrl], 'old');
          src__matcher__expect.expect(event[dartx.newUrl], 'new');
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid$()));
  };
  dart.fn(history_test.main, VoidTodynamic());
  // Exports:
  exports.history_test = history_test;
});
