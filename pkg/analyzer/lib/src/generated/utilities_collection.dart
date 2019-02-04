// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/generated/java_core.dart';

/**
 * Returns `true` if a and b contain equal elements in the same order.
 */
bool listsEqual(List a, List b) {
  // TODO(rnystrom): package:collection also implements this, and analyzer
  // already transitively depends on that package. Consider using it instead.
  if (identical(a, b)) {
    return true;
  }

  if (a.length != b.length) {
    return false;
  }

  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

/**
 * Methods for operating on integers as if they were arrays of booleans. These
 * arrays can be indexed by either integers or by enumeration constants.
 */
class BooleanArray {
  /**
   * Return the value of the element of the given [array] at the given [index].
   */
  static bool get(int array, int index) {
    _checkIndex(index);
    return (array & (1 << index)) > 0;
  }

  /**
   * Return the value of the element at the given index.
   */
  @deprecated
  static bool getEnum<E extends Enum<E>>(int array, Enum<E> index) =>
      get(array, index.ordinal);

  /**
   * Set the value of the element of the given [array] at the given [index] to
   * the given [value].
   */
  static int set(int array, int index, bool value) {
    _checkIndex(index);
    if (value) {
      return array | (1 << index);
    } else {
      return array & ~(1 << index);
    }
  }

  /**
   * Set the value of the element at the given index to the given value.
   */
  @deprecated
  static int setEnum<E extends Enum<E>>(int array, Enum<E> index, bool value) =>
      set(array, index.ordinal, value);

  /**
   * Throw an exception if the index is not within the bounds allowed for an
   * integer-encoded array of boolean values.
   */
  static void _checkIndex(int index) {
    if (index < 0 || index > 30) {
      throw new RangeError("Index not between 0 and 30: $index");
    }
  }
}

/**
 * The interface `MapIterator` defines the behavior of objects that iterate over the entries
 * in a map.
 *
 * This interface defines the concept of a current entry and provides methods to access the key and
 * value in the current entry. When an iterator is first created it will be positioned before the
 * first entry and there is no current entry until [moveNext] is invoked. When all of the
 * entries have been accessed there will also be no current entry.
 *
 * There is no guarantee made about the order in which the entries are accessible.
 */
abstract class MapIterator<K, V> {
  /**
   * Return the key associated with the current element.
   *
   * @return the key associated with the current element
   * @throws NoSuchElementException if there is no current element
   */
  K get key;

  /**
   * Return the value associated with the current element.
   *
   * @return the value associated with the current element
   * @throws NoSuchElementException if there is no current element
   */
  V get value;

  /**
   * Set the value associated with the current element to the given value.
   *
   * @param newValue the new value to be associated with the current element
   * @throws NoSuchElementException if there is no current element
   */
  void set value(V newValue);

  /**
   * Advance to the next entry in the map. Return `true` if there is a current element that
   * can be accessed after this method returns. It is safe to invoke this method even if the
   * previous invocation returned `false`.
   *
   * @return `true` if there is a current element that can be accessed
   */
  bool moveNext();
}

/**
 * Instances of the class `MultipleMapIterator` implement an iterator that can be used to
 * sequentially access the entries in multiple maps.
 */
class MultipleMapIterator<K, V> implements MapIterator<K, V> {
  /**
   * The iterators used to access the entries.
   */
  List<MapIterator<K, V>> _iterators;

  /**
   * The index of the iterator currently being used to access the entries.
   */
  int _iteratorIndex = -1;

  /**
   * The current iterator, or `null` if there is no current iterator.
   */
  MapIterator<K, V> _currentIterator;

  /**
   * Initialize a newly created iterator to return the entries from the given maps.
   *
   * @param maps the maps containing the entries to be iterated
   */
  MultipleMapIterator(List<Map<K, V>> maps) {
    int count = maps.length;
    _iterators = new List<MapIterator<K, V>>(count);
    for (int i = 0; i < count; i++) {
      _iterators[i] = new SingleMapIterator<K, V>(maps[i]);
    }
  }

  @override
  K get key {
    if (_currentIterator == null) {
      throw new StateError('No element');
    }
    return _currentIterator.key;
  }

  @override
  V get value {
    if (_currentIterator == null) {
      throw new StateError('No element');
    }
    return _currentIterator.value;
  }

  @override
  void set value(V newValue) {
    if (_currentIterator == null) {
      throw new StateError('No element');
    }
    _currentIterator.value = newValue;
  }

  @override
  bool moveNext() {
    if (_iteratorIndex < 0) {
      if (_iterators.length == 0) {
        _currentIterator = null;
        return false;
      }
      if (_advanceToNextIterator()) {
        return true;
      } else {
        _currentIterator = null;
        return false;
      }
    }
    if (_currentIterator.moveNext()) {
      return true;
    } else if (_advanceToNextIterator()) {
      return true;
    } else {
      _currentIterator = null;
      return false;
    }
  }

  /**
   * Under the assumption that there are no more entries that can be returned using the current
   * iterator, advance to the next iterator that has entries.
   *
   * @return `true` if there is a current iterator that has entries
   */
  bool _advanceToNextIterator() {
    _iteratorIndex++;
    while (_iteratorIndex < _iterators.length) {
      MapIterator<K, V> iterator = _iterators[_iteratorIndex];
      if (iterator.moveNext()) {
        _currentIterator = iterator;
        return true;
      }
      _iteratorIndex++;
    }
    return false;
  }
}

/**
 * Instances of the class `SingleMapIterator` implement an iterator that can be used to access
 * the entries in a single map.
 */
class SingleMapIterator<K, V> implements MapIterator<K, V> {
  /**
   * The [Map] containing the entries to be iterated over.
   */
  final Map<K, V> _map;

  /**
   * The iterator used to access the entries.
   */
  Iterator<K> _keyIterator;

  /**
   * The current key, or `null` if there is no current key.
   */
  K _currentKey;

  /**
   * The current value.
   */
  V _currentValue;

  /**
   * Initialize a newly created iterator to return the entries from the given map.
   *
   * @param map the map containing the entries to be iterated over
   */
  SingleMapIterator(this._map) {
    this._keyIterator = _map.keys.iterator;
  }

  @override
  K get key {
    if (_currentKey == null) {
      throw new StateError('No element');
    }
    return _currentKey;
  }

  @override
  V get value {
    if (_currentKey == null) {
      throw new StateError('No element');
    }
    if (_currentValue == null) {
      _currentValue = _map[_currentKey];
    }
    return _currentValue;
  }

  @override
  void set value(V newValue) {
    if (_currentKey == null) {
      throw new StateError('No element');
    }
    _currentValue = newValue;
    _map[_currentKey] = newValue;
  }

  @override
  bool moveNext() {
    if (_keyIterator.moveNext()) {
      _currentKey = _keyIterator.current;
      _currentValue = null;
      return true;
    } else {
      _currentKey = null;
      return false;
    }
  }

  /**
   * Returns a new [SingleMapIterator] instance for the given [Map].
   */
  static SingleMapIterator forMap(Map map) => new SingleMapIterator(map);
}

/**
 * Instances of the class `TokenMap` map one set of tokens to another set of tokens.
 */
class TokenMap {
  /**
   * A table mapping tokens to tokens. This should be replaced by a more performant implementation.
   * One possibility is a pair of parallel arrays, with keys being sorted by their offset and a
   * cursor indicating where to start searching.
   */
  Map<Token, Token> _map = new HashMap<Token, Token>();

  /**
   * Return the token that is mapped to the given token, or `null` if there is no token
   * corresponding to the given token.
   *
   * @param key the token being mapped to another token
   * @return the token that is mapped to the given token
   */
  Token get(Token key) => _map[key];

  /**
   * Map the key to the value.
   *
   * @param key the token being mapped to the value
   * @param value the token to which the key will be mapped
   */
  void put(Token key, Token value) {
    _map[key] = value;
  }
}
