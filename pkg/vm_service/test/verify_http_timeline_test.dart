// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--timeline_streams=Dart

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'verify_http_timeline_lib.dart' as testee_lib;

bool isStartEvent(Map event) => event['ph'] == 'b';
bool isFinishEvent(Map event) => event['ph'] == 'e';

bool hasCompletedEvents(List<TimelineEvent> traceEvents) {
  final events = <String, int>{};
  for (final event in traceEvents) {
    final id = event.json!['id'];
    events.putIfAbsent(id, () => 0);
    if (isStartEvent(event.json!)) {
      events[id] = events[id]! + 1;
    } else if (isFinishEvent(event.json!)) {
      events[id] = events[id]! - 1;
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

List<TimelineEvent> filterEventsByName(
  List<TimelineEvent> traceEvents,
  String name,
) =>
    traceEvents.where((e) => e.json!.containsKey(name)).toList();

List<TimelineEvent> filterEventsByIdAndName(
  List<TimelineEvent> traceEvents,
  String id,
  String name,
) =>
    traceEvents
        .where((e) => e.json!['id'] == id && e.json!['name'].contains(name))
        .toList();

void hasValidHttpConnections(List<TimelineEvent> traceEvents) {
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

void hasValidHttpRequests(
  HttpProfile profile,
  List<TimelineEvent> traceEvents,
  String method,
) {
  final requests = profile.requests
      .where(
        (element) => element.method == method,
      )
      .toList();
  expect(requests.length, 10);

  var events = filterEventsByName(traceEvents, 'HTTP CLIENT $method');
  for (final event in events) {
    final json = event.json!;
    if (isStartEvent(json)) {
      validateHttpStartEvent(event.json!, method);
      final id = json['id'];

      // HttpProfile request IDs should match up with their corresponding
      // timeline event IDS.
      final httpProfileRequest =
          requests.singleWhere((element) => element.id == id);
      expect(httpProfileRequest.id, id);
    } else if (isFinishEvent(json)) {
      validateHttpFinishEvent(json);
    } else {
      fail('unexpected event type: ${json["ph"]}');
    }
  }

  // Check response body matches string stored in the map.
  events = filterEventsByName(traceEvents, 'HTTP CLIENT response of $method');
  if (method == 'DELETE') {
    // It called listen().
    expect(hasCompletedEvents(events), isTrue);
  }
  for (final event in events) {
    final json = event.json!;
    // Each response will be associated with a request.
    if (isFinishEvent(json)) {
      continue;
    }
    final id = json['id'];
    final data = filterEventsByIdAndName(traceEvents, id, 'Response body');
    if (data.isNotEmpty) {
      expect(data.length, 1);
      expect(utf8.encode(method), data[0].json!['args']['data']);
    }
  }
}

void hasValidHttpProfile(HttpProfile profile, String method) {
  expect(profile.requests.where((e) => e.method == method).length, 10);
}

void hasValidHttpCONNECTs(
  HttpProfile profile,
  List<TimelineEvent> traceEvents,
) =>
    hasValidHttpRequests(profile, traceEvents, 'CONNECT');
void hasValidHttpDELETEs(
  HttpProfile profile,
  List<TimelineEvent> traceEvents,
) =>
    hasValidHttpRequests(profile, traceEvents, 'DELETE');
void hasValidHttpGETs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'GET');
void hasValidHttpHEADs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'HEAD');
void hasValidHttpPATCHs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'PATCH');
void hasValidHttpPOSTs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'POST');
void hasValidHttpPUTs(HttpProfile profile, List<TimelineEvent> traceEvents) =>
    hasValidHttpRequests(profile, traceEvents, 'PUT');

Future<void> testTimeline(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;

  final httpProfile = await service.getHttpProfile(isolateId);
  expect(httpProfile.requests.length, 70);

  // Verify timeline events.
  final result = await service.getVMTimeline();
  final traceEvents = result.traceEvents!;
  expect(traceEvents.isNotEmpty, isTrue);
  hasValidHttpConnections(traceEvents);
  hasValidHttpCONNECTs(httpProfile, traceEvents);
  hasValidHttpDELETEs(httpProfile, traceEvents);
  hasValidHttpGETs(httpProfile, traceEvents);
  hasValidHttpHEADs(httpProfile, traceEvents);
  hasValidHttpPATCHs(httpProfile, traceEvents);
  hasValidHttpPOSTs(httpProfile, traceEvents);
  hasValidHttpPUTs(httpProfile, traceEvents);
}

void main([List<String> args = const <String>[]]) {
  late IsolateTestHarness harness;
  harness = IsolateTestHarness(
    'verify_http_timeline_lib.dart',
    args,
  ).addCustomTest(testTimeline);
  harness.run(testeeMain: testee_lib.main);
}
