// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

/** Records a change to an [Observable]. */
// TODO(jmesserly): remove this type
abstract class ChangeRecord {}

/** A change record to a field of an observable object. */
class PropertyChangeRecord<T> extends ChangeRecord {
  /**
   * *Deprecated* use [name] instead.
   * The field that was changed.
   */
  @deprecated
  Symbol get field => name;

  /** The object that changed. */
  final object;

  /** The name of the property that changed. */
  final Symbol name;

  /** The previous value of the property. */
  final T oldValue;

  /** The new value of the property. */
  final T newValue;

  PropertyChangeRecord(this.object, this.name, this.oldValue, this.newValue);

  /*
   * *Deprecated* instead of `record.changes(key)` simply do
   * `key == record.name`.
   */
  @deprecated
  bool changes(key) => key is Symbol && name == key;

  String toString() =>
      '#<PropertyChangeRecord $name from: $oldValue to: $newValue>';
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

  /**
   * *Deprecated* use [indexChanged] instead.
   * Returns true if the provided index was changed by this operation.
   */
  @deprecated
  bool changes(value) => indexChanged(value);

  /** Returns true if the provided index was changed by this operation. */
  bool indexChanged(otherIndex) {
    // If key isn't an int, or before the index, then it wasn't changed.
    if (otherIndex is! int || otherIndex < index) return false;

    // If this was a shift operation, anything after index is changed.
    if (addedCount != removedCount) return true;

    // Otherwise, anything in the update range was changed.
    return otherIndex < index + addedCount;
  }

  String toString() => '#<ListChangeRecord index: $index, '
      'removed: $removedCount, addedCount: $addedCount>';
}
