// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

/** Records a change to an [Observable]. */
abstract class ChangeRecord {
  // TODO(jmesserly): rename this--it's confusing. Perhaps "matches"?
  /** True if the change affected the given item, otherwise false. */
  bool changes(key);
}

/** A change record to a field of an observable object. */
class PropertyChangeRecord extends ChangeRecord {
  /** The field that was changed. */
  final Symbol field;

  PropertyChangeRecord(this.field);

  bool changes(key) => key is Symbol && field == key;

  String toString() => '#<PropertyChangeRecord $field>';
}

/** A change record for an observable list. */
class ListChangeRecord extends ChangeRecord {
  /** The starting index of the change. */
  final int index;

  /** The number of items removed. */
  final int removedCount;

  /** The number of items added. */
  final int addedCount;

  ListChangeRecord(this.index, {this.removedCount: 0, this.addedCount: 0}) {
    if (addedCount == 0 && removedCount == 0) {
      throw new ArgumentError('added and removed counts should not both be '
          'zero. Use 1 if this was a single item update.');
    }
  }

  /** Returns true if the provided index was changed by this operation. */
  bool changes(key) {
    // If key isn't an int, or before the index, then it wasn't changed.
    if (key is! int || key < index) return false;

    // If this was a shift operation, anything after index is changed.
    if (addedCount != removedCount) return true;

    // Otherwise, anything in the update range was changed.
    return key < index + addedCount;
  }

  String toString() => '#<ListChangeRecord index: $index, '
      'removed: $removedCount, addedCount: $addedCount>';
}
