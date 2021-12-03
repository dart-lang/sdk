// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../tool/_fasta/entry_points.dart' show compileEntryPoint;

Future<void> main(List<String> arguments) async {
  await compileEntryPoint(arguments);
  if (numCalls.isNotEmpty) {
    print("[");
    bool printed = false;
    for (int i = 0; i < numCalls.length; i++) {
      int? value = numCalls[i];
      if (value != null && value > 0) {
        if (printed) print(",");
        print("$i, $value");
        printed = true;
      }
    }
    print("]");
  } else if (inCall.isNotEmpty) {
    print("[");
    bool printed = false;
    for (int i = 0; i < inCall.length; i++) {
      int? value = inCall[i];
      if (value == null) continue;
      if (value != 0) throw "$i has value $value";
      if (printed) print(",");
      int? time = callTimes[i];
      print("$i, $time");
      printed = true;
    }
    print("]");
  }
}

List<int?> numCalls = [];

void registerCall(int procedureNum) {
  while (numCalls.length <= procedureNum) {
    if (numCalls.length < 8) {
      numCalls.length = 8;
    } else {
      numCalls.length *= 2;
    }
  }
  int numCallsCount = numCalls[procedureNum] ??= 0;
  numCalls[procedureNum] = numCallsCount + 1;
}

List<int?> inCall = [];
List<int?> callTimes = [];
Stopwatch stopwatch = new Stopwatch()..start();

void registerCallStart(int procedureNum) {
  while (inCall.length <= procedureNum) {
    if (inCall.length < 8) {
      inCall.length = 8;
      callTimes.length = 8;
    } else {
      inCall.length *= 2;
      callTimes.length *= 2;
    }
  }
  int inCallCount = inCall[procedureNum] ??= 0;
  int callTimesCount = callTimes[procedureNum] ??= 0;
  inCall[procedureNum] = inCallCount + 1;
  if (inCallCount == 0) {
    // First --- start a timer-ish.
    callTimes[procedureNum] = callTimesCount - stopwatch.elapsedMicroseconds;
  }
}

void registerCallEnd(int procedureNum) {
  int inCallCount = inCall[procedureNum]!;
  inCall[procedureNum] = inCallCount - 1;
  if (inCallCount == 1) {
    // Last --- stop the timer-ish.
    callTimes[procedureNum] =
        callTimes[procedureNum]! + stopwatch.elapsedMicroseconds;
  }
}

@pragma("vm:prefer-inline")
void preferInlineMe() {
  // This makes it easier to get the annotation :).
}

int busyWait(int micro) {
  int count = 0;
  Stopwatch stopwatch = new Stopwatch()..start();
  while (true) {
    for (int i = 0; i < 1000; i++) {
      count++;
    }
    int elapsed = stopwatch.elapsedMicroseconds;
    if (elapsed >= micro) {
      print("Bye from busywait after $count iterations ($elapsed vs $micro)!");
      return count;
    }
  }
}
