// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
import 'dart:json' as json;

void fail(message) {
  guardAsync(() {
    expect(false, isTrue, reason: message);
  });
}

main() {
  useHtmlIndividualConfiguration();
  var url = "/tests/html/xhr_cross_origin_data.txt";

  void validate200Response(xhr) {
    expect(xhr.status, equals(200));
    var data = json.parse(xhr.response);
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

  group('xhr', () {
    test('XHR No file', () {
      HttpRequest xhr = new HttpRequest();
      xhr.open("GET", "NonExistingFile", true);
      xhr.onReadyStateChange.listen(expectAsyncUntil1((event) {
        if (xhr.readyState == HttpRequest.DONE) {
          validate404(xhr);
        }
      }, () => xhr.readyState == HttpRequest.DONE));
      xhr.send();
    });

    test('XHR file', () {
      var xhr = new HttpRequest();
      xhr.open('GET', url, true);
      xhr.onReadyStateChange.listen(expectAsyncUntil1((e) {
        if (xhr.readyState == HttpRequest.DONE) {
          validate200Response(xhr);
        }
      }, () => xhr.readyState == HttpRequest.DONE));

      xhr.onLoadEnd.listen(expectAsync1((ProgressEvent e) {
        expect(e.currentTarget, xhr);
        expect(e.target, xhr);
      }));
      xhr.send();
    });

    test('XHR.request No file', () {
      HttpRequest.request('NonExistingFile').then(
        (_) { fail('Request should not have succeeded.'); },
        onError: expectAsync1((e) {
          var xhr = e.error.target;
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
            expect(progressCalled, isTrue);
            validate200Response(xhr);
          }));
    });

    test('XHR.request withCredentials No file', () {
      HttpRequest.request('NonExistingFile', withCredentials: true).then(
        (_) { fail('Request should not have succeeded.'); },
        onError: expectAsync1((e) {
          var xhr = e.error.target;
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
        onError: expectAsync1((e) {
          validate404(e.error.target);
        }));
    });

    test('XHR.request responseType', () {
      if (ArrayBuffer.supported) {
        HttpRequest.request(url, responseType: 'ArrayBuffer').then(
          expectAsync1((xhr) {
            validate200Response(xhr);
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
}
