dart_library.library('lib/html/js_interop_1_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__js_interop_1_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const js_interop_1_test = Object.create(null);
  let MessageEventTovoid = () => (MessageEventTovoid = dart.constFn(dart.functionType(dart.void, [html.MessageEvent])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  js_interop_1_test.injectSource = function(code) {
    let script = html.ScriptElement.new();
    script[dartx.type] = 'text/javascript';
    script[dartx.innerHtml] = core.String._check(code);
    html.document[dartx.body][dartx.append](script);
  };
  dart.fn(js_interop_1_test.injectSource, dynamicTodynamic());
  js_interop_1_test.main = function() {
    html_config.useHtmlConfiguration();
    let callback = null;
    unittest$.test('js-to-dart-post-message', dart.fn(() => {
      let subscription = null;
      let complete = false;
      subscription = html.window[dartx.onMessage].listen(MessageEventTovoid()._check(unittest$.expectAsyncUntil(dart.fn(e => {
        if (dart.equals(dart.dload(e, 'data'), 'hello')) {
          dart.dsend(subscription, 'cancel');
          complete = true;
        }
      }, dynamicTodynamic()), dart.fn(() => complete, VoidTobool()))));
      js_interop_1_test.injectSource("window.postMessage('hello', '*');");
    }, VoidTodynamic()));
  };
  dart.fn(js_interop_1_test.main, VoidTodynamic());
  // Exports:
  exports.js_interop_1_test = js_interop_1_test;
});
