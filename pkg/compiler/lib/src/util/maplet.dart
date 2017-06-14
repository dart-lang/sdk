// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.maplet;

import 'dart:collection' show MapBase, IterableBase;

class Maplet<K, V> extends MapBase<K, V> {
  static const _MapletMarker _MARKER = const _MapletMarker();
  static const int CAPACITY = 8;

// The maplet can be in one of four states:
  //
  //   * Empty          (extra: null,   key: marker, value: null)
  //   * Single element (extra: null,   key: key,    value: value)
  //   * List-backed    (extra: length, key: list,   value: null)
  //   * Map-backed     (extra: marker, key: map,    value: null)
  //
  // When the maplet is list-backed, the list has two sections: One
  // for keys and one for values. The first [CAPACITY] entries are
  // the keys and they may contain markers for deleted elements. After
  // the keys there are [CAPACITY] entries for the values.

  dynamic _key = _MARKER;
  var _value;
  var _extra;

  Maplet();

  Maplet.from(Maplet<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  bool get isEmpty {
    if (_extra == null) {
      return _MARKER == _key;
    } else if (_MARKER == _extra) {
      return _key.isEmpty;
    } else {
      return _extra == 0;
    }
  }

  int get length {
    if (_extra == null) {
      return (_MARKER == _key) ? 0 : 1;
    } else if (_MARKER == _extra) {
      return _key.length;
    } else {
      return _extra;
    }
  }

  bool containsKey(K key) {
    if (_extra == null) {
      return _key == key;
    } else if (_MARKER == _extra) {
      return _key.containsKey(key);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _key[i];
        if (_MARKER == candidate) continue;
        if (candidate == key) return true;
        remaining--;
      }
      return false;
    }
  }

  V operator [](K key) {
    if (_extra == null) {
      return (_key == key) ? _value : null;
    } else if (_MARKER == _extra) {
      return _key[key];
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _key[i];
        if (_MARKER == candidate) continue;
        if (candidate == key) return _key[i + CAPACITY];
        remaining--;
      }
      return null;
    }
  }

  void operator []=(K key, V value) {
    if (_extra == null) {
      if (_MARKER == _key) {
        _key = key;
        _value = value;
      } else if (_key == key) {
        _value = value;
      } else {
        List list = new List(CAPACITY * 2);
        list[0] = _key;
        list[1] = key;
        list[CAPACITY] = _value;
        list[CAPACITY + 1] = value;
        _key = list;
        _value = null;
        _extra = 2; // Two elements.
      }
    } else if (_MARKER == _extra) {
      _key[key] = value;
    } else {
      int remaining = _extra;
      int index = 0;
      int copyTo, copyFrom;
      while (remaining > 0 && index < CAPACITY) {
        var candidate = _key[index];
        if (_MARKER == candidate) {
          // Keep track of the last range of empty slots in the
          // list. When we're done we'll move all the elements
          // after those empty slots down, so that adding an element
          // after that will preserve the insertion order.
          if (copyFrom == index) {
            copyFrom++;
          } else {
            copyTo = index;
            copyFrom = index + 1;
          }
        } else if (candidate == key) {
          _key[CAPACITY + index] = value;
          return;
        } else {
          // Skipped an element that didn't match.
          remaining--;
        }
        index++;
      }
      if (index < CAPACITY) {
        _key[index] = key;
        _key[CAPACITY + index] = value;
        _extra++;
      } else if (_extra < CAPACITY) {
        // Move the last elements down into the last empty slots
        // so that we have empty slots after the last element.
        while (copyFrom < CAPACITY) {
          _key[copyTo] = _key[copyFrom];
          _key[CAPACITY + copyTo] = _key[CAPACITY + copyFrom];
          copyTo++;
          copyFrom++;
        }
        // Insert the new element as the last element.
        _key[copyTo] = key;
        _key[CAPACITY + copyTo] = value;
        copyTo++;
        // Add one to the length encoded in the extra field.
        _extra++;
        // Clear all elements after the new last elements to
        // make sure we don't keep extra stuff alive.
        while (copyTo < CAPACITY) {
          _key[copyTo] = _key[CAPACITY + copyTo] = null;
          copyTo++;
        }
      } else {
        Map map = new Map();
        forEach((eachKey, eachValue) => map[eachKey] = eachValue);
        map[key] = value;
        _key = map;
        _extra = _MARKER;
      }
    }
  }

  V remove(K key) {
    if (_extra == null) {
      if (_key != key) return null;
      _key = _MARKER;
      V result = _value;
      _value = null;
      return result;
    } else if (_MARKER == _extra) {
      return _key.remove(key);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _key[i];
        if (_MARKER == candidate) continue;
        if (candidate == key) {
          int valueIndex = CAPACITY + i;
          var result = _key[valueIndex];
          _key[i] = _MARKER;
          _key[valueIndex] = null;
          _extra--;
          return result;
        }
        remaining--;
      }
      return null;
    }
  }

  void forEach(void action(K key, V value)) {
    if (_extra == null) {
      if (_MARKER != _key) action(_key, _value);
    } else if (_MARKER == _extra) {
      _key.forEach(action);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _key[i];
        if (_MARKER == candidate) continue;
        action(candidate, _key[CAPACITY + i]);
        remaining--;
      }
    }
  }

  void clear() {
    _key = _MARKER;
    _value = _extra = null;
  }

  Iterable<K> get keys => new _MapletKeyIterable<K>(this);
}

class _MapletMarker {
  const _MapletMarker();
}

class _MapletKeyIterable<K> extends IterableBase<K> {
  final Maplet<K, dynamic> maplet;

  _MapletKeyIterable(this.maplet);

  Iterator<K> get iterator {
    if (maplet._extra == null) {
      return new _MapletSingleIterator<K>(maplet._key);
    } else if (Maplet._MARKER == maplet._extra) {
      return maplet._key.keys.iterator;
    } else {
      return new _MapletListIterator<K>(maplet._key, maplet._extra);
    }
  }
}

class _MapletSingleIterator<K> implements Iterator<K> {
  var _element;
  K _current;

  _MapletSingleIterator(this._element);

  K get current => _current;

  bool moveNext() {
    if (Maplet._MARKER == _element) {
      _current = null;
      return false;
    }
    _current = _element;
    _element = Maplet._MARKER;
    return true;
  }
}

class _MapletListIterator<K> implements Iterator<K> {
  final List _list;
  int _remaining;
  int _index = 0;
  K _current;

  _MapletListIterator(this._list, this._remaining);

  K get current => _current;

  bool moveNext() {
    while (_remaining > 0) {
      var candidate = _list[_index++];
      if (Maplet._MARKER != candidate) {
        _current = candidate;
        _remaining--;
        return true;
      }
    }
    _current = null;
    return false;
  }
}
