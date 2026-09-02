// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This data structure assigns a unique [PromotionKey] to everything that might
/// undergo promotion in the user's code (local variables and properties). A
/// key is also assigned to `this`, because promotable properties can be reached
/// using `this` as a starting point.
class PromotionKeyStore<Variable extends Object> {
  final Map<Variable, PromotionKey> _variableKeys =
      new Map<Variable, PromotionKey>.identity();

  /// List whose `i`th entry is the [Variable] corresponding to the
  /// [PromotionKey] whose [PromotionKey.index] is `i`, or `null` if the key
  /// does not correspond to a specific [Variable].
  final List<Variable?> _keyToVariable = [];

  PromotionKey keyForVariable(Variable variable) =>
      _variableKeys[variable] ??= _makeNewKey(variable: variable);

  /// Creates a fresh promotion key that hasn't been used before (and won't be
  /// reused again).  This is used by flow analysis to model the synthetic
  /// variables used during pattern matching to cache the values that the
  /// pattern, and its subpatterns, are being matched against. It is also used
  /// to track the values returned by property gets.
  PromotionKey makeTemporaryKey() => _makeNewKey();

  /// Gets the [Variable] corresponding to [variableKey], or `null` if
  /// [variableKey] does not correspond to a specific [Variable].
  Variable? variableForKey(PromotionKey variableKey) =>
      _keyToVariable[variableKey.index];

  /// Creates a fresh promotion key. If a [variable] is provided, it is stored
  /// for later retrieval by [variableForKey].
  PromotionKey _makeNewKey({Variable? variable}) {
    PromotionKey key = new PromotionKey(_keyToVariable.length);
    _keyToVariable.add(variable);
    return key;
  }
}

/// Unique identifier assigned to a value tracked by flow analysis.
extension type PromotionKey(int index) {}
