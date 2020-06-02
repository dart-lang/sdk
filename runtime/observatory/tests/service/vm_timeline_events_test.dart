// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

primeDartTimeline() async {
  while (true) {
    Timeline.startSync('apple');
    Timeline.finishSync();
    // Give the VM a chance to send the timeline events. This test is
    // significantly slower if we loop without yielding control after each
    // iteration.
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

bool isDart(event) => event['cat'] == 'Dart';

List filterEvents(List events, filter) {
  return events.where(filter).toList();
}

late Completer<void> completer;
int eventCount = 0;

onTimelineEvent(ServiceEvent event) {
  if (event.kind != ServiceEvent.kTimelineEvents) {
    return;
  }
  eventCount++;
  expect(filterEvents(event.timelineEvents!, isDart).length, greaterThan(0));
  if (eventCount == 5) {
    completer.complete(eventCount);
  }
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    // Clear global state.
    eventCount = 0;
    completer = Completer<void>();
  },
  (Isolate isolate) async {
    // Subscribe to the Timeline stream.
    await subscribeToStream(isolate.vm, VM.kTimelineStream, onTimelineEvent);
  },
  (Isolate isolate) async {
    // Ensure we don't get any events before enabling Dart.
    await new Future.delayed(new Duration(seconds: 5));
    expect(eventCount, 0);
  },
  (Isolate isolate) async {
    // Get the flags.
    Map flags = await isolate.vm.invokeRpcNoUpgrade('getVMTimelineFlags', {});
    expect(flags['type'], 'TimelineFlags');
    // Confirm that 'Dart' is available.
    expect(flags['availableStreams'].contains('Dart'), isTrue);
    // Confirm that nothing is being recorded.
    expect(flags['recordedStreams'].length, equals(0));
  },
  (Isolate isolate) async {
    // Enable the Dart category.
    await isolate.vm.invokeRpcNoUpgrade('setVMTimelineFlags', {
      "recordedStreams": ["Dart"]
    });
  },
  (Isolate isolate) async {
    // Wait to receive events.
    await completer.future;
    cancelStreamSubscription(VM.kTimelineStream);
  },
];

main(args) async =>
    runIsolateTests(args, tests, testeeConcurrent: primeDartTimeline);
