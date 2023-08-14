// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Stopwatch _stopwatch = new Stopwatch();
int _combinedRuntimes = 0;
int _countVisits = 0;
int _currentlyActive = 0;

void initialize(int count, bool reportCandidates) {
  _stopwatch.start();
}

@pragma("vm:prefer-inline")
void enter(int i) {
  if (_currentlyActive++ == 0) {
    _combinedRuntimes -= _stopwatch.elapsedTicks;
  }
  _countVisits++;
}

@pragma("vm:prefer-inline")
void exit(int i) {
  if (--_currentlyActive == 0) {
    _combinedRuntimes += _stopwatch.elapsedTicks;
  }
}

void report(List<String> names) {
  print("Runtime: $_combinedRuntimes");
  print("Runtime in seconds: ${_combinedRuntimes / _stopwatch.frequency}");
  print("Visits: $_countVisits");
  print("Active: $_currentlyActive");
  print("Stopwatch frequency: ${_stopwatch.frequency}");
}
