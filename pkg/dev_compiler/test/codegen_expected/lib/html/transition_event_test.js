dart_library.library('lib/html/transition_event_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__transition_event_test(exports, dart_sdk, unittest) {
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
  const transition_event_test = Object.create(null);
  let TransitionEventTodynamic = () => (TransitionEventTodynamic = dart.constFn(dart.functionType(dart.dynamic, [html.TransitionEvent])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let const$;
  transition_event_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.CssStyleDeclaration[dartx.supportsTransitions], true);
      }, VoidTodynamic()));
    }, VoidTovoid$()));
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('transitionEnd', dart.fn(() => {
        if (dart.test(html.CssStyleDeclaration[dartx.supportsTransitions])) {
          let element = html.DivElement.new();
          html.document[dartx.body][dartx.append](element);
          element[dartx.style][dartx.opacity] = '0';
          element[dartx.style][dartx.width] = '100px';
          element[dartx.style][dartx.height] = '100px';
          element[dartx.style][dartx.background] = 'red';
          element[dartx.style][dartx.transition] = 'opacity .1s';
          async.Timer.new(const$ || (const$ = dart.const(new core.Duration({milliseconds: 100}))), VoidTovoid()._check(unittest$.expectAsync(dart.fn(() => {
            element[dartx.onTransitionEnd].first.then(dart.dynamic)(TransitionEventTodynamic()._check(unittest$.expectAsync(dart.fn(e => {
              src__matcher__expect.expect(html.TransitionEvent.is(e), src__matcher__core_matchers.isTrue);
              src__matcher__expect.expect(dart.dload(e, 'propertyName'), 'opacity');
            }, dynamicTodynamic()))));
            element[dartx.style][dartx.opacity] = '1';
          }, VoidTodynamic()))));
        }
      }, VoidTodynamic()));
    }, VoidTovoid$()));
  };
  dart.fn(transition_event_test.main, VoidTodynamic());
  // Exports:
  exports.transition_event_test = transition_event_test;
});
