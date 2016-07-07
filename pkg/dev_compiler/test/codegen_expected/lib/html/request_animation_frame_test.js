dart_library.library('lib/html/request_animation_frame_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__request_animation_frame_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const request_animation_frame_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let numTovoid = () => (numTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.num])))();
  request_animation_frame_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('oneShot', dart.fn(() => {
      let frame = html.window[dartx.requestAnimationFrame](html.FrameRequestCallback._check(unittest$.expectAsync(dart.fn(timestamp => {
      }, dynamicTodynamic()))));
    }, VoidTodynamic()));
    unittest$.test('twoShot', dart.fn(() => {
      let frame = html.window[dartx.requestAnimationFrame](html.FrameRequestCallback._check(unittest$.expectAsync(dart.fn(timestamp1 => {
        html.window[dartx.requestAnimationFrame](html.FrameRequestCallback._check(unittest$.expectAsync(dart.fn(timestamp2 => {
        }, dynamicTodynamic()))));
      }, dynamicTodynamic()))));
    }, VoidTodynamic()));
    unittest$.test('cancel1', dart.fn(() => {
      let frame1 = html.window[dartx.requestAnimationFrame](dart.fn(timestamp1 => {
        dart.throw(core.Exception.new('Should have been cancelled'));
      }, numTovoid()));
      let frame2 = html.window[dartx.requestAnimationFrame](html.FrameRequestCallback._check(unittest$.expectAsync(dart.fn(timestamp2 => {
      }, dynamicTodynamic()))));
      html.window[dartx.cancelAnimationFrame](frame1);
    }, VoidTodynamic()));
    unittest$.test('cancel2', dart.fn(() => {
      let frame1 = html.window[dartx.requestAnimationFrame](html.FrameRequestCallback._check(unittest$.expectAsync(dart.fn(timestamp1 => {
      }, dynamicTodynamic()))));
      let frame2 = html.window[dartx.requestAnimationFrame](dart.fn(timestamp2 => {
        dart.throw(core.Exception.new('Should have been cancelled'));
      }, numTovoid()));
      let frame3 = html.window[dartx.requestAnimationFrame](html.FrameRequestCallback._check(unittest$.expectAsync(dart.fn(timestamp3 => {
      }, dynamicTodynamic()))));
      html.window[dartx.cancelAnimationFrame](frame2);
    }, VoidTodynamic()));
  };
  dart.fn(request_animation_frame_test.main, VoidTodynamic());
  // Exports:
  exports.request_animation_frame_test = request_animation_frame_test;
});
