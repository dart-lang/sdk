// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:async';
import 'dart:html';
import 'dart:json' as json;

void fail(message) {
  guardAsync(() {
    expect(false, isTrue, reason: message);
  });
}

main() {
  useHtmlIndividualConfiguration();
  var url = "/root_dart/tests/html/xhr_cross_origin_data.txt";

  void validate200Response(xhr) {
    expect(xhr.status, equals(200));
    var data = json.parse(xhr.responseText);
    expect(data, contains('feed'));
    expect(data['feed'], contains('entry'));
    expect(data, isMap);
  }

  void validate404(xhr) {
    expect(xhr.status, equals(404));
    expect(xhr.responseText, equals(''));
  }

  group('supported_HttpRequestProgressEvent', () {
    test('supported', () {
      expect(HttpRequestProgressEvent.supported, isTrue);
    });
  });

  group('supported_onProgress', () {
    test('supported', () {
      expect(HttpRequest.supportsProgressEvent, isTrue);
    });
  });

  group('supported_onLoadEnd', () {
    test('supported', () {
      expect(HttpRequest.supportsLoadEndEvent, isTrue);
    });
  });

  group('xhr', () {
    test('XHR No file', () {
      HttpRequest xhr = new HttpRequest();
      xhr.open("GET", "NonExistingFile", async: true);
      xhr.onReadyStateChange.listen(expectAsyncUntil1((event) {
        if (xhr.readyState == HttpRequest.DONE) {
          validate404(xhr);
        }
      }, () => xhr.readyState == HttpRequest.DONE));
      xhr.send();
    });

    test('XHR file', () {
      var loadEndCalled = false;

      var xhr = new HttpRequest();
      xhr.open('GET', url, async: true);
      xhr.onReadyStateChange.listen(expectAsyncUntil1((e) {
        if (xhr.readyState == HttpRequest.DONE) {
          validate200Response(xhr);

          Timer.run(expectAsync0(() {
            expect(loadEndCalled, HttpRequest.supportsLoadEndEvent);
          }));
        }
      }, () => xhr.readyState == HttpRequest.DONE));

      xhr.onLoadEnd.listen((ProgressEvent e) {
        loadEndCalled = true;
      });
      xhr.send();
    });

    test('XHR.request No file', () {
      HttpRequest.request('NonExistingFile').then(
        (_) { fail('Request should not have succeeded.'); },
        onError: expectAsync1((error) {
          var xhr = error.target;
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate404(xhr);
        }));
    });

    test('XHR.request file', () {
      HttpRequest.request(url).then(expectAsync1((xhr) {
        expect(xhr.readyState, equals(HttpRequest.DONE));
        validate200Response(xhr);
      }));
    });

    test('XHR.request onProgress', () {
      var progressCalled = false;
      HttpRequest.request(url,
        onProgress: (_) {
          progressCalled = true;
        }).then(expectAsync1(
          (xhr) {
            expect(xhr.readyState, equals(HttpRequest.DONE));
            expect(progressCalled, HttpRequest.supportsProgressEvent);
            validate200Response(xhr);
          }));
    });

    test('XHR.request withCredentials No file', () {
      HttpRequest.request('NonExistingFile', withCredentials: true).then(
        (_) { fail('Request should not have succeeded.'); },
        onError: expectAsync1((error) {
          var xhr = error.target;
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate404(xhr);
        }));
    });

    test('XHR.request withCredentials file', () {
      HttpRequest.request(url, withCredentials: true).then(expectAsync1((xhr) {
        expect(xhr.readyState, equals(HttpRequest.DONE));
        validate200Response(xhr);
      }));
    });

    test('XHR.getString file', () {
      HttpRequest.getString(url).then(expectAsync1((str) {}));
    });

    test('XHR.getString No file', () {
      HttpRequest.getString('NonExistingFile').then(
        (_) { fail('Succeeded for non-existing file.'); },
        onError: expectAsync1((error) {
          validate404(error.target);
        }));
    });

    test('XHR.request responseType arraybuffer', () {
      if (ArrayBuffer.supported) {
        HttpRequest.request(url, responseType: 'arraybuffer').then(
          expectAsync1((xhr) {
            expect(xhr.status, equals(200));
            var arrayBuffer = xhr.response;
            expect(arrayBuffer, new isInstanceOf<ArrayBuffer>());
            expect(arrayBuffer, isNotNull);
          }));
      }
    });

    test('HttpRequestProgressEvent', () {
      var expectation = HttpRequestProgressEvent.supported ?
          returnsNormally : throws;
      expect(() {
        var event = new Event.eventType('XMLHttpRequestProgressEvent', '');
        expect(event is HttpRequestProgressEvent, isTrue);
      }, expectation);
    });
  });

  group('xhr_requestBlob', () {
    test('XHR.request responseType blob', () {
      if (ArrayBuffer.supported) {
        return HttpRequest.request(url, responseType: 'blob').then(
          (xhr) {
            expect(xhr.status, equals(200));
            var blob = xhr.response;
            expect(blob is Blob, isTrue);
            expect(blob, isNotNull);
          });
      }
    });
  });
}
