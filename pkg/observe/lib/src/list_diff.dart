// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.list_diff;

import 'dart:math' as math;
import 'dart:collection' show UnmodifiableListView;
import 'change_record.dart' show ChangeRecord;

/// A summary of an individual change to a [List].
///
/// Each delta represents that at the [index], [removed] sequence of items were
/// removed, and counting forward from [index], [addedCount] items were added.
class ListChangeRecord extends ChangeRecord {
  /// The list that changed.
  final List object;

  /// The index of the change.
  int get index => _index;

  /// The items removed, if any. Otherwise this will be an empty list.
  List get removed => _unmodifiableRemoved;
  UnmodifiableListView _unmodifiableRemoved;

  /// Mutable version of [removed], used during the algorithms as they are
  /// constructing the object.
  List _removed;

  /// The number of items added.
  int get addedCount => _addedCount;

  // Note: conceptually these are final, but for convenience we increment it as
  // we build the object. It will be "frozen" by the time it is returned the the
  // user.
  int _index, _addedCount;

  ListChangeRecord._(this.object, this._index, removed, this._addedCount)
      : _removed = removed,
        _unmodifiableRemoved = new UnmodifiableListView(removed);

  factory ListChangeRecord(List object, int index,
      {List removed, int addedCount}) {

    if (removed == null) removed = [];
    if (addedCount == null) addedCount = 0;
    return new ListChangeRecord._(object, index, removed, addedCount);
  }

  /// Returns true if the provided index was changed by this operation.
  bool indexChanged(key) {
    // If key isn't an int, or before the index, then it wasn't changed.
    if (key is! int || key < index) return false;

    // If this was a shift operation, anything after index is changed.
    if (addedCount != removed.length) return true;

    // Otherwise, anything in the update range was changed.
    return key < index + addedCount;
  }

  String toString() => '#<ListChangeRecord index: $index, '
      'removed: $removed, addedCount: $addedCount>';
}

// Note: This function is *based* on the computation of the Levenshtein
// "edit" distance. The one change is that "updates" are treated as two
// edits - not one. With List splices, an update is really a delete
// followed by an add. By retaining this, we optimize for "keeping" the
// maximum array items in the original array. For example:
//
//   'xxxx123' -> '123yyyy'
//
// With 1-edit updates, the shortest path would be just to update all seven
// characters. With 2-edit updates, we delete 4, leave 3, and add 4. This
// leaves the substring '123' intact.
List<List<int>> _calcEditDistances(List current, int currentStart,
    int currentEnd, List old, int oldStart, int oldEnd) {
  // "Deletion" columns
  var rowCount = oldEnd - oldStart + 1;
  var columnCount = currentEnd - currentStart + 1;
  var distances = new List(rowCount);

  // "Addition" rows. Initialize null column.
  for (var i = 0; i < rowCount; i++) {
    distances[i] = new List(columnCount);
    distances[i][0] = i;
  }

  // Initialize null row
  for (var j = 0; j < columnCount; j++) {
    distances[0][j] = j;
  }

  for (var i = 1; i < rowCount; i++) {
    for (var j = 1; j < columnCount; j++) {
      if (old[oldStart + i - 1] == current[currentStart + j - 1]) {
        distances[i][j] = distances[i - 1][j - 1];
      } else {
        var north = distances[i - 1][j] + 1;
        var west = distances[i][j - 1] + 1;
        distances[i][j] = math.min(north, west);
      }
    }
  }

  return distances;
}

const _EDIT_LEAVE = 0;
const _EDIT_UPDATE = 1;
const _EDIT_ADD = 2;
const _EDIT_DELETE = 3;

// This starts at the final weight, and walks "backward" by finding
// the minimum previous weight recursively until the origin of the weight
// matrix.
List<int> _spliceOperationsFromEditDistances(List<List<int>> distances) {
  var i = distances.length - 1;
  var j = distances[0].length - 1;
  var current = distances[i][j];
  var edits = [];
  while (i > 0 || j > 0) {
    if (i == 0) {
      edits.add(_EDIT_ADD);
      j--;
      continue;
    }
    if (j == 0) {
      edits.add(_EDIT_DELETE);
      i--;
      continue;
    }
    var northWest = distances[i - 1][j - 1];
    var west = distances[i - 1][j];
    var north = distances[i][j - 1];

    var min = math.min(math.min(west, north), northWest);

    if (min == northWest) {
      if (northWest == current) {
        edits.add(_EDIT_LEAVE);
      } else {
        edits.add(_EDIT_UPDATE);
        current = northWest;
      }
      i--;
      j--;
    } else if (min == west) {
      edits.add(_EDIT_DELETE);
      i--;
      current = west;
    } else {
      edits.add(_EDIT_ADD);
      j--;
      current = north;
    }
  }

  return edits.reversed.toList();
}

int _sharedPrefix(List arr1, List arr2, int searchLength) {
  for (var i = 0; i < searchLength; i++) {
    if (arr1[i] != arr2[i]) {
      return i;
    }
  }
  return searchLength;
}

int _sharedSuffix(List arr1, List arr2, int searchLength) {
  var index1 = arr1.length;
  var index2 = arr2.length;
  var count = 0;
  while (count < searchLength && arr1[--index1] == arr2[--index2]) {
    count++;
  }
  return count;
}

/// Lacking individual splice mutation information, the minimal set of
/// splices can be synthesized given the previous state and final state of an
/// array. The basic approach is to calculate the edit distance matrix and
/// choose the shortest path through it.
///
/// Complexity: O(l * p)
///   l: The length of the current array
///   p: The length of the old array
List<ListChangeRecord> calcSplices(List current, int currentStart,
    int currentEnd, List old, int oldStart, int oldEnd) {

  var prefixCount = 0;
  var suffixCount = 0;

  var minLength = math.min(currentEnd - currentStart, oldEnd - oldStart);
  if (currentStart == 0 && oldStart == 0) {
    prefixCount = _sharedPrefix(current, old, minLength);
  }

  if (currentEnd == current.length && oldEnd == old.length) {
    suffixCount = _sharedSuffix(current, old, minLength - prefixCount);
  }

  currentStart += prefixCount;
  oldStart += prefixCount;
  currentEnd -= suffixCount;
  oldEnd -= suffixCount;

  if (currentEnd - currentStart == 0 && oldEnd - oldStart == 0) {
    return const [];
  }

  if (currentStart == currentEnd) {
    var splice = new ListChangeRecord(current, currentStart);
    while (oldStart < oldEnd) {
      splice._removed.add(old[oldStart++]);
    }

    return [splice ];
  } else if (oldStart == oldEnd)
    return [new ListChangeRecord(current, currentStart,
        addedCount: currentEnd - currentStart)];

  var ops = _spliceOperationsFromEditDistances(
      _calcEditDistances(current, currentStart, currentEnd, old, oldStart,
          oldEnd));

  ListChangeRecord splice = null;
  var splices = <ListChangeRecord>[];
  var index = currentStart;
  var oldIndex = oldStart;
  for (var i = 0; i < ops.length; i++) {
    switch(ops[i]) {
      case _EDIT_LEAVE:
        if (splice != null) {
          splices.add(splice);
          splice = null;
        }

        index++;
        oldIndex++;
        break;
      case _EDIT_UPDATE:
        if (splice == null) splice = new ListChangeRecord(current, index);

        splice._addedCount++;
        index++;

        splice._removed.add(old[oldIndex]);
        oldIndex++;
        break;
      case _EDIT_ADD:
        if (splice == null) splice = new ListChangeRecord(current, index);

        splice._addedCount++;
        index++;
        break;
      case _EDIT_DELETE:
        if (splice == null) splice = new ListChangeRecord(current, index);

        splice._removed.add(old[oldIndex]);
        oldIndex++;
        break;
    }
  }

  if (splice != null) splices.add(splice);
  return splices;
}

int _intersect(int start1, int end1, int start2, int end2) =>
    math.min(end1, end2) - math.max(start1, start2);

void _mergeSplice(List<ListChangeRecord> splices, ListChangeRecord record) {
  var splice = new ListChangeRecord(record.object, record.index,
      removed: record._removed.toList(), addedCount: record.addedCount);

  var inserted = false;
  var insertionOffset = 0;

  // I think the way this works is:
  // - the loop finds where the merge should happen
  // - it applies the merge in a particular splice
  // - then continues and updates the subsequent splices with any offset diff.
  for (var i = 0; i < splices.length; i++) {
    final current = splices[i];
    current._index += insertionOffset;

    if (inserted) continue;

    var intersectCount = _intersect(
        splice.index, splice.index + splice.removed.length,
        current.index, current.index + current.addedCount);

    if (intersectCount >= 0) {
      // Merge the two splices

      splices.removeAt(i);
      i--;

      insertionOffset -= current.addedCount - current.removed.length;

      splice._addedCount += current.addedCount - intersectCount;
      var deleteCount = splice.removed.length +
                        current.removed.length - intersectCount;

      if (splice.addedCount == 0 && deleteCount == 0) {
        // merged splice is a noop. discard.
        inserted = true;
      } else {
        var removed = current._removed;

        if (splice.index < current.index) {
          // some prefix of splice.removed is prepended to current.removed.
          removed.insertAll(0,
              splice.removed.getRange(0, current.index - splice.index));
        }

        if (splice.index + splice.removed.length >
            current.index + current.addedCount) {
          // some suffix of splice.removed is appended to current.removed.
          removed.addAll(splice.removed.getRange(
              current.index + current.addedCount - splice.index,
              splice.removed.length));
        }

        splice._removed = removed;
        splice._unmodifiableRemoved = current._unmodifiableRemoved;
        if (current.index < splice.index) {
          splice._index = current.index;
        }
      }
    } else if (splice.index < current.index) {
      // Insert splice here.

      inserted = true;

      splices.insert(i, splice);
      i++;

      var offset = splice.addedCount - splice.removed.length;
      current._index += offset;
      insertionOffset += offset;
    }
  }

  if (!inserted) splices.add(splice);
}

List<ListChangeRecord> _createInitialSplices(List<Object> list,
    List<ListChangeRecord> records) {

  var splices = <ListChangeRecord>[];
  for (var record in records) {
    _mergeSplice(splices, record);
  }
  return splices;
}

/// We need to summarize change records. Consumers of these records want to
/// apply the batch sequentially, and ensure that they can find inserted
/// items by looking at that position in the list. This property does not
/// hold in our record-as-you-go records. Consider:
///
///     var model = toObservable(['a', 'b']);
///     model.removeAt(1);
///     model.insertAll(0, ['c', 'd', 'e']);
///     model.removeRange(1, 3);
///     model.insert(1, 'f');
///
/// Here, we inserted some records and then removed some of them.
/// If someone processed these records naively, they would "play back" the
/// insert incorrectly, because those items will be shifted.
List<ListChangeRecord> projectListSplices(List list,
    List<ListChangeRecord> records) {
  if (records.length <= 1) return records;

  var splices = [];
  for (var splice in _createInitialSplices(list, records)) {
    if (splice.addedCount == 1 && splice.removed.length == 1) {
      if (splice.removed[0] != list[splice.index]) splices.add(splice);
      continue;
    }

    splices.addAll(calcSplices(list, splice.index,
        splice.index + splice.addedCount, splice._removed, 0,
        splice.removed.length));
  }

  return splices;
}
