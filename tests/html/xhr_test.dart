// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRTest;
import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';
import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useHtmlIndividualConfiguration();
  // Cache blocker is a workaround for:
  // https://code.google.com/p/dart/issues/detail?id=11834
  var cacheBlocker = new DateTime.now().millisecondsSinceEpoch;
  var url = '/root_dart/tests/html/xhr_cross_origin_data.txt?'
      'cacheBlock=$cacheBlocker';

  void validate200Response(xhr) {
    expect(xhr.status, equals(200));
    var data = JSON.decode(xhr.responseText);
    expect(data, contains('feed'));
    expect(data['feed'], contains('entry'));
    expect(data, isMap);
  }

  void validate404(xhr) {
    expect(xhr.status, equals(404));
    // We cannot say much about xhr.responseText, most HTTP servers will
    // include an HTML page explaining the error to a human.
    String responseText = xhr.responseText;
    expect(responseText, isNotNull);
  }

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

  group('supported_overrideMimeType', () {
    test('supported', () {
      expect(HttpRequest.supportsOverrideMimeType, isTrue);
    });
  });

  group('xhr', () {
    test('XHR No file', () {
      HttpRequest xhr = new HttpRequest();
      xhr.open("GET", "NonExistingFile", async: true);
      xhr.onReadyStateChange.listen(expectAsyncUntil((event) {
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
      xhr.onReadyStateChange.listen(expectAsyncUntil((e) {
        if (xhr.readyState == HttpRequest.DONE) {
          validate200Response(xhr);

          Timer.run(expectAsync(() {
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
        onError: expectAsync((error) {
          var xhr = error.target;
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate404(xhr);
        }));
    });

    test('XHR.request file', () {
      HttpRequest.request(url).then(expectAsync((xhr) {
        expect(xhr.readyState, equals(HttpRequest.DONE));
        validate200Response(xhr);
      }));
    });

    test('XHR.request onProgress', () {
      var progressCalled = false;
      HttpRequest.request(url,
        onProgress: (_) {
          progressCalled = true;
        }).then(expectAsync(
          (xhr) {
            expect(xhr.readyState, equals(HttpRequest.DONE));
            expect(progressCalled, HttpRequest.supportsProgressEvent);
            validate200Response(xhr);
          }));
    });

    test('XHR.request withCredentials No file', () {
      HttpRequest.request('NonExistingFile', withCredentials: true).then(
        (_) { fail('Request should not have succeeded.'); },
        onError: expectAsync((error) {
          var xhr = error.target;
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate404(xhr);
        }));
    });

    test('XHR.request withCredentials file', () {
      HttpRequest.request(url, withCredentials: true).then(expectAsync((xhr) {
        expect(xhr.readyState, equals(HttpRequest.DONE));
        validate200Response(xhr);
      }));
    });

    test('XHR.getString file', () {
      HttpRequest.getString(url).then(expectAsync((str) {}));
    });

    test('XHR.getString No file', () {
      HttpRequest.getString('NonExistingFile').then(
        (_) { fail('Succeeded for non-existing file.'); },
        onError: expectAsync((error) {
          validate404(error.target);
        }));
    });

    test('XHR.request responseType arraybuffer', () {
      if (Platform.supportsTypedData) {
        HttpRequest.request(url, responseType: 'arraybuffer',
          requestHeaders: {'Content-Type': 'text/xml'}).then(
          expectAsync((xhr) {
            expect(xhr.status, equals(200));
            var byteBuffer = xhr.response;
            expect(byteBuffer, new isInstanceOf<ByteBuffer>());
            expect(byteBuffer, isNotNull);
          }));
      }
    });

    test('overrideMimeType', () {
      var expectation =
          HttpRequest.supportsOverrideMimeType ? returnsNormally : throws;

      expect(() {
        HttpRequest.request(url, mimeType: 'application/binary');
      }, expectation);
    });

    if (Platform.supportsTypedData) {
      test('xhr upload', () {
        var xhr = new HttpRequest();
        var progressCalled = false;
        xhr.upload.onProgress.listen((e) {
          progressCalled = true;
        });

        xhr.open('POST',
              '${window.location.protocol}//${window.location.host}/echo');

        // 10MB of payload data w/ a bit of data to make sure it
        // doesn't get compressed to nil.
        var data = new Uint8List(1 * 1024 * 1024);
        for (var i = 0; i < data.length; ++i) {
          data[i] = i & 0xFF;
        }
        xhr.send(new Uint8List.view(data.buffer));

        return xhr.onLoad.first.then((_) {
          expect(progressCalled, isTrue, reason: 'onProgress should be fired');
        });
      });
    }

    test('xhr postFormData', () {
      var data = { 'name': 'John', 'time': '2 pm' };

      var parts = [];
      for (var key in data.keys) {
        parts.add('${Uri.encodeQueryComponent(key)}='
          '${Uri.encodeQueryComponent(data[key])}');
      }
      var encodedData = parts.join('&');

      return HttpRequest.postFormData(
          '${window.location.protocol}//${window.location.host}/echo', data)
          .then((xhr) {
          expect(xhr.responseText, encodedData);
        });
    });
  });

  group('xhr_requestBlob', () {
    test('XHR.request responseType blob', () {
      if (Platform.supportsTypedData) {
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

  group('json', () {
    test('xhr responseType json', () {
      var url = '${window.location.protocol}//${window.location.host}/echo';
      var data = {
        'key': 'value',
        'a': 'b',
        'one': 2,
      };

      HttpRequest.request(url,
          method: 'POST',
          sendData: JSON.encode(data),
          responseType: 'json').then(
          expectAsync((xhr) {
            expect(xhr.status, equals(200));
            var json = xhr.response;
            expect(json, equals(data));
          }));
    });
  });

  group('headers', () {
    test('xhr responseHeaders', () {
      return HttpRequest.request(url).then(
        (xhr) {
          var contentTypeHeader = xhr.responseHeaders['content-type'];
          expect(contentTypeHeader, isNotNull);
          // Should be like: 'text/plain; charset=utf-8'
          expect(contentTypeHeader.contains('text/plain'), isTrue);
          expect(contentTypeHeader.contains('charset=utf-8'), isTrue);
        });
    });
  });
}
