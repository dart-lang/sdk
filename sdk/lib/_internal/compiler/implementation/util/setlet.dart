// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.setlet;

import 'dart:collection' show IterableBase;

class Setlet<E> extends IterableBase<E> implements Set<E> {
  static const _MARKER = const _SetletMarker();
  static const CAPACITY = 8;

  // The setlet can be in one of four states:
  //
  //   * Empty          (extra: null,   contents: marker)
  //   * Single element (extra: null,   contents: element)
  //   * List-backed    (extra: length, contents: list)
  //   * Set-backed     (extra: marker, contents: set)
  //
  // When the setlet is list-backed, the list in the contents field
  // may have empty slots filled with the marker value.
  var _contents = _MARKER;
  var _extra;

  Setlet();
  Setlet.from(Iterable<E> elements) {
    addAll(elements);
  }

  Iterator<E> get iterator {
    if (_extra == null) {
      return new _SetletSingleIterator<E>(_contents);
    } else if (_MARKER == _extra) {
      return _contents.iterator;
    } else {
      return new _SetletListIterator<E>(_contents, _extra);
    }
  }

  int get length {
    if (_extra == null) {
      return (_MARKER == _contents) ? 0 : 1;
    } else if (_MARKER == _extra) {
      return _contents.length;
    } else {
      return _extra;
    }
  }

  bool get isEmpty {
    if (_extra == null) {
      return _MARKER == _contents;
    } else if (_MARKER == _extra) {
      return _contents.isEmpty;
    } else {
      return _extra == 0;
    }
  }

  bool contains(E element) {
    if (_extra == null) {
      return _contents == element;
    } else if (_MARKER == _extra) {
      return _contents.contains(element);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _contents[i];
        if (_MARKER == candidate) continue;
        if (candidate == element) return true;
        remaining--;
      }
      return false;
    }
  }

  bool add(E element) {
    if (_extra == null) {
      if (_MARKER == _contents) {
        _contents = element;
        return true;
      } else if (_contents == element) {
        // Do nothing.
        return false;
      } else {
        List list = new List(CAPACITY);
        list[0] = _contents;
        list[1] = element;
        _contents = list;
        _extra = 2;  // Two elements.
        return true;
      }
    } else if (_MARKER == _extra) {
      return _contents.add(element);
    } else {
      int remaining = _extra;
      int index = 0;
      int copyTo, copyFrom;
      while (remaining > 0 && index < CAPACITY) {
        var candidate = _contents[index++];
        if (_MARKER == candidate) {
          // Keep track of the last range of empty slots in the
          // list. When we're done we'll move all the elements
          // after those empty slots down, so that adding an element
          // after that will preserve the insertion order.
          if (copyFrom == index - 1) {
            copyFrom++;
          } else {
            copyTo = index - 1;
            copyFrom = index;
          }
          continue;
        } else if (candidate == element) {
          return false;
        }
        remaining--;
      }
      if (index < CAPACITY) {
        _contents[index] = element;
        _extra++;
      } else if (_extra < CAPACITY) {
        // Move the last elements down into the last empty slots
        // so that we have empty slots after the last element.
        while (copyFrom < CAPACITY) {
          _contents[copyTo++] = _contents[copyFrom++];
        }
        // Insert the new element as the last element.
        _contents[copyTo++] = element;
        _extra++;
        // Clear all elements after the new last elements to
        // make sure we don't keep extra stuff alive.
        while (copyTo < CAPACITY) _contents[copyTo++] = null;
      } else {
        _contents = new Set<E>()..addAll(_contents)..add(element);
        _extra = _MARKER;
      }
      return true;
    }
  }

  void addAll(Iterable<E> elements) {
    elements.forEach((each) => add(each));
  }

  E lookup(Object element) {
    if (_extra == null) {
      return _contents == element ? _contents : null;
    } else if (_MARKER == _extra) {
      return _contents.lookup(element);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _contents[i];
        if (_MARKER == candidate) continue;
        if (candidate == element) return candidate;
        remaining--;
      }
      return null;
    }
  }

  bool remove(E element) {
    if (_extra == null) {
      if (_contents == element) {
        _contents = _MARKER;
        return true;
      } else {
        return false;
      }
    } else if (_MARKER == _extra) {
      return _contents.remove(element);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _contents[i];
        if (_MARKER == candidate) continue;
        if (candidate == element) {
          _contents[i] = _MARKER;
          _extra--;
          return true;
        }
        remaining--;
      }
      return false;
    }
  }

  void removeAll(Iterable<Object> other) {
    other.forEach(remove);
  }

  void removeWhere(bool test(E element)) {
    if (_extra == null) {
      if (test(_contents)) {
        _contents = _MARKER;
      }
    } else if (_MARKER == _extra) {
      _contents.removeWhere(test);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var candidate = _contents[i];
        if (_MARKER == candidate) continue;
        if (test(candidate)) {
          _contents[i] = _MARKER;
          _extra--;
        }
        remaining--;
      }
    }
  }

  void retainWhere(bool test(E element)) {
    removeWhere((E element) => !test(element));
  }

  void retainAll(Iterable<Object> elements) {
    Set set = elements is Set ? elements : elements.toSet();
    removeWhere((E element) => !set.contains(element));
  }

  void forEach(void action(E element)) {
    if (_extra == null) {
      if (_MARKER != _contents) action(_contents);
    } else if (_MARKER == _extra) {
      _contents.forEach(action);
    } else {
      for (int remaining = _extra, i = 0; remaining > 0 && i < CAPACITY; i++) {
        var element = _contents[i];
        if (_MARKER == element) continue;
        action(element);
        remaining--;
      }
    }
  }

  bool containsAll(Iterable<E> other) {
    for (E e in other) {
      if (!this.contains(e)) return false;
    };
    return true;
  }

  clear() {
    _contents = _MARKER;
    _extra = null;
  }

  Set<E> union(Set<E> other) => new Set<E>.from(this)..addAll(other);

  Setlet<E> intersection(Set<E> other) =>
      new Setlet<E>.from(this.where((e) => other.contains(e)));

  Setlet<E> difference(Set<E> other) =>
      new Setlet<E>.from(this.where((e) => !other.contains(e)));
}

class _SetletMarker {
  const _SetletMarker();
  toString() => "-";
}

class _SetletSingleIterator<E> implements Iterator<E> {
  var _element;
  E _current;
  _SetletSingleIterator(this._element);

  E get current => _current;

  bool moveNext() {
    if (Setlet._MARKER == _element) {
      _current = null;
      return false;
    }
    _current = _element;
    _element = Setlet._MARKER;
    return true;
  }
}

class _SetletListIterator<E> implements Iterator<E> {
  final List _list;
  int _remaining;
  int _index = 0;
  E _current;
  _SetletListIterator(this._list, this._remaining);

  E get current => _current;

  bool moveNext() {
    while (_remaining > 0) {
      var candidate = _list[_index++];
      if (Setlet._MARKER != candidate) {
        _current = candidate;
        _remaining--;
        return true;
      }
    }
    _current = null;
    return false;
  }
}
