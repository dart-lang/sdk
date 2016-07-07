dart_library.library('lib/html/notification_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__notification_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const notification_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  notification_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported_notification', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.Notification[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('constructors', dart.fn(() => {
      unittest$.test('Notification', dart.fn(() => {
        let expectation = dart.test(html.Notification[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let allDefaults = html.Notification.new("Hello world");
          let allSpecified = html.Notification.new("Deluxe notification", {dir: "rtl", body: 'All parameters set', icon: 'icon.png', tag: 'tag', lang: 'en_US'});
          src__matcher__expect.expect(html.Notification.is(allDefaults), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(html.Notification.is(allSpecified), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(allDefaults[dartx.title], "Hello world");
          src__matcher__expect.expect(allSpecified[dartx.title], "Deluxe notification");
          src__matcher__expect.expect(allSpecified[dartx.dir], "rtl");
          src__matcher__expect.expect(allSpecified[dartx.body], "All parameters set");
          let icon = allSpecified[dartx.icon];
          let tail = core.Uri.parse(icon).pathSegments[dartx.last];
          src__matcher__expect.expect(tail, "icon.png");
          src__matcher__expect.expect(allSpecified[dartx.tag], "tag");
          src__matcher__expect.expect(allSpecified[dartx.lang], "en_US");
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(notification_test.main, VoidTodynamic());
  // Exports:
  exports.notification_test = notification_test;
});
