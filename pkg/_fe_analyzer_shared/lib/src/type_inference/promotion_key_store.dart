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

  final List<Variable?> _keyToVariable = [];

  /// List of maps indicating the set of properties of each promotable entity
  /// being tracked by flow analysis.  The list is indexed by the promotion key
  /// of the target, and the map is indexed by the property name.
  ///
  /// Null list elements are considered equivalent to an empty map (this allows
  /// us so save memory due to the fact that most entries will not be accessed).
  final List<Map<String, int>?> _properties = [];

  /// List of integers indicating, for each promotable entity, the key of the
  /// next promotable entity whose [_rootVariableKey] is the same.  Keys with
  /// the same root are linked together in a loop (so to iterate through them,
  /// continue walking the chain until you reach your starting point).
  final List<int> _nextKeyWithSameRoot = [];

  /// List of integers indicating, for each promotable entity, the variable key
  /// for the variable that forms the root of the property accesses that led
  /// to this variable key.  For example, the entry for a property access
  /// `a.b.c` points to the promotion key for `a`.
  final List<int> _rootVariableKey = [];

  /// Gets the key of the next promotable entity whose [_rootVariableKey] is the
  /// same as [key].  Keys with the same root are linked together in a loop (so
  /// to iterate through them, continue walking the chain until you reach your
  /// starting point).
  int getNextKeyWithSameRoot(int key) => _nextKeyWithSameRoot[key];

  int getProperty(int targetKey, String propertyName) =>
      (_properties[targetKey] ??= {})[propertyName] ??=
          _makeNewKey(targetKey: targetKey);

  /// Gets the variable key for the variable that forms the root of the property
  /// accesses that led to [promotionKey].  For example, the root variable key
  /// for a property access `a.b.c` is the promotion key for `a`.
  int getRootVariableKey(int promotionKey) => _rootVariableKey[promotionKey];

  int keyForVariable(Variable variable) =>
      _variableKeys[variable] ??= _makeNewKey(variable: variable);

  Variable? variableForKey(int variableKey) => _keyToVariable[variableKey];

  int _makeNewKey({Variable? variable, int? targetKey}) {
    int key = _keyToVariable.length;
    _keyToVariable.add(variable);
    _properties.add(null);
    if (targetKey == null) {
      _rootVariableKey.add(key);
      // This key does not represent a property, so its _nextKeyWithSameRoot
      // pointer should point to itself.
      _nextKeyWithSameRoot.add(key);
    } else {
      _rootVariableKey.add(_rootVariableKey[targetKey]);
      // This key represents a property of [targetKey], so its
      // _nextKeyWithSameRoot should be linked into whatever chain [targetKey]
      // is in.
      _nextKeyWithSameRoot.add(_nextKeyWithSameRoot[targetKey]);
      _nextKeyWithSameRoot[targetKey] = key;
    }
    return key;
  }
}
