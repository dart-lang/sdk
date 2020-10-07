// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--timeline_streams=Dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

final rng = Random();

// Enable to test redirects.
const shouldTestRedirects = false;

const maxRequestDelayMs = 3000;
const maxResponseDelayMs = 500;
const serverShutdownDelayMs = 2000;

void randomlyAddCookie(HttpResponse response) {
  if (rng.nextInt(3) == 0) {
    response.cookies.add(Cookie('Cookie-Monster', 'Me-want-cookie!'));
  }
}

Future<bool> randomlyRedirect(HttpServer server, HttpResponse response) async {
  if (shouldTestRedirects && rng.nextInt(5) == 0) {
    final redirectUri = Uri(host: 'www.google.com', port: 80);
    response.redirect(redirectUri);
    return true;
  }
  return false;
}

// Execute HTTP requests with random delays so requests have some overlap. This
// way we can be certain that timeline events are matching up properly even when
// connections are interrupted or can't be established.
Future<void> executeWithRandomDelay(Function f) =>
    Future<void>.delayed(Duration(milliseconds: rng.nextInt(maxRequestDelayMs)))
        .then((_) async {
      try {
        await f();
      } on HttpException catch (_) {} on SocketException catch (_) {} on StateError catch (_) {} on OSError catch (_) {}
    });

Uri randomlyAddRequestParams(Uri uri) {
  const possiblePathSegments = <String>['foo', 'bar', 'baz', 'foobar'];
  final segmentSubset =
      possiblePathSegments.sublist(0, rng.nextInt(possiblePathSegments.length));
  uri = uri.replace(pathSegments: segmentSubset);
  if (rng.nextInt(3) == 0) {
    uri = uri.replace(queryParameters: {
      'foo': 'bar',
      'year': '2019',
    });
  }
  return uri;
}

Future<HttpServer> startServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final response = request.response;
    response.write(request.method);
    randomlyAddCookie(response);
    if (await randomlyRedirect(server, response)) {
      // Redirect calls close() on the response.
      return;
    }
    // Randomly delay response.
    await Future.delayed(
        Duration(milliseconds: rng.nextInt(maxResponseDelayMs)));
    response.close();
  });
  return server;
}

Future<void> testMain() async {
  // Ensure there's a chance some requests will be interrupted.
  Expect.isTrue(maxRequestDelayMs > serverShutdownDelayMs);
  Expect.isTrue(maxResponseDelayMs < serverShutdownDelayMs);

  final server = await startServer();
  HttpClient.enableTimelineLogging = true;
  final client = HttpClient();
  final requests = <Future>[];
  final address =
      Uri(scheme: 'http', host: server.address.host, port: server.port);

  // HTTP DELETE
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.deleteUrl(randomlyAddRequestParams(address));
      final string = 'DELETE $address';
      r.headers.add(HttpHeaders.contentLengthHeader, string.length);
      r.write(string);
      final response = await r.close();
      response.listen((_) {});
    });
    requests.add(future);
  }

  // HTTP GET
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.getUrl(randomlyAddRequestParams(address));
      final response = await r.close();
      await response.drain();
    });
    requests.add(future);
  }
  // HTTP HEAD
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.headUrl(randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP CONNECT
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r =
          await client.openUrl('connect', randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP PATCH
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.patchUrl(randomlyAddRequestParams(address));
      final response = await r.close();
      response.listen(null);
    });
    requests.add(future);
  }

  // HTTP POST
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.postUrl(randomlyAddRequestParams(address));
      r.add(Uint8List.fromList([0, 1, 2]));
      await r.close();
    });
    requests.add(future);
  }

  // HTTP PUT
  for (int i = 0; i < 10; ++i) {
    final future = executeWithRandomDelay(() async {
      final r = await client.putUrl(randomlyAddRequestParams(address));
      await r.close();
    });
    requests.add(future);
  }

  // Purposefully close server before some connections can be made to ensure
  // that refused / interrupted connections correctly create finish timeline
  // events.
  await Future.delayed(Duration(milliseconds: serverShutdownDelayMs));
  await server.close();

  // Ensure all requests complete before finishing.
  await Future.wait(requests);
}

bool isStartEvent(Map event) => (event['ph'] == 'b');
bool isFinishEvent(Map event) => (event['ph'] == 'e');

bool hasCompletedEvents(List traceEvents) {
  final events = <String, int>{};
  for (final event in traceEvents) {
    final id = event['id'];
    events.putIfAbsent(id, () => 0);
    if (isStartEvent(event)) {
      events[id]++;
    } else if (isFinishEvent(event)) {
      events[id]--;
    }
  }
  bool valid = true;
  events.forEach((id, count) {
    if (count != 0) {
      valid = false;
    }
  });
  return valid;
}

List filterEventsByName(List traceEvents, String name) =>
    traceEvents.where((e) => e['name'].contains(name)).toList();

List filterEventsByIdAndName(List traceEvents, String id, String name) =>
    traceEvents
        .where((e) => e['id'] == id && e['name'].contains(name))
        .toList();

void hasValidHttpConnections(List traceEvents) {
  final events = filterEventsByName(traceEvents, 'HTTP Connection');
  expect(hasCompletedEvents(events), isTrue);
}

void validateHttpStartEvent(Map event, String method) {
  expect(event.containsKey('args'), isTrue);
  final args = event['args'];
  expect(args.containsKey('method'), isTrue);
  expect(args['method'], method);
  expect(args['filterKey'], 'HTTP/client');
  expect(args.containsKey('uri'), isTrue);
}

void validateHttpFinishEvent(Map event) {
  expect(event.containsKey('args'), isTrue);
  final args = event['args'];
  expect(args['filterKey'], 'HTTP/client');
  if (!args.containsKey('error')) {
    expect(args.containsKey('requestHeaders'), isTrue);
    expect(args['requestHeaders'] != null, isTrue);
    expect(args.containsKey('compressionState'), isTrue);
    expect(args.containsKey('connectionInfo'), isTrue);
    expect(args.containsKey('contentLength'), isTrue);
    expect(args.containsKey('cookies'), isTrue);
    expect(args.containsKey('responseHeaders'), isTrue);
    expect(args.containsKey('isRedirect'), isTrue);
    expect(args.containsKey('persistentConnection'), isTrue);
    expect(args.containsKey('reasonPhrase'), isTrue);
    expect(args.containsKey('redirects'), isTrue);
    expect(args.containsKey('statusCode'), isTrue);
    // If proxyInfo is non-null, uri and port _must_ be non-null.
    if (args.containsKey('proxyInfo')) {
      final proxyInfo = args['proxyInfo'];
      expect(proxyInfo.containsKey('uri'), isTrue);
      expect(proxyInfo.containsKey('port'), isTrue);
    }
  }
}

void hasValidHttpRequests(List traceEvents, String method) {
  var events = filterEventsByName(traceEvents, 'HTTP CLIENT $method');
  for (final event in events) {
    if (isStartEvent(event)) {
      validateHttpStartEvent(event, method);
      // Check body of request has been sent and recorded correctly.
      if (method == 'DELETE' || method == 'POST') {
        final id = event['id'];
        final bodyEvent =
            filterEventsByIdAndName(traceEvents, id, 'Request body');
        // Due to randomness, it doesn't guarantee to have the timeline events.
        if (bodyEvent.length == 1) {
          if (method == 'POST') {
            // add() was used
            Expect.listEquals(
                <int>[0, 1, 2], bodyEvent[0]['args']['encodedData']);
          } else {
            // write() was used.
            Expect.isTrue(
                bodyEvent[0]['args']['data'].startsWith('$method http'));
          }
        }
      }
    } else if (isFinishEvent(event)) {
      validateHttpFinishEvent(event);
    } else {
      fail('unexpected event type: ${event["ph"]}');
    }
  }

  // Check response body matches string stored in the map.
  events = filterEventsByName(traceEvents, 'HTTP CLIENT response of $method');
  if (method == 'DELETE') {
    // It called listen().
    expect(hasCompletedEvents(events), isTrue);
  }
  for (final event in events) {
    // Each response will be associated with a request.
    if (isFinishEvent(event)) {
      continue;
    }
    final id = event['id'];
    final data = filterEventsByIdAndName(traceEvents, id, 'Response body');
    if (data.length != 0) {
      Expect.equals(1, data.length);
      Expect.listEquals(utf8.encode(method), data[0]['args']['data']);
    }
  }
}

void hasValidHttpCONNECTs(List traceEvents) =>
    hasValidHttpRequests(traceEvents, 'CONNECT');
void hasValidHttpDELETEs(List traceEvents) =>
    hasValidHttpRequests(traceEvents, 'DELETE');
void hasValidHttpGETs(List traceEvents) =>
    hasValidHttpRequests(traceEvents, 'GET');
void hasValidHttpHEADs(List traceEvents) =>
    hasValidHttpRequests(traceEvents, 'HEAD');
void hasValidHttpPATCHs(List traceEvents) =>
    hasValidHttpRequests(traceEvents, 'PATCH');
void hasValidHttpPOSTs(List traceEvents) =>
    hasValidHttpRequests(traceEvents, 'POST');
void hasValidHttpPUTs(List traceEvents) =>
    hasValidHttpRequests(traceEvents, 'PUT');

var tests = <IsolateTest>[
  (Isolate isolate) async {
    final result = await isolate.vm.invokeRpcNoUpgrade('getVMTimeline', {});
    expect(result['type'], 'Timeline');
    expect(result.containsKey('traceEvents'), isTrue);
    final traceEvents = result['traceEvents'];
    expect(traceEvents.length > 0, isTrue);
    hasValidHttpConnections(traceEvents);
    hasValidHttpCONNECTs(traceEvents);
    hasValidHttpDELETEs(traceEvents);
    hasValidHttpGETs(traceEvents);
    hasValidHttpHEADs(traceEvents);
    hasValidHttpPATCHs(traceEvents);
    hasValidHttpPOSTs(traceEvents);
    hasValidHttpPUTs(traceEvents);
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: testMain);
