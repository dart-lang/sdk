dart_library.library('lib/html/rtc_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__rtc_test(exports, dart_sdk, unittest) {
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
  const rtc_test = Object.create(null);
  let MapOfString$String = () => (MapOfString$String = dart.constFn(core.Map$(core.String, core.String)))();
  let JSArrayOfMapOfString$String = () => (JSArrayOfMapOfString$String = dart.constFn(_interceptors.JSArray$(MapOfString$String())))();
  let ListOfMapOfString$String = () => (ListOfMapOfString$String = dart.constFn(core.List$(MapOfString$String())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  rtc_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.RtcPeerConnection[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functionality', dart.fn(() => {
      if (dart.test(html.RtcPeerConnection[dartx.supported])) {
        unittest$.test('peer connection', dart.fn(() => {
          let pc = html.RtcPeerConnection.new(dart.map({iceServers: JSArrayOfMapOfString$String().of([dart.map({url: 'stun:216.93.246.18:3478'}, core.String, core.String)])}, core.String, ListOfMapOfString$String()));
          src__matcher__expect.expect(html.RtcPeerConnection.is(pc), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()));
        unittest$.test('ice candidate', dart.fn(() => {
          let candidate = html.RtcIceCandidate.new(dart.map({sdpMLineIndex: 1, candidate: 'hello'}, core.String, core.Object));
          src__matcher__expect.expect(html.RtcIceCandidate.is(candidate), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()));
        unittest$.test('session description', dart.fn(() => {
          let description = html.RtcSessionDescription.new(dart.map({sdp: 'foo', type: 'offer'}, core.String, core.String));
          src__matcher__expect.expect(html.RtcSessionDescription.is(description), src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()));
      }
    }, VoidTovoid()));
  };
  dart.fn(rtc_test.main, VoidTodynamic());
  // Exports:
  exports.rtc_test = rtc_test;
});
