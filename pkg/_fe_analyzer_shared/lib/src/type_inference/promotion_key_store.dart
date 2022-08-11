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
  late final int thisPromotionKey = _makeNewKey(null);

  final Map<Variable, int> _variableKeys = new Map<Variable, int>.identity();

  final List<Variable?> _keyToVariable = [];

  /// List of maps indicating the set of properties of each promotable entity
  /// being tracked by flow analysis.  The list is indexed by the promotion key
  /// of the target, and the map is indexed by the property name.
  ///
  /// Null list elements are considered equivalent to an empty map (this allows
  /// us so save memory due to the fact that most entries will not be accessed).
  final List<Map<String, int>?> _properties = [];

  int getProperty(int targetKey, String propertyName) =>
      (_properties[targetKey] ??= {})[propertyName] ??= _makeNewKey(null);

  int keyForVariable(Variable variable) =>
      _variableKeys[variable] ??= _makeNewKey(variable);

  Variable? variableForKey(int variableKey) => _keyToVariable[variableKey];

  int _makeNewKey(Variable? variable) {
    int key = _keyToVariable.length;
    _keyToVariable.add(variable);
    _properties.add(null);
    return key;
  }
}
