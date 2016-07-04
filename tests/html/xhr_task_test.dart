// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRTaskTest;

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

  var urlExpando = new Expando();

  Function buildCreateTaskHandler(List log, List tasks) {
    Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
        TaskCreate create, TaskSpecification spec) {
      if (spec is HttpRequestTaskSpecification) {
        var url = spec.url;
        var method = spec.method;
        var withCredentials = spec.withCredentials;
        var responseType = spec.responseType;
        var mimeType = spec.mimeType;
        var data = spec.sendData;

        log.add("request $url");
        var dataLog = data is List<int> ? "binary ${data.length}" : "$data";
        log.add("  method: $method withCredentials: $withCredentials "
            "responseType: $responseType mimeType: $mimeType data: $dataLog");
        var task = parent.createTask(zone, create, spec);
        urlExpando[task] = url;
        tasks.add(task);
        return task;
      }
      if (spec is HttpRequestSendTaskSpecification) {
        var data = spec.sendData;
        var dataLog = data is List<int> ? "binary ${data.length}" : "$data";
        log.add("http-request (no info), data: $dataLog");
        var task = parent.createTask(zone, create, spec);
        tasks.add(task);
        urlExpando[task] = "unknown";
        return task;
      }
      if (spec is EventSubscriptionSpecification) {
        EventSubscriptionSpecification eventSpec = spec;
        if (eventSpec.target is HttpRequest) {
          HttpRequest target = eventSpec.target;
          log.add("event listener on http-request ${eventSpec.eventType}");
          if (eventSpec.eventType == "readystatechange") {
            var oldOnData = eventSpec.onData;
            spec = eventSpec.replace(onData: (event) {
              oldOnData(event);
              if (target.readyState == HttpRequest.DONE) {
                log.add("unknown request done");
              }
            });
          }
        }
      }
      return parent.createTask(zone, create, spec);
    }

    return createTaskHandler;
  }

  Function buildRunTaskHandler(List log, List tasks) {
    void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
        TaskRun run, Object task, Object arg) {
      if (tasks.contains(task)) {
        var url = urlExpando[task];
        if (arg is Error || arg is Exception) {
          log.add("failed $url");
        } else {
          if (arg is ProgressEvent) {
            log.add("success $url with progress-event");
          } else if (arg is HttpRequest){
            log.add("success $url with http-request");
          } else {
            log.add("success $url (unknown arg)");
          }
        }
      }
      parent.runTask(zone, run, task, arg);
    }

    return runTaskHandler;
  }

  Future<List> runWithLogging(fun) async {
    var log = [];
    var tasks = [];
    await runZoned(fun, zoneSpecification: new ZoneSpecification(
        createTask: buildCreateTaskHandler(log, tasks),
        runTask: buildRunTaskHandler(log, tasks)));
    return log;
  }

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

  group('xhr', () {
    test('XHR No file', () async {
      var log = await runWithLogging(() {
        var completer = new Completer();
        HttpRequest xhr = new HttpRequest();
        xhr.open("GET", "NonExistingFile", async: true);
        xhr.onReadyStateChange.listen(expectAsyncUntil((event) {
          if (xhr.readyState == HttpRequest.DONE) {
            validate404(xhr);
            completer.complete("done");
          }
        }, () => xhr.readyState == HttpRequest.DONE));
        xhr.send();
        return completer.future;
      });
      expect(log, equals([
        'event listener on http-request readystatechange',
        'http-request (no info), data: null',
        'unknown request done'
      ]));
    });

    test('XHR_file', () async {
      var log = await runWithLogging(() {
        var completer = new Completer();
        var loadEndCalled = false;

        var xhr = new HttpRequest();
        xhr.open('GET', url, async: true);
        xhr.onReadyStateChange.listen(expectAsyncUntil((e) {
          if (xhr.readyState == HttpRequest.DONE) {
            validate200Response(xhr);

            Timer.run(expectAsync(() {
              expect(loadEndCalled, HttpRequest.supportsLoadEndEvent);
              completer.complete("done");
            }));
          }
        }, () => xhr.readyState == HttpRequest.DONE));

        xhr.onLoadEnd.listen((ProgressEvent e) {
          loadEndCalled = true;
        });
        xhr.send();
        return completer.future;
      });
      expect(log, equals([
        'event listener on http-request readystatechange',
        'event listener on http-request loadend',
        'http-request (no info), data: null',
        'unknown request done'
      ]));
    });

    test('XHR.request No file', () async {
      var log = await runWithLogging(() {
        var completer = new Completer();
        HttpRequest.request('NonExistingFile').then(
            (_) { fail('Request should not have succeeded.'); },
            onError: expectAsync((error) {
              var xhr = error.target;
              expect(xhr.readyState, equals(HttpRequest.DONE));
              validate404(xhr);
              completer.complete('done');
            }));
        return completer.future;
      });
      expect(log, equals([
        'request NonExistingFile',
        '  method: null withCredentials: null responseType: null '
            'mimeType: null data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success NonExistingFile with progress-event'
      ]));
    });

    test('XHR.request file', () async {
      var log = await runWithLogging(() {
        var completer = new Completer();
        HttpRequest.request(url).then(expectAsync((xhr) {
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate200Response(xhr);
          completer.complete('done');
        }));
        return completer.future;
      });
      expect(log, equals([
        'request $url',
        '  method: null withCredentials: null responseType: null '
            'mimeType: null data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });

    test('XHR.request onProgress', () async {
      var log = await runWithLogging(() {
        var completer = new Completer();
        var progressCalled = false;
        HttpRequest.request(url,
            onProgress: (_) {
              progressCalled = true;
            }).then(expectAsync(
            (xhr) {
              expect(xhr.readyState, equals(HttpRequest.DONE));
              expect(progressCalled, HttpRequest.supportsProgressEvent);
              validate200Response(xhr);
              completer.complete("done");
        }));
        return completer.future;
      });
      expect(log, equals([
        'request $url',
        '  method: null withCredentials: null responseType: null '
            'mimeType: null data: null',
        'event listener on http-request progress',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });

    test('XHR.request withCredentials No file', () async {
      var log = await runWithLogging(() {
        var completer = new Completer();
        HttpRequest.request('NonExistingFile', withCredentials: true).then(
            (_) { fail('Request should not have succeeded.'); },
            onError: expectAsync((error) {
              var xhr = error.target;
              expect(xhr.readyState, equals(HttpRequest.DONE));
              validate404(xhr);
              completer.complete("done");
            }));
        return completer.future;
      });
      expect(log, equals([
        'request NonExistingFile',
        '  method: null withCredentials: true responseType: null '
            'mimeType: null data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success NonExistingFile with progress-event'
      ]));
    });


    test('XHR.request withCredentials file', () async {
      var log = await runWithLogging(() {
        var completer = new Completer();
        HttpRequest.request(url, withCredentials: true).then(expectAsync((xhr) {
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate200Response(xhr);
          completer.complete("done");
        }));
        return completer.future;
      });
      expect(log, equals([
        'request $url',
        '  method: null withCredentials: true responseType: null '
            'mimeType: null data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });

    test('XHR.getString file', () async {
      var log = await runWithLogging(() {
        return HttpRequest.getString(url).then(expectAsync((str) {}));
      });
      expect(log, equals([
        'request $url',
        '  method: null withCredentials: null responseType: null '
            'mimeType: null data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });

    test('XHR.getString No file', () async {
      var log = await runWithLogging(() {
        return HttpRequest.getString('NonExistingFile').then(
            (_) { fail('Succeeded for non-existing file.'); },
            onError: expectAsync((error) {
              validate404(error.target);
            }));
      });
      expect(log, equals([
        'request NonExistingFile',
        '  method: null withCredentials: null responseType: null '
            'mimeType: null data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success NonExistingFile with progress-event'
      ]));
    });

    test('XHR.request responseType arraybuffer', () async {
      if (Platform.supportsTypedData) {
        var log = await runWithLogging(() {
          return HttpRequest.request(url, responseType: 'arraybuffer',
              requestHeaders: {'Content-Type': 'text/xml'}).then(
              expectAsync((xhr) {
                expect(xhr.status, equals(200));
                var byteBuffer = xhr.response;
                expect(byteBuffer, new isInstanceOf<ByteBuffer>());
                expect(byteBuffer, isNotNull);
              }));
        });
        expect(log, equals([
          'request $url',
          '  method: null withCredentials: null responseType: arraybuffer '
              'mimeType: null data: null',
          'event listener on http-request load',
          'event listener on http-request error',
          'success $url with http-request'
        ]));
      };
    });

    test('overrideMimeType', () async {
      var expectation =
          HttpRequest.supportsOverrideMimeType ? returnsNormally : throws;

      var log = await runWithLogging(() {
        var completer = new Completer();
        expect(() {
          HttpRequest.request(url, mimeType: 'application/binary')
              .whenComplete(completer.complete);
        }, expectation);
        return completer.future;
      });
      expect(log, equals([
        'request $url',
        '  method: null withCredentials: null responseType: null '
            'mimeType: application/binary data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });

    if (Platform.supportsTypedData) {
      test('xhr upload', () async {
        var log = await runWithLogging(() {
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
            expect(
                progressCalled, isTrue, reason: 'onProgress should be fired');
          });
        });
        expect(log, equals([
          'http-request (no info), data: binary 1048576',
          'event listener on http-request load',
        ]));
      });
    }

    test('xhr postFormData', () async {
      var url = '${window.location.protocol}//${window.location.host}/echo';
      var log = await runWithLogging(() {
        var data = { 'name': 'John', 'time': '2 pm'};

        var parts = [];
        for (var key in data.keys) {
          parts.add('${Uri.encodeQueryComponent(key)}='
              '${Uri.encodeQueryComponent(data[key])}');
        }
        var encodedData = parts.join('&');

        return HttpRequest.postFormData(url, data).then((xhr) {
          expect(xhr.responseText, encodedData);
        });
      });
      expect(log, equals([
        'request $url',
        '  method: POST withCredentials: null responseType: null '
            'mimeType: null data: name=John&time=2+pm',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });
  });

  group('xhr_requestBlob', () {
    test('XHR.request responseType blob', () async {
      if (Platform.supportsTypedData) {
        var log = await runWithLogging(() {
          return HttpRequest.request(url, responseType: 'blob').then(
              (xhr) {
            expect(xhr.status, equals(200));
            var blob = xhr.response;
            expect(blob is Blob, isTrue);
            expect(blob, isNotNull);
          });
        });
        expect(log, equals([
          'request $url',
          '  method: null withCredentials: null responseType: blob '
              'mimeType: null data: null',
          'event listener on http-request load',
          'event listener on http-request error',
          'success $url with http-request'
        ]));
      }
    });
  });

  group('json', () {
    test('xhr responseType json', () async {
      var url = '${window.location.protocol}//${window.location.host}/echo';
      var log = await runWithLogging(() {
        var completer = new Completer();
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
              completer.complete("done");
            }));
        return completer.future;
      });
      expect(log, equals([
        'request $url',
        '  method: POST withCredentials: null responseType: json mimeType: null'
            ' data: {"key":"value","a":"b","one":2}',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });
  });

  group('headers', () {
    test('xhr responseHeaders', () async {
      var log = await runWithLogging(() {
        return HttpRequest.request(url).then(
            (xhr) {
          var contentTypeHeader = xhr.responseHeaders['content-type'];
          expect(contentTypeHeader, isNotNull);
          // Should be like: 'text/plain; charset=utf-8'
          expect(contentTypeHeader.contains('text/plain'), isTrue);
          expect(contentTypeHeader.contains('charset=utf-8'), isTrue);
        });
      });
      expect(log, equals([
        'request $url',
        '  method: null withCredentials: null responseType: null'
            ' mimeType: null data: null',
        'event listener on http-request load',
        'event listener on http-request error',
        'success $url with http-request'
      ]));
    });
  });
}
