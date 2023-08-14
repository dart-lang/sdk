// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This data structure assigns a unique integer identifier to everything that
/// might undergo promotion in the user's code (local variables and properties).
/// An integer identifier is also assigned to `this` (even though `this` is not
/// promotable), because promotable properties can be reached using `this` as a
/// starting point.
class PromotionKeyStore<Variable extends Object> {
  /// Special promotion key to represent `this`.
  late final int thisPromotionKey = _makeNewKey();

  final Map<Variable, int> _variableKeys = new Map<Variable, int>.identity();

  /// List whose `i`th entry is the [Variable] corresponding to promotion key
  /// `i`, or `null`, if promotion key `i` does not correspond to a specific
  /// [Variable].
  final List<Variable?> _keyToVariable = [];

  int keyForVariable(Variable variable) =>
      _variableKeys[variable] ??= _makeNewKey(variable: variable);

  /// Creates a fresh promotion key that hasn't been used before (and won't be
  /// reused again).  This is used by flow analysis to model the synthetic
  /// variables used during pattern matching to cache the values that the
  /// pattern, and its subpatterns, are being matched against. It is also used
  /// to track the values returned by property gets.
  int makeTemporaryKey() => _makeNewKey();

  /// Gets the [Variable] corresponding to [variableKey], or `null` if
  /// [variableKey] does not correspond to a specific [Variable].
  Variable? variableForKey(int variableKey) => _keyToVariable[variableKey];

  /// Creates a fresh promotion key. If a [variable] is provided, it is stored
  /// for later retrieval by [variableForKey].
  int _makeNewKey({Variable? variable}) {
    int key = _keyToVariable.length;
    _keyToVariable.add(variable);
    return key;
  }
}
