// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

// Based on (as in mostly a copy from) the _IntervalListBuilder in
// package:kernel/class_hierarchy.dart.
class IntervalListBuilder {
  bool _finished = false;
  final List<int> _events = <int>[];

  IntervalListBuilder clone() {
    if (_finished) throw "Can't clone an already finished builder.";
    IntervalListBuilder clone = new IntervalListBuilder();
    clone._events.addAll(_events);
    return clone;
  }

  void addIntervalIncludingEnd(int start, int end) {
    // Add an event point for each interval end point, using the low bit to
    // distinguish opening from closing end points. Closing end points should
    // have the high bit to ensure they occur after an opening end point.
    _events.add(start << 1);
    // Add 1 to include the end.
    _events.add(((end + 1) << 1) + 1);
  }

  void addIntervalExcludingEnd(int start, int end) {
    // Add an event point for each interval end point, using the low bit to
    // distinguish opening from closing end points. Closing end points should
    // have the high bit to ensure they occur after an opening end point.
    _events.add(start << 1);
    _events.add((end << 1) + 1);
  }

  void addSingleton(int x) {
    addIntervalExcludingEnd(x, x + 1);
  }

  IntervalList buildIntervalList() {
    if (_finished) throw "Can't build an already finished builder.";
    // Sort the event points and sweep left to right while tracking how many
    // intervals we are currently inside.  Record an interval end point when the
    // number of intervals drop to zero or increase from zero to one.
    // Event points are encoded so that an opening end point occur before a
    // closing end point at the same value.
    _events.sort();
    int insideCount = 0; // The number of intervals we are currently inside.
    int storeIndex = 0;
    for (int i = 0; i < _events.length; ++i) {
      int event = _events[i];
      if (event & 1 == 0) {
        // Start point
        ++insideCount;
        if (insideCount == 1) {
          // Store the results temporarily back in the event array.
          _events[storeIndex++] = event >> 1;
        }
      } else {
        // End point
        --insideCount;
        if (insideCount == 0) {
          _events[storeIndex++] = event >> 1;
        }
      }
    }
    // Copy the results over to a typed array of the correct length.
    Uint32List result = new Uint32List(storeIndex);
    for (int i = 0; i < storeIndex; ++i) {
      result[i] = _events[i];
    }

    _finished = true;
    return new IntervalList._(result);
  }
}

class IntervalList {
  final Uint32List _intervalList;
  IntervalList._(this._intervalList);

  bool get isEmpty => _intervalList.isEmpty;

  bool contains(int x) {
    int low = 0, high = _intervalList.length - 1;
    if (high == -1 || x < _intervalList[0] || _intervalList[high] <= x) {
      return false;
    }
    // Find the lower bound of x in the list.
    // If the lower bound is at an even index, the lower bound is an opening
    // point of an interval that contains x, otherwise it is a closing point of
    // an interval below x and there is no interval containing x.
    while (low < high) {
      int mid = high - ((high - low) >> 1); // Get middle, rounding up.
      int pivot = _intervalList[mid];
      if (pivot <= x) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low == high && (low & 1) == 0;
  }
}
