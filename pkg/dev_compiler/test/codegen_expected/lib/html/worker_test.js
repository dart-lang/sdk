dart_library.library('lib/html/worker_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__worker_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const worker_test = Object.create(null);
  let EventTodynamic = () => (EventTodynamic = dart.constFn(dart.functionType(dart.dynamic, [html.Event])))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let MessageEventTodynamic = () => (MessageEventTodynamic = dart.constFn(dart.functionType(dart.dynamic, [html.MessageEvent])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidToWorker = () => (VoidToWorker = dart.constFn(dart.definiteFunctionType(html.Worker, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  worker_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.Worker[dartx.supported], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    let workerScript = 'postMessage(\'WorkerMessage\');';
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('unsupported', dart.fn(() => {
        if (!dart.test(html.Worker[dartx.supported])) {
          src__matcher__expect.expect(dart.fn(() => html.Worker.new('worker.js'), VoidToWorker()), src__matcher__throws_matcher.throws);
        } else {
          html.Worker.new('worker.js')[dartx.onError].first.then(dart.dynamic)(EventTodynamic()._check(unittest$.expectAsync(dart.fn(e => {
            dart.dsend(e, 'preventDefault');
            dart.dsend(e, 'stopImmediatePropagation');
          }, dynamicTodynamic()))));
        }
      }, VoidTodynamic()));
      if (!dart.test(html.Worker[dartx.supported])) {
        return;
      }
      unittest$.test('works', dart.fn(() => {
        let blob = html.Blob.new(JSArrayOfString().of([workerScript]), 'text/javascript');
        let url = html.Url.createObjectUrl(blob);
        let worker = html.Worker.new(url);
        let test = unittest$.expectAsync(dart.fn(e => {
          src__matcher__expect.expect(dart.dload(e, 'data'), 'WorkerMessage');
        }, dynamicTodynamic()));
        worker[dartx.onMessage].first.then(dart.dynamic)(MessageEventTodynamic()._check(test));
      }, VoidTodynamic()));
    }, VoidTovoid()));
  };
  dart.fn(worker_test.main, VoidTodynamic());
  // Exports:
  exports.worker_test = worker_test;
});
