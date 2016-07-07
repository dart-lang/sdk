dart_library.library('lib/html/xhr_cross_origin_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__xhr_cross_origin_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const convert = dart_sdk.convert;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const xhr_cross_origin_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let ObjectTobool = () => (ObjectTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.Object])))();
  let HttpRequestTodynamic = () => (HttpRequestTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [html.HttpRequest])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let StringTodynamic = () => (StringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String])))();
  let ProgressEventTovoid = () => (ProgressEventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.ProgressEvent])))();
  dart.copyProperties(xhr_cross_origin_test, {
    get crossOriginPort() {
      let searchUrl = html.window[dartx.location][dartx.search];
      let crossOriginStr = 'crossOriginPort=';
      let index = searchUrl[dartx.indexOf](crossOriginStr);
      let nextArg = searchUrl[dartx.indexOf]('&', index);
      return core.int.parse(searchUrl[dartx.substring](dart.notNull(index) + dart.notNull(crossOriginStr[dartx.length]), nextArg == -1 ? searchUrl[dartx.length] : nextArg));
    }
  });
  xhr_cross_origin_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.HttpRequest[dartx.supportsCrossOrigin], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      let port = xhr_cross_origin_test.crossOriginPort;
      let host = dart.str`${html.window[dartx.location][dartx.protocol]}//${html.window[dartx.location][dartx.hostname]}:${port}`;
      unittest$.test('XHR.get Cross-domain', dart.fn(() => {
        let gotError = false;
        let url = dart.str`${host}/root_dart/tests/html/xhr_cross_origin_data.txt`;
        return html.HttpRequest.request(url).then(dart.dynamic)(dart.fn(xhr => {
          let data = convert.JSON.decode(core.String._check(xhr[dartx.response]));
          src__matcher__expect.expect(data, src__matcher__core_matchers.contains('feed'));
          src__matcher__expect.expect(dart.dindex(data, 'feed'), src__matcher__core_matchers.contains('entry'));
          src__matcher__expect.expect(data, src__matcher__core_matchers.isMap);
        }, HttpRequestTodynamic())).catchError(dart.fn(error => {
        }, dynamicTodynamic()), {test: dart.fn(error => {
            gotError = true;
            return !dart.test(html.HttpRequest[dartx.supportsCrossOrigin]);
          }, ObjectTobool())}).whenComplete(dart.fn(() => {
          src__matcher__expect.expect(gotError, !dart.test(html.HttpRequest[dartx.supportsCrossOrigin]));
        }, VoidTodynamic()));
      }, VoidToFuture()));
      unittest$.test('XHR.requestCrossOrigin', dart.fn(() => {
        let url = dart.str`${host}/root_dart/tests/html/xhr_cross_origin_data.txt`;
        return html.HttpRequest.requestCrossOrigin(url).then(dart.dynamic)(dart.fn(response => {
          src__matcher__expect.expect(response, src__matcher__core_matchers.contains('feed'));
        }, StringTodynamic()));
      }, VoidToFuture()));
      unittest$.test('XHR.requestCrossOrigin errors', dart.fn(() => {
        let gotError = false;
        return html.HttpRequest.requestCrossOrigin('does_not_exist').then(dart.dynamic)(dart.fn(response => {
          src__matcher__expect.expect(true, src__matcher__core_matchers.isFalse, {reason: '404s should fail request.'});
        }, StringTodynamic())).catchError(dart.fn(error => {
        }, dynamicTodynamic()), {test: dart.fn(error => {
            gotError = true;
            return true;
          }, ObjectTobool())}).whenComplete(dart.fn(() => {
          src__matcher__expect.expect(gotError, src__matcher__core_matchers.isTrue);
        }, VoidTodynamic()));
      }, VoidToFuture()));
      if (!dart.test(html.HttpRequest[dartx.supportsCrossOrigin])) {
        return;
      }
      unittest$.test('XHR Cross-domain', dart.fn(() => {
        let url = dart.str`${host}/root_dart/tests/html/xhr_cross_origin_data.txt`;
        let xhr = html.HttpRequest.new();
        xhr[dartx.open]('GET', url, {async: true});
        let validate = unittest$.expectAsync(dart.fn(data => {
          src__matcher__expect.expect(data, src__matcher__core_matchers.contains('feed'));
          src__matcher__expect.expect(dart.dindex(data, 'feed'), src__matcher__core_matchers.contains('entry'));
          src__matcher__expect.expect(data, src__matcher__core_matchers.isMap);
        }, dynamicTodynamic()));
        xhr[dartx.onReadyStateChange].listen(dart.fn(e => {
          if (xhr[dartx.readyState] == html.HttpRequest.DONE) {
            dart.dcall(validate, convert.JSON.decode(core.String._check(xhr[dartx.response])));
          }
        }, ProgressEventTovoid()));
        xhr[dartx.send]();
      }, VoidTodynamic()));
      unittest$.test('XHR.getWithCredentials Cross-domain', dart.fn(() => {
        let url = dart.str`${host}/root_dart/tests/html/xhr_cross_origin_data.txt`;
        return html.HttpRequest.request(url, {withCredentials: true}).then(dart.dynamic)(dart.fn(xhr => {
          let data = convert.JSON.decode(core.String._check(xhr[dartx.response]));
          src__matcher__expect.expect(data, src__matcher__core_matchers.contains('feed'));
          src__matcher__expect.expect(dart.dindex(data, 'feed'), src__matcher__core_matchers.contains('entry'));
          src__matcher__expect.expect(data, src__matcher__core_matchers.isMap);
        }, HttpRequestTodynamic()));
      }, VoidToFuture()));
    }, VoidTovoid()));
  };
  dart.fn(xhr_cross_origin_test.main, VoidTodynamic());
  // Exports:
  exports.xhr_cross_origin_test = xhr_cross_origin_test;
});
