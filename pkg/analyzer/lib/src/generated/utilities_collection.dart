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
