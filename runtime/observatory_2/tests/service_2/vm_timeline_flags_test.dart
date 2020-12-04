// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

primeDartTimeline() {
  while (true) {
    Timeline.startSync('apple');
    Timeline.finishSync();
    debugger();
  }
}

bool isDart(event) => event['cat'] == 'Dart';
bool isMetaData(event) => event['ph'] == 'M';
bool isNotMetaData(event) => !isMetaData(event);
bool isNotDartAndMetaData(event) => !isDart(event) && !isMetaData(event);

List filterEvents(List events, filter) {
  return events.where(filter).toList();
}

int dartEventCount;

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
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
    // Get the timeline.
    Map result = await isolate.vm.invokeRpcNoUpgrade('getVMTimeline', {});
    expect(result['type'], equals('Timeline'));
    expect(result['traceEvents'], isA<List>());
    // Confirm that it as no non-meta data events.
    expect(filterEvents(result['traceEvents'], isNotMetaData).length, 0);
  },
  (Isolate isolate) async {
    final completer = Completer<void>();
    await subscribeToStream(isolate.vm, 'Timeline', (event) async {
      expect(event.kind, ServiceEvent.kTimelineStreamSubscriptionsUpdate);
      expect(event.updatedStreams.length, 1);
      expect(event.updatedStreams.first, 'Dart');
      await cancelStreamSubscription('Timeline');
      completer.complete();
    });
    // Enable the Dart category.
    await isolate.vm.invokeRpcNoUpgrade('setVMTimelineFlags', {
      "recordedStreams": ["Dart"]
    });
    await completer.future;
  },
  (Isolate isolate) async {
    // Get the flags.
    Map flags = await isolate.vm.invokeRpcNoUpgrade('getVMTimelineFlags', {});
    expect(flags['type'], 'TimelineFlags');
    // Confirm that only Dart is being recorded.
    expect(flags['recordedStreams'].length, equals(1));
    expect(flags['recordedStreams'].contains('Dart'), isTrue);
    print(flags);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Get the timeline.
    Map result = await isolate.vm.invokeRpcNoUpgrade('getVMTimeline', {});
    expect(result['type'], equals('Timeline'));
    expect(result['traceEvents'], isA<List>());
    print(result['traceEvents']);
    // Confirm that Dart events are added.
    expect(filterEvents(result['traceEvents'], isDart).length, greaterThan(0));
    // Confirm that zero non-Dart events are added.
    expect(filterEvents(result['traceEvents'], isNotDartAndMetaData).length,
        equals(0));
  },
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    final completer = Completer<void>();
    await subscribeToStream(isolate.vm, 'Timeline', (event) async {
      expect(event.kind, ServiceEvent.kTimelineStreamSubscriptionsUpdate);
      expect(event.updatedStreams.length, 0);
      await cancelStreamSubscription('Timeline');
      completer.complete();
    });

    // Disable the Dart category.
    await isolate.vm
        .invokeRpcNoUpgrade('setVMTimelineFlags', {"recordedStreams": []});
    // Grab the timeline and remember the number of Dart events.
    Map result = await isolate.vm.invokeRpcNoUpgrade('getVMTimeline', {});
    expect(result['type'], equals('Timeline'));
    expect(result['traceEvents'], isA<List>());
    dartEventCount = filterEvents(result['traceEvents'], isDart).length;

    await completer.future;
  },
  (Isolate isolate) async {
    // Get the flags.
    Map flags = await isolate.vm.invokeRpcNoUpgrade('getVMTimelineFlags', {});
    expect(flags['type'], 'TimelineFlags');
    // Confirm that 'Dart' is not being recorded.
    expect(flags['recordedStreams'].length, equals(0));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Grab the timeline and verify that we haven't added any new Dart events.
    Map result = await isolate.vm.invokeRpcNoUpgrade('getVMTimeline', {});
    expect(result['type'], equals('Timeline'));
    expect(result['traceEvents'], isA<List>());
    expect(filterEvents(result['traceEvents'], isDart).length, dartEventCount);
    // Confirm that zero non-Dart events are added.
    expect(filterEvents(result['traceEvents'], isNotDartAndMetaData).length,
        equals(0));
  },
];

main(args) async =>
    runIsolateTests(args, tests, testeeConcurrent: primeDartTimeline);
