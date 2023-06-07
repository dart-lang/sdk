// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

Stopwatch _stopwatch = new Stopwatch();
Uint64List _combinedRuntimes = Uint64List(0);
Uint32List _countVisits = Uint32List(0);
Uint32List _currentlyActive = Uint32List(0);

void initialize(int count, bool reportCandidates) {
  _combinedRuntimes = new Uint64List(count);
  _countVisits = new Uint32List(count);
  _currentlyActive = new Uint32List(count);
  _stopwatch.start();
}

@pragma("vm:prefer-inline")
void enter(int i) {
  if (_currentlyActive[i]++ == 0) {
    _combinedRuntimes[i] -= _stopwatch.elapsedTicks;
  }
  _countVisits[i]++;
}

@pragma("vm:prefer-inline")
void exit(int i) {
  if (--_currentlyActive[i] == 0) {
    _combinedRuntimes[i] += _stopwatch.elapsedTicks;
  }
}

void report(List<String> names) {
  List<_Data> data = [];
  for (int i = 0; i < _combinedRuntimes.length; i++) {
    if (_countVisits[i] > 0) {
      data.add(new _Data(names[i], _combinedRuntimes[i], _countVisits[i],
          _currentlyActive[i]));
    }
  }
  data..sort((a, b) => a.combinedRuntime - b.combinedRuntime);
  for (_Data d in data) {
    print("${d.name}:"
        " runtime: ${d.combinedRuntime}"
        " (${d.combinedRuntime / _stopwatch.frequency} s)"
        ", visits: ${d.visits}"
        ", active: ${d.active}");
  }
}

class _Data {
  final String name;
  final int combinedRuntime;
  final int visits;
  final int active;

  _Data(this.name, this.combinedRuntime, this.visits, this.active);
}
