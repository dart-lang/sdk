// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@patch
class Expando<T> {
  @patch
  Expando([String name])
      : name = name,
        _data = new List(_minSize),
        _used = 0;

  static const _minSize = 8;
  static final _deletedEntry = new _WeakProperty(null, null);

  @patch
  T operator [](Object object) {
    _checkType(object);

    var mask = _size - 1;
    var idx = object._identityHashCode & mask;
    var wp = _data[idx];

    while (wp != null) {
      if (identical(wp.key, object)) {
        return wp.value;
      } else if (wp.key == null) {
        // This entry has been cleared by the GC.
        _data[idx] = _deletedEntry;
      }
      idx = (idx + 1) & mask;
      wp = _data[idx];
    }

    return null;
  }

  @patch
  void operator []=(Object object, T value) {
    _checkType(object);

    var mask = _size - 1;
    var idx = object._identityHashCode & mask;
    var empty_idx = -1;
    var wp = _data[idx];

    while (wp != null) {
      if (identical(wp.key, object)) {
        if (value != null) {
          // Update the associated value.
          wp.value = value;
        } else {
          // Mark the entry as deleted.
          _data[idx] = _deletedEntry;
        }
        return;
      } else if ((empty_idx < 0) && identical(wp, _deletedEntry)) {
        empty_idx = idx; // Insert at this location if not found.
      } else if (wp.key == null) {
        // This entry has been cleared by the GC.
        _data[idx] = _deletedEntry;
        if (empty_idx < 0) {
          empty_idx = idx; // Insert at this location if not found.
        }
      }
      idx = (idx + 1) & mask;
      wp = _data[idx];
    }

    if (value == null) {
      // Not entering a null value. We just needed to make sure to clear an
      // existing value if it existed.
      return;
    }

    if (empty_idx >= 0) {
      // We will be reusing the empty slot below.
      _used--;
      idx = empty_idx;
    }

    if (_used < _limit) {
      _data[idx] = new _WeakProperty(object, value);
      _used++;
      return;
    }

    // Grow/reallocate if too many slots have been used.
    _rehash();
    this[object] = value; // Recursively add the value.
  }

  _rehash() {
    // Determine the population count of the map to allocate an appropriately
    // sized map below.
    var count = 0;
    var old_data = _data;
    var len = old_data.length;
    for (var i = 0; i < len; i++) {
      var entry = old_data[i];
      if ((entry != null) && (entry.key != null)) {
        // Only count non-cleared entries.
        count++;
      }
    }

    var new_size = _size;
    if (count <= (new_size >> 2)) {
      new_size = new_size >> 1;
    } else if (count > (new_size >> 1)) {
      new_size = new_size << 1;
    }
    new_size = (new_size < _minSize) ? _minSize : new_size;

    // Reset the mappings to empty so that we can just add the existing
    // valid entries.
    _data = new List(new_size);
    _used = 0;

    for (var i = 0; i < old_data.length; i++) {
      var entry = old_data[i];
      if (entry != null) {
        // Ensure that the entry.key is not cleared between checking for it and
        // inserting it into the new table.
        var val = entry.value;
        var key = entry.key;
        if (key != null) {
          this[key] = val;
        }
      }
    }
  }

  static _checkType(object) {
    if ((object == null) ||
        (object is bool) ||
        (object is num) ||
        (object is String)) {
      throw new ArgumentError.value(object,
          "Expandos are not allowed on strings, numbers, booleans or null");
    }
  }

  get _size => _data.length;
  get _limit => (3 * (_size ~/ 4));

  List _data;
  int _used; // Number of used (active and deleted) slots.
}
