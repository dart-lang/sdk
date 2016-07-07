dart_library.library('lib/html/callbacks_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__callbacks_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const callbacks_test = Object.create(null);
  let numTobool = () => (numTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.num])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  callbacks_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('RequestAnimationFrameCallback', dart.fn(() => {
      html.window[dartx.requestAnimationFrame](dart.fn(time => false, numTobool()));
    }, VoidTodynamic()));
  };
  dart.fn(callbacks_test.main, VoidTodynamic());
  // Exports:
  exports.callbacks_test = callbacks_test;
});
