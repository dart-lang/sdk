dart_library.library('lib/html/xhr_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__xhr_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const convert = dart_sdk.convert;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const xhr_test = Object.create(null);
  let ProgressEventTovoid = () => (ProgressEventTovoid = dart.constFn(dart.functionType(dart.void, [html.ProgressEvent])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let HttpRequestTodynamic = () => (HttpRequestTodynamic = dart.constFn(dart.functionType(dart.dynamic, [html.HttpRequest])))();
  let StringTodynamic = () => (StringTodynamic = dart.constFn(dart.functionType(dart.dynamic, [core.String])))();
  let isInstanceOfOfByteBuffer = () => (isInstanceOfOfByteBuffer = dart.constFn(src__matcher__core_matchers.isInstanceOf$(typed_data.ByteBuffer)))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let ProgressEventTovoid$ = () => (ProgressEventTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [html.ProgressEvent])))();
  let HttpRequestTodynamic$ = () => (HttpRequestTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [html.HttpRequest])))();
  let StringTodynamic$ = () => (StringTodynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String])))();
  let ProgressEventTodynamic = () => (ProgressEventTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [html.ProgressEvent])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  xhr_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    let cacheBlocker = new core.DateTime.now().millisecondsSinceEpoch;
    let url = '/root_dart/tests/html/xhr_cross_origin_data.txt?' + dart.str`cacheBlock=${cacheBlocker}`;
    function validate200Response(xhr) {
      src__matcher__expect.expect(dart.dload(xhr, 'status'), src__matcher__core_matchers.equals(200));
      let data = convert.JSON.decode(core.String._check(dart.dload(xhr, 'responseText')));
      src__matcher__expect.expect(data, src__matcher__core_matchers.contains('feed'));
      src__matcher__expect.expect(dart.dindex(data, 'feed'), src__matcher__core_matchers.contains('entry'));
      src__matcher__expect.expect(data, src__matcher__core_matchers.isMap);
    }
    dart.fn(validate200Response, dynamicTovoid());
    function validate404(xhr) {
      src__matcher__expect.expect(dart.dload(xhr, 'status'), src__matcher__core_matchers.equals(404));
      let responseText = core.String._check(dart.dload(xhr, 'responseText'));
      src__matcher__expect.expect(responseText, src__matcher__core_matchers.isNotNull);
    }
    dart.fn(validate404, dynamicTovoid());
    unittest$.group('supported_onProgress', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.HttpRequest[dartx.supportsProgressEvent], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid$()));
    unittest$.group('supported_onLoadEnd', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.HttpRequest[dartx.supportsLoadEndEvent], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid$()));
    unittest$.group('supported_overrideMimeType', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.HttpRequest[dartx.supportsOverrideMimeType], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid$()));
    unittest$.group('xhr', dart.fn(() => {
      unittest$.test('XHR No file', dart.fn(() => {
        let xhr = html.HttpRequest.new();
        xhr[dartx.open]("GET", "NonExistingFile", {async: true});
        xhr[dartx.onReadyStateChange].listen(ProgressEventTovoid()._check(unittest$.expectAsyncUntil(dart.fn(event => {
          if (xhr[dartx.readyState] == html.HttpRequest.DONE) {
            validate404(xhr);
          }
        }, dynamicTodynamic()), dart.fn(() => xhr[dartx.readyState] == html.HttpRequest.DONE, VoidTobool()))));
        xhr[dartx.send]();
      }, VoidTodynamic()));
      unittest$.test('XHR_file', dart.fn(() => {
        let loadEndCalled = false;
        let xhr = html.HttpRequest.new();
        xhr[dartx.open]('GET', url, {async: true});
        xhr[dartx.onReadyStateChange].listen(ProgressEventTovoid()._check(unittest$.expectAsyncUntil(dart.fn(e => {
          if (xhr[dartx.readyState] == html.HttpRequest.DONE) {
            validate200Response(xhr);
            async.Timer.run(VoidTovoid()._check(unittest$.expectAsync(dart.fn(() => {
              src__matcher__expect.expect(loadEndCalled, html.HttpRequest[dartx.supportsLoadEndEvent]);
            }, VoidTodynamic()))));
          }
        }, dynamicTodynamic()), dart.fn(() => xhr[dartx.readyState] == html.HttpRequest.DONE, VoidTobool()))));
        xhr[dartx.onLoadEnd].listen(dart.fn(e => {
          loadEndCalled = true;
        }, ProgressEventTovoid$()));
        xhr[dartx.send]();
      }, VoidTodynamic()));
      unittest$.test('XHR.request No file', dart.fn(() => {
        html.HttpRequest.request('NonExistingFile').then(dart.dynamic)(dart.fn(_ => {
          src__matcher__expect.fail('Request should not have succeeded.');
        }, HttpRequestTodynamic$()), {onError: unittest$.expectAsync(dart.fn(error => {
            let xhr = dart.dload(error, 'target');
            src__matcher__expect.expect(dart.dload(xhr, 'readyState'), src__matcher__core_matchers.equals(html.HttpRequest.DONE));
            validate404(xhr);
          }, dynamicTodynamic()))});
      }, VoidTodynamic()));
      unittest$.test('XHR.request file', dart.fn(() => {
        html.HttpRequest.request(url).then(dart.dynamic)(HttpRequestTodynamic()._check(unittest$.expectAsync(dart.fn(xhr => {
          src__matcher__expect.expect(dart.dload(xhr, 'readyState'), src__matcher__core_matchers.equals(html.HttpRequest.DONE));
          validate200Response(xhr);
        }, dynamicTodynamic()))));
      }, VoidTodynamic()));
      unittest$.test('XHR.request onProgress', dart.fn(() => {
        let progressCalled = false;
        html.HttpRequest.request(url, {onProgress: dart.fn(_ => {
            progressCalled = true;
          }, ProgressEventTovoid$())}).then(dart.dynamic)(HttpRequestTodynamic()._check(unittest$.expectAsync(dart.fn(xhr => {
          src__matcher__expect.expect(dart.dload(xhr, 'readyState'), src__matcher__core_matchers.equals(html.HttpRequest.DONE));
          src__matcher__expect.expect(progressCalled, html.HttpRequest[dartx.supportsProgressEvent]);
          validate200Response(xhr);
        }, dynamicTodynamic()))));
      }, VoidTodynamic()));
      unittest$.test('XHR.request withCredentials No file', dart.fn(() => {
        html.HttpRequest.request('NonExistingFile', {withCredentials: true}).then(dart.dynamic)(dart.fn(_ => {
          src__matcher__expect.fail('Request should not have succeeded.');
        }, HttpRequestTodynamic$()), {onError: unittest$.expectAsync(dart.fn(error => {
            let xhr = dart.dload(error, 'target');
            src__matcher__expect.expect(dart.dload(xhr, 'readyState'), src__matcher__core_matchers.equals(html.HttpRequest.DONE));
            validate404(xhr);
          }, dynamicTodynamic()))});
      }, VoidTodynamic()));
      unittest$.test('XHR.request withCredentials file', dart.fn(() => {
        html.HttpRequest.request(url, {withCredentials: true}).then(dart.dynamic)(HttpRequestTodynamic()._check(unittest$.expectAsync(dart.fn(xhr => {
          src__matcher__expect.expect(dart.dload(xhr, 'readyState'), src__matcher__core_matchers.equals(html.HttpRequest.DONE));
          validate200Response(xhr);
        }, dynamicTodynamic()))));
      }, VoidTodynamic()));
      unittest$.test('XHR.getString file', dart.fn(() => {
        html.HttpRequest.getString(url).then(dart.dynamic)(StringTodynamic()._check(unittest$.expectAsync(dart.fn(str => {
        }, dynamicTodynamic()))));
      }, VoidTodynamic()));
      unittest$.test('XHR.getString No file', dart.fn(() => {
        html.HttpRequest.getString('NonExistingFile').then(dart.dynamic)(dart.fn(_ => {
          src__matcher__expect.fail('Succeeded for non-existing file.');
        }, StringTodynamic$()), {onError: unittest$.expectAsync(dart.fn(error => {
            validate404(dart.dload(error, 'target'));
          }, dynamicTodynamic()))});
      }, VoidTodynamic()));
      unittest$.test('XHR.request responseType arraybuffer', dart.fn(() => {
        if (dart.test(html.Platform.supportsTypedData)) {
          html.HttpRequest.request(url, {responseType: 'arraybuffer', requestHeaders: dart.map({'Content-Type': 'text/xml'})}).then(dart.dynamic)(HttpRequestTodynamic()._check(unittest$.expectAsync(dart.fn(xhr => {
            src__matcher__expect.expect(dart.dload(xhr, 'status'), src__matcher__core_matchers.equals(200));
            let byteBuffer = dart.dload(xhr, 'response');
            src__matcher__expect.expect(byteBuffer, new (isInstanceOfOfByteBuffer())());
            src__matcher__expect.expect(byteBuffer, src__matcher__core_matchers.isNotNull);
          }, dynamicTodynamic()))));
        }
      }, VoidTodynamic()));
      unittest$.test('overrideMimeType', dart.fn(() => {
        let expectation = dart.test(html.HttpRequest[dartx.supportsOverrideMimeType]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          html.HttpRequest.request(url, {mimeType: 'application/binary'});
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      if (dart.test(html.Platform.supportsTypedData)) {
        unittest$.test('xhr upload', dart.fn(() => {
          let xhr = html.HttpRequest.new();
          let progressCalled = false;
          xhr[dartx.upload][dartx.onProgress].listen(dart.fn(e => {
            progressCalled = true;
          }, ProgressEventTovoid$()));
          xhr[dartx.open]('POST', dart.str`${html.window[dartx.location][dartx.protocol]}//${html.window[dartx.location][dartx.host]}/echo`);
          let data = typed_data.Uint8List.new(1 * 1024 * 1024);
          for (let i = 0; i < dart.notNull(data[dartx.length]); ++i) {
            data[dartx.set](i, i & 255);
          }
          xhr[dartx.send](typed_data.Uint8List.view(data[dartx.buffer]));
          return xhr[dartx.onLoad].first.then(dart.dynamic)(dart.fn(_ => {
            src__matcher__expect.expect(progressCalled, src__matcher__core_matchers.isTrue, {reason: 'onProgress should be fired'});
          }, ProgressEventTodynamic()));
        }, VoidToFuture()));
      }
      unittest$.test('xhr postFormData', dart.fn(() => {
        let data = dart.map({name: 'John', time: '2 pm'});
        let parts = [];
        for (let key of data[dartx.keys]) {
          parts[dartx.add](dart.str`${core.Uri.encodeQueryComponent(key)}=` + dart.str`${core.Uri.encodeQueryComponent(data[dartx.get](key))}`);
        }
        let encodedData = parts[dartx.join]('&');
        return html.HttpRequest.postFormData(dart.str`${html.window[dartx.location][dartx.protocol]}//${html.window[dartx.location][dartx.host]}/echo`, data).then(dart.dynamic)(dart.fn(xhr => {
          src__matcher__expect.expect(xhr[dartx.responseText], encodedData);
        }, HttpRequestTodynamic$()));
      }, VoidToFuture()));
    }, VoidTovoid$()));
    unittest$.group('xhr_requestBlob', dart.fn(() => {
      unittest$.test('XHR.request responseType blob', dart.fn(() => {
        if (dart.test(html.Platform.supportsTypedData)) {
          return html.HttpRequest.request(url, {responseType: 'blob'}).then(dart.dynamic)(dart.fn(xhr => {
            src__matcher__expect.expect(xhr[dartx.status], src__matcher__core_matchers.equals(200));
            let blob = xhr[dartx.response];
            src__matcher__expect.expect(html.Blob.is(blob), src__matcher__core_matchers.isTrue);
            src__matcher__expect.expect(blob, src__matcher__core_matchers.isNotNull);
          }, HttpRequestTodynamic$()));
        }
      }, VoidToFuture()));
    }, VoidTovoid$()));
    unittest$.group('json', dart.fn(() => {
      unittest$.test('xhr responseType json', dart.fn(() => {
        let url = dart.str`${html.window[dartx.location][dartx.protocol]}//${html.window[dartx.location][dartx.host]}/echo`;
        let data = dart.map({key: 'value', a: 'b', one: 2});
        html.HttpRequest.request(url, {method: 'POST', sendData: convert.JSON.encode(data), responseType: 'json'}).then(dart.dynamic)(HttpRequestTodynamic()._check(unittest$.expectAsync(dart.fn(xhr => {
          src__matcher__expect.expect(dart.dload(xhr, 'status'), src__matcher__core_matchers.equals(200));
          let json = dart.dload(xhr, 'response');
          src__matcher__expect.expect(json, src__matcher__core_matchers.equals(data));
        }, dynamicTodynamic()))));
      }, VoidTodynamic()));
    }, VoidTovoid$()));
    unittest$.group('headers', dart.fn(() => {
      unittest$.test('xhr responseHeaders', dart.fn(() => html.HttpRequest.request(url).then(dart.dynamic)(dart.fn(xhr => {
        let contentTypeHeader = xhr[dartx.responseHeaders][dartx.get]('content-type');
        src__matcher__expect.expect(contentTypeHeader, src__matcher__core_matchers.isNotNull);
        src__matcher__expect.expect(contentTypeHeader[dartx.contains]('text/plain'), src__matcher__core_matchers.isTrue);
        src__matcher__expect.expect(contentTypeHeader[dartx.contains]('charset=utf-8'), src__matcher__core_matchers.isTrue);
      }, HttpRequestTodynamic$())), VoidToFuture()));
    }, VoidTovoid$()));
  };
  dart.fn(xhr_test.main, VoidTodynamic());
  // Exports:
  exports.xhr_test = xhr_test;
});
