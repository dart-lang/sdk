// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override --complete_timeline

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

primeTimeline() {
  Timeline.startSync('apple');
  Timeline.instantSync('ISYNC', arguments: {'fruit': 'banana'});
  Timeline.finishSync();
  TimelineTask task = new TimelineTask();
  task.start('TASK1');
  task.instant('ITASK');
  task.finish();

  Flow flow = Flow.begin();
  Timeline.startSync('peach', flow: flow);
  Timeline.finishSync();
  Timeline.startSync('watermelon', flow: Flow.step(flow.id));
  Timeline.finishSync();
  Timeline.startSync('pear', flow: Flow.end(flow.id));
  Timeline.finishSync();
}

List filterForDartEvents(List events) {
  return events.where((event) => event['cat'] == 'Dart').toList();
}

bool eventsContains(List events, String phase, String name) {
  for (Map event in events) {
    if ((event['ph'] == phase) && (event['name'] == name)) {
      return true;
    }
  }
  return false;
}

int timeOrigin(List events) {
  if (events.length == 0) {
    return 0;
  }
  int smallest = events[0]['ts'];
  for (var i = 0; i < events.length; i++) {
    Map event = events[i];
    if (event['ts'] < smallest) {
      smallest = event['ts'];
    }
  }
  return smallest;
}

int timeDuration(List events, int timeOrigin) {
  if (events.length == 0) {
    return 0;
  }
  int biggestDuration = events[0]['ts'] - timeOrigin;
  for (var i = 0; i < events.length; i++) {
    Map event = events[i];
    int duration = event['ts'] - timeOrigin;
    if (duration > biggestDuration) {
      biggestDuration = duration;
    }
  }
  return biggestDuration;
}

void allEventsHaveIsolateNumber(List events) {
  for (Map event in events) {
    print(event);
    if (event['ph'] == 'M') {
      // Skip meta-data events.
      continue;
    }
    if (event['ph'] == 'C') {
      // Skip counter events, where an isolate id makes Catapult hard to read.
      continue;
    }
    if (event['name'] == 'Runnable' && event['ph'] == 'i') {
      // Skip Runnable events which don't have an isolate.
      continue;
    }
    if (event['cat'] == 'VM') {
      // Skip VM category events which don't have an isolate.
      continue;
    }
    if (event['cat'] == 'API') {
      // Skip API category events which sometimes don't have an isolate.
      continue;
    }
    if (event['cat'] == 'Embedder' &&
        (event['name'] == 'DFE::ReadScript' ||
            event['name'] == 'CreateIsolateAndSetupHelper')) {
      continue;
    }
    Map arguments = event['args'];
    expect(arguments, new isInstanceOf<Map>());
    expect(arguments['isolateNumber'], new isInstanceOf<String>());
  }
}

var tests = <VMTest>[
  (VM vm) async {
    Map result = await vm.invokeRpcNoUpgrade('_getVMTimeline', {});
    expect(result['type'], equals('_Timeline'));
    expect(result['traceEvents'], new isInstanceOf<List>());
    final int numEvents = result['traceEvents'].length;
    List dartEvents = filterForDartEvents(result['traceEvents']);
    expect(dartEvents.length, equals(11));
    allEventsHaveIsolateNumber(dartEvents);
    allEventsHaveIsolateNumber(result['traceEvents']);
    expect(eventsContains(dartEvents, 'i', 'ISYNC'), isTrue);
    expect(eventsContains(dartEvents, 'X', 'apple'), isTrue);
    expect(eventsContains(dartEvents, 'b', 'TASK1'), isTrue);
    expect(eventsContains(dartEvents, 'e', 'TASK1'), isTrue);
    expect(eventsContains(dartEvents, 'n', 'ITASK'), isTrue);
    expect(eventsContains(dartEvents, 'q', 'ITASK'), isFalse);
    expect(eventsContains(dartEvents, 's', 'peach'), isTrue);
    expect(eventsContains(dartEvents, 't', 'watermelon'), isTrue);
    expect(eventsContains(dartEvents, 'f', 'pear'), isTrue);
    // Calculate the time Window of Dart events.
    int origin = timeOrigin(dartEvents);
    int extent = timeDuration(dartEvents, origin);
    // Query for the timeline with the time window for Dart events.
    result = await vm.invokeRpcNoUpgrade('_getVMTimeline',
        {'timeOriginMicros': origin, 'timeExtentMicros': extent});
    // Verify that we received fewer events than before.
    expect(result['traceEvents'].length, lessThan(numEvents));
    // Verify that we have the same number of Dart events.
    List dartEvents2 = filterForDartEvents(result['traceEvents']);
    expect(dartEvents2.length, dartEvents.length);
  },
];

main(args) async => runVMTests(args, tests, testeeBefore: primeTimeline);
