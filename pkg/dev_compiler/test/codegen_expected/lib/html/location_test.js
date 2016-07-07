dart_library.library('lib/html/location_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__location_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const location_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  location_test.main = function() {
    html_config.useHtmlConfiguration();
    let isLocation = src__matcher__core_matchers.predicate(dart.fn(x => html.Location.is(x), dynamicTobool()), 'is a Location');
    unittest$.test('location hash', dart.fn(() => {
      let location = html.window[dartx.location];
      src__matcher__expect.expect(location, isLocation);
      location[dartx.hash] = 'hello';
      let h = location[dartx.hash];
      src__matcher__expect.expect(h, '#hello');
    }, VoidTodynamic()));
    unittest$.test('location.origin', dart.fn(() => {
      let origin = html.window[dartx.location][dartx.origin];
      let uri = core.Uri.parse(html.window[dartx.location][dartx.href]);
      let reconstructedOrigin = dart.str`${uri.scheme}://${uri.host}`;
      if (uri.port != 0) {
        reconstructedOrigin = dart.str`${reconstructedOrigin}:${uri.port}`;
      }
      src__matcher__expect.expect(origin, reconstructedOrigin);
    }, VoidTodynamic()));
  };
  dart.fn(location_test.main, VoidTodynamic());
  // Exports:
  exports.location_test = location_test;
});
