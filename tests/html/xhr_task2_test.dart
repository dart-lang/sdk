// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRTask2Test;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';
import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';

class MockProgressEvent implements ProgressEvent {
  final target;
  MockProgressEvent(this.target);

  noSuchMethod(Invocation invocation) {
    throw "missing function in MockProgressEvent";
  }
}

class MockHttpRequestTask implements Future<HttpRequest> {
  final Completer completer = new Completer<MockHttpRequestTask>();
  final HttpRequestTaskSpecification spec;
  final Zone zone;

  MockHttpRequestTask(this.spec, this.zone);

  void trigger(String response) {
    var xhr = new MockHttpRequest(spec, response);
    var arg;
    if (spec.url == "NonExistingFile") {
      arg = new MockProgressEvent(xhr);
    } else {
      arg = xhr;
    }
    zone.runTask(run, this, arg);
  }

  then(onData, {onError}) => completer.future.then(onData, onError: onError);
  catchError(f, {test}) => completer.future.catchError(f, test: test);
  whenComplete(f) => completer.future.whenComplete(f);
  asStream() => completer.future.asStream();
  timeout(timeLimit, {onTimeout}) =>
      completer.future.timeout(timeLimit, onTimeout: onTimeout);

  static create(HttpRequestTaskSpecification spec, Zone zone) {
    return new MockHttpRequestTask(spec, zone);
  }

  static run(MockHttpRequestTask task, value) {
    if (value is HttpRequest) {
      task.completer.complete(value);
    } else {
      task.completer.completeError(value);
    }
  }
}

class MockHttpRequest implements HttpRequest {
  final HttpRequestTaskSpecification spec;
  final response;

  MockHttpRequest(this.spec, this.response);

  noSuchMethod(Invocation invocation) {
    print("isGetter: ${invocation.isGetter}");
    print("isMethod: ${invocation.isMethod}");
    print("memberName: ${invocation.memberName}");
  }

  int get status => spec.url == "NonExistingFile" ? 404 : 200;

  get readyState => HttpRequest.DONE;
  get responseText => "$response";

  Map get responseHeaders => {'content-type': 'text/plain; charset=utf-8',};
}

main() {
  useHtmlIndividualConfiguration();
  unittestConfiguration.timeout = const Duration(milliseconds: 800);

  var urlExpando = new Expando();

  var url = 'some/url.html';

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
        var task = parent.createTask(zone, MockHttpRequestTask.create, spec);
        urlExpando[task] = url;
        tasks.add(task);
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
    void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
        Object task, Object arg) {
      if (tasks.contains(task)) {
        var url = urlExpando[task];
        if (arg is Error || arg is Exception) {
          log.add("failed $url");
        } else {
          if (arg is ProgressEvent) {
            log.add("success $url with progress-event");
          } else if (arg is HttpRequest) {
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

  Future<List> runMocked(response, fun) async {
    var log = [];
    var tasks = [];
    var future = runZoned(fun,
        zoneSpecification: new ZoneSpecification(
            createTask: buildCreateTaskHandler(log, tasks),
            runTask: buildRunTaskHandler(log, tasks)));
    // Wait a full cycle to make sure things settle.
    await new Future(() {});
    var beforeTriggerLog = log.toList();
    log.clear();
    expect(tasks.length, 1);
    tasks.single.trigger(response);
    await future;
    return [beforeTriggerLog, log];
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
    test('XHR.request No file', () async {
      var log = await runMocked("404", () {
        var completer = new Completer();
        HttpRequest.request('NonExistingFile').then((_) {
          fail('Request should not have succeeded.');
        }, onError: expectAsync((error) {
          var xhr = error.target;
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate404(xhr);
          completer.complete('done');
        }));
        return completer.future;
      });
      expect(
          log,
          equals([
            [
              'request NonExistingFile',
              '  method: null withCredentials: null responseType: null '
                  'mimeType: null data: null',
            ],
            ['success NonExistingFile with progress-event']
          ]));
    });

    test('XHR.request file', () async {
      var log = await runMocked('{"feed": {"entry": 499}}', () {
        var completer = new Completer();
        HttpRequest.request(url).then(expectAsync((xhr) {
          expect(xhr.readyState, equals(HttpRequest.DONE));
          validate200Response(xhr);
          completer.complete('done');
        }));
        return completer.future;
      });
      expect(
          log,
          equals([
            [
              'request $url',
              '  method: null withCredentials: null responseType: null '
                  'mimeType: null data: null'
            ],
            ['success $url with http-request']
          ]));
    });

    test('XHR.getString file', () async {
      var log = await runMocked("foo", () {
        return HttpRequest.getString(url).then(expectAsync((str) {}));
      });
      expect(
          log,
          equals([
            [
              'request $url',
              '  method: null withCredentials: null responseType: null '
                  'mimeType: null data: null'
            ],
            ['success $url with http-request']
          ]));
    });

    test('XHR.request responseType arraybuffer', () async {
      if (Platform.supportsTypedData) {
        var data = new Uint8List(128);
        var log = await runMocked(data.buffer, () {
          return HttpRequest.request(url,
              responseType: 'arraybuffer',
              requestHeaders: {
                'Content-Type': 'text/xml'
              }).then(expectAsync((xhr) {
            expect(xhr.status, equals(200));
            var byteBuffer = xhr.response;
            expect(byteBuffer, new isInstanceOf<ByteBuffer>());
            expect(byteBuffer, isNotNull);
          }));
        });
        expect(
            log,
            equals([
              [
                'request $url',
                '  method: null withCredentials: null responseType: arraybuffer'
                    ' mimeType: null data: null'
              ],
              ['success $url with http-request']
            ]));
      }
      ;
    });
  });
}
