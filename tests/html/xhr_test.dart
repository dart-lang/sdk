// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
import 'dart:json' as json;

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

    test('XHR.get No file', () {
      new HttpRequest.get("NonExistingFile", expectAsync1((xhr) {
        expect(xhr.readyState, equals(HttpRequest.DONE));
        validate404(xhr);
      }));
    });

    test('XHR.get file', () {
      var xhr = new HttpRequest.get(url, expectAsync1((event) {
        expect(event.readyState, equals(HttpRequest.DONE));
        validate200Response(event);
      }));
    });

    test('XHR.getWithCredentials No file', () {
      new HttpRequest.getWithCredentials("NonExistingFile", expectAsync1((xhr) {
        expect(xhr.readyState, equals(HttpRequest.DONE));
        validate404(xhr);
      }));
    });

    test('XHR.getWithCredentials file', () {
      new HttpRequest.getWithCredentials(url, expectAsync1((xhr) {
        expect(xhr.readyState, equals(HttpRequest.DONE));
        validate200Response(xhr);
      }));
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
