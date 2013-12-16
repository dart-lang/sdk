// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Merge multiple isolate profiler tracing dumps into one.

import 'dart:convert';
import 'dart:io';

/**
 * Sort a list using insertion sort.
 *
 * Insertion sort is a simple sorting algorithm. For `n` elements it does on
 * the order of `n * log(n)` comparisons but up to `n` squared moves. The
 * sorting is performed in-place, without using extra memory.
 *
 * For short lists the many moves have less impact than the simple algorithm,
 * and it is often the favored sorting algorithm for short lists.
 *
 * This insertion sort is stable: Equal elements end up in the same order
 * as they started in.
 */
void insertionSort(List list,
                   { int compare(a, b),
                     int start: 0,
                     int end: null }) {
  // If the same method could have both positional and named optional
  // parameters, this should be (list, [start, end], {compare}).
  if (end == null) end = list.length;
  if (compare == null) compare = Comparable.compare;
  _insertionSort(list, compare, start, end, start + 1);
}

/**
 * Internal helper function that assumes arguments correct.
 *
 * Assumes that the elements up to [sortedUntil] (not inclusive) are
 * already sorted. The [sortedUntil] values should always be at least
 * `start + 1`.
 */
void _insertionSort(List list, int compare(a, b), int start, int end,
                    int sortedUntil) {
  for (int pos = sortedUntil; pos < end; pos++) {
    int min = start;
    int max = pos;
    var element = list[pos];
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      int comparison = compare(element, list[mid]);
      if (comparison < 0) {
        max = mid;
      } else {
        min = mid + 1;
      }
    }
    list.setRange(min + 1, pos + 1, list, min);
    list[min] = element;
  }
}

/** Limit below which merge sort defaults to insertion sort. */
const int _MERGE_SORT_LIMIT = 32;

/**
 * Sorts a list, or a range of a list, using the merge sort algorithm.
 *
 * Merge-sorting works by splitting the job into two parts, sorting each
 * recursively, and then merging the two sorted parts.
 *
 * This takes on the order of `n * log(n)` comparisons and moves to sort
 * `n` elements, but requires extra space of about the same size as the list
 * being sorted.
 *
 * This merge sort is stable: Equal elements end up in the same order
 * as they started in.
 */
void mergeSort(List list, {int start: 0, int end: null, int compare(a, b)}) {
  if (end == null) end = list.length;
  if (compare == null) compare = Comparable.compare;
  int length = end - start;
  if (length < 2) return;
  if (length < _MERGE_SORT_LIMIT) {
    _insertionSort(list, compare, start, end, start + 1);
    return;
  }
  // Special case the first split instead of directly calling
  // _mergeSort, because the _mergeSort requires its target to
  // be different from its source, and it requires extra space
  // of the same size as the list to sort.
  // This split allows us to have only half as much extra space,
  // and it ends up in the original place.
  int middle = start + ((end - start) >> 1);
  int firstLength = middle - start;
  int secondLength = end - middle;
  // secondLength is always the same as firstLength, or one greater.
  List scratchSpace = new List(secondLength);
  _mergeSort(list, compare, middle, end, scratchSpace, 0);
  int firstTarget = end - firstLength;
  _mergeSort(list, compare, start, middle, list, firstTarget);
  _merge(compare,
         list, firstTarget, end,
         scratchSpace, 0, secondLength,
         list, start);
}

/**
 * Performs an insertion sort into a potentially different list than the
 * one containing the original values.
 *
 * It will work in-place as well.
 */
void _movingInsertionSort(List list, int compare(a, b), int start, int end,
                          List target, int targetOffset) {
  int length = end - start;
  if (length == 0) return;
  target[targetOffset] = list[start];
  for (int i = 1; i < length; i++) {
    var element = list[start + i];
    int min = targetOffset;
    int max = targetOffset + i;
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      if (compare(element, target[mid]) < 0) {
        max = mid;
      } else {
        min = mid + 1;
      }
    }
    target.setRange(min + 1, targetOffset + i + 1,
                    target, min);
    target[min] = element;
  }
}

/**
 * Sorts [list] from [start] to [end] into [target] at [targetOffset].
 *
 * The `target` list must be able to contain the range from `start` to `end`
 * after `targetOffset`.
 *
 * Allows target to be the same list as [list], as long as it's not
 * overlapping the `start..end` range.
 */
void _mergeSort(List list, int compare(a, b), int start, int end,
                List target, int targetOffset) {
  int length = end - start;
  if (length < _MERGE_SORT_LIMIT) {
    _movingInsertionSort(list, compare, start, end, target, targetOffset);
    return;
  }
  int middle = start + (length >> 1);
  int firstLength = middle - start;
  int secondLength = end - middle;
  // Here secondLength >= firstLength (differs by at most one).
  int targetMiddle = targetOffset + firstLength;
  // Sort the second half into the end of the target area.
  _mergeSort(list, compare, middle, end,
             target, targetMiddle);
  // Sort the first half into the end of the source area.
  _mergeSort(list, compare, start, middle,
             list, middle);
  // Merge the two parts into the target area.
  _merge(compare,
         list, middle, middle + firstLength,
         target, targetMiddle, targetMiddle + secondLength,
         target, targetOffset);
}

/**
 * Merges two lists into a target list.
 *
 * One of the input lists may be positioned at the end of the target
 * list.
 *
 * For equal object, elements from [firstList] are always preferred.
 * This allows the merge to be stable if the first list contains elements
 * that started out earlier than the ones in [secondList]
 */
void _merge(int compare(a, b),
            List firstList, int firstStart, int firstEnd,
            List secondList, int secondStart, int secondEnd,
            List target, int targetOffset) {
  // No empty lists reaches here.
  assert(firstStart < firstEnd);
  assert(secondStart < secondEnd);
  int cursor1 = firstStart;
  int cursor2 = secondStart;
  var firstElement = firstList[cursor1++];
  var secondElement = secondList[cursor2++];
  while (true) {
    if (compare(firstElement, secondElement) <= 0) {
      target[targetOffset++] = firstElement;
      if (cursor1 == firstEnd) break;  // Flushing second list after loop.
      firstElement = firstList[cursor1++];
    } else {
      target[targetOffset++] = secondElement;
      if (cursor2 != secondEnd) {
        secondElement = secondList[cursor2++];
        continue;
      }
      // Second list empties first. Flushing first list here.
      target[targetOffset++] = firstElement;
      target.setRange(targetOffset, targetOffset + (firstEnd - cursor1),
          firstList, cursor1);
      return;
    }
  }
  // First list empties first. Reached by break above.
  target[targetOffset++] = secondElement;
  target.setRange(targetOffset, targetOffset + (secondEnd - cursor2),
      secondList, cursor2);
}

class TraceMerge {
  Map _processes = {};
  List _metaEvents = [];

  void _processEventsFromFile(String name) {
    var file = new File(name);
    var events = [];
    try {
      var contents = file.readAsStringSync();
      events = JSON.decode(contents);
    } catch (e) {
      print('Exception for $name $e');
    }
    _processEvents(events);
  }

  List _findOrAddProcessThread(pid, tid) {
    var process = _processes[pid];
    if (process == null) {
      process = {};
      _processes[pid] = process;
    }
    var thread = process[tid];
    if (thread == null) {
      thread = [];
      process[tid] = thread;
    }
    return thread;
  }

  void _processEvents(List events) {
    for (var i = 0; i < events.length; i++) {
      Map event = events[i];
      if (event['ph'] == 'M') {
        _metaEvents.add(event);
      } else {
        var pid = event['pid'];
        if (pid == null) {
          throw "No pid in ${event}";
        }
        var tid = event['tid'];
        if (tid == null) {
          throw "No tid in ${event}";
        }
        var thread = _findOrAddProcessThread(pid, tid);
        if (thread == null) {
          throw "No thread list returned.";
        }
        thread.add(event);
      }
    }
  }

  int _compare(Map a, Map b) {
    if (a['ts'] > b['ts']) {
      return 1;
    } else if (a['ts'] < b['ts']) {
      return -1;
    }
    return 0;
  }

  void _sortEvents() {
    _processes.forEach((k, Map process) {
      process.forEach((k, List thread) {
        mergeSort(thread, compare:_compare);
      });
    });
  }

  void _mergeEventsForThread(List thread) {
    List<Map> stack = [];
    int stackDepth = 0;
    thread.forEach((event) {
      if (event['ph'] == 'B') {
        if (stackDepth == stack.length) {
          stack.add(null);
        }
        stackDepth++;
        var end_event = stack[stackDepth - 1];
        if (end_event != null) {
          if (end_event['name'] == event['name'] && stackDepth > 1) {
            // Kill these events.
            // event['dead'] = true;
            // end_event['dead'] = true;
          }
        }
      } else {
        if (event['ph'] != 'E') {
          throw 'Expected E event: ${event}';
        }
        if (stackDepth <= 0) {
          throw 'Stack out of sync ${event}.';
        }
        stackDepth--;
        stack[stackDepth] = event;
      }
    });
  }

  void _mergeEvents() {
    _processes.forEach((k, Map process) {
      process.forEach((k, List thread) {
        _mergeEventsForThread(thread);
      });
    });
  }

  void writeEventsToFile(String name) {
    var file = new File(name);
    List final_events = _metaEvents;
    _processes.forEach((pid, Map process) {
      process.forEach((tid, List thread) {
        thread.forEach((event) {
          if (event['dead'] == null) {
            // Not dead.
            final_events.add(event);
          }
        });
      });
    });
    file.writeAsStringSync(JSON.encode(final_events));
  }

  void merge(List<String> inputs) {
    for (var i = 0; i < inputs.length; i++) {
      _processEventsFromFile(inputs[i]);
    }
    _sortEvents();
    _mergeEvents();
  }
}

main(List<String> arguments) {
  if (arguments.length < 2) {
    print('${Platform.executable} ${Platform.script} <output> <inputs>');
    return;
  }
  String output = arguments[0];
  List<String> inputs = new List<String>();
  for (var i = 1; i < arguments.length; i++) {
    inputs.add(arguments[i]);
  }
  print('Merging $inputs into $output.');
  TraceMerge tm = new TraceMerge();
  tm.merge(inputs);
  tm.writeEventsToFile(output);
}
