dart_library.library('lib/html/exceptions_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__exceptions_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const exceptions_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  exceptions_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('EventException', dart.fn(() => {
      let event = html.Event.new('Event');
      try {
        html.document[dartx.dispatchEvent](event);
      } catch (e) {
        if (html.DomException.is(e)) {
          src__matcher__expect.expect(e[dartx.name], html.DomException.INVALID_STATE);
        } else
          throw e;
      }

    }, VoidTodynamic()));
  };
  dart.fn(exceptions_test.main, VoidTodynamic());
  // Exports:
  exports.exceptions_test = exceptions_test;
});
