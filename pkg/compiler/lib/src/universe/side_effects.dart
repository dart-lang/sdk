// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.side_effects;

import '../common.dart';

class SideEffects {
  // Changes flags.
  static const int FLAG_CHANGES_INDEX = 0;
  static const int FLAG_CHANGES_INSTANCE_PROPERTY = FLAG_CHANGES_INDEX + 1;
  static const int FLAG_CHANGES_STATIC_PROPERTY
      = FLAG_CHANGES_INSTANCE_PROPERTY + 1;
  static const int FLAG_CHANGES_COUNT = FLAG_CHANGES_STATIC_PROPERTY + 1;

  // Depends flags (one for each changes flag).
  static const int FLAG_DEPENDS_ON_INDEX_STORE = FLAG_CHANGES_COUNT;
  static const int FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE =
      FLAG_DEPENDS_ON_INDEX_STORE + 1;
  static const int FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE =
      FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE + 1;
  static const int FLAG_DEPENDS_ON_COUNT =
      FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE + 1;

  int _flags = 0;

  SideEffects() {
    setAllSideEffects();
    setDependsOnSomething();
  }

  SideEffects.empty() {
    clearAllDependencies();
    clearAllSideEffects();
  }

  bool operator==(other) => _flags == other._flags;

  int get hashCode => throw new UnsupportedError('SideEffects.hashCode');

  bool _getFlag(int position) => (_flags & (1 << position)) != 0;
  void _setFlag(int position) { _flags |= (1 << position); }
  void _clearFlag(int position) { _flags &= ~(1 << position); }

  int getChangesFlags() => _flags & ((1 << FLAG_CHANGES_COUNT) - 1);
  int getDependsOnFlags() {
    return (_flags & ((1 << FLAG_DEPENDS_ON_COUNT) - 1)) >> FLAG_CHANGES_COUNT;
  }

  bool hasSideEffects() => getChangesFlags() != 0;
  bool dependsOnSomething() => getDependsOnFlags() != 0;

  void setAllSideEffects() { _flags |= ((1 << FLAG_CHANGES_COUNT) - 1); }

  void clearAllSideEffects() { _flags &= ~((1 << FLAG_CHANGES_COUNT) - 1); }

  void setDependsOnSomething() {
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    _flags |= (((1 << count) - 1) << FLAG_CHANGES_COUNT);
  }
  void clearAllDependencies() {
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    _flags &= ~(((1 << count) - 1) << FLAG_CHANGES_COUNT);
  }

  bool dependsOnStaticPropertyStore() {
    return _getFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }
  void setDependsOnStaticPropertyStore() {
    _setFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }
  void clearDependsOnStaticPropertyStore() {
    _clearFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }
  void setChangesStaticProperty() { _setFlag(FLAG_CHANGES_STATIC_PROPERTY); }
  void clearChangesStaticProperty() {
    _clearFlag(FLAG_CHANGES_STATIC_PROPERTY);
  }
  bool changesStaticProperty() => _getFlag(FLAG_CHANGES_STATIC_PROPERTY);

  bool dependsOnIndexStore() => _getFlag(FLAG_DEPENDS_ON_INDEX_STORE);
  void setDependsOnIndexStore() { _setFlag(FLAG_DEPENDS_ON_INDEX_STORE); }
  void clearDependsOnIndexStore() { _clearFlag(FLAG_DEPENDS_ON_INDEX_STORE); }
  void setChangesIndex() { _setFlag(FLAG_CHANGES_INDEX); }
  void clearChangesIndex() { _clearFlag(FLAG_CHANGES_INDEX); }
  bool changesIndex() => _getFlag(FLAG_CHANGES_INDEX);

  bool dependsOnInstancePropertyStore() {
    return _getFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }
  void setDependsOnInstancePropertyStore() {
    _setFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }
  void clearDependsOnInstancePropertyStore() {
    _setFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }
  void setChangesInstanceProperty() {
    _setFlag(FLAG_CHANGES_INSTANCE_PROPERTY);
  }
  void clearChangesInstanceProperty() {
    _clearFlag(FLAG_CHANGES_INSTANCE_PROPERTY);
  }
  bool changesInstanceProperty() => _getFlag(FLAG_CHANGES_INSTANCE_PROPERTY);

  static int computeDependsOnFlags(int flags) => flags << FLAG_CHANGES_COUNT;

  bool dependsOn(int dependsFlags) => (_flags & dependsFlags) != 0;

  void add(SideEffects other) {
    _flags |= other._flags;
  }

  void setTo(SideEffects other) {
    _flags = other._flags;
  }

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Depends on');
    if (dependsOnIndexStore()) buffer.write(' []');
    if (dependsOnInstancePropertyStore()) buffer.write(' field store');
    if (dependsOnStaticPropertyStore()) buffer.write(' static store');
    if (!dependsOnSomething()) buffer.write(' nothing');
    buffer.write(', Changes');
    if (changesIndex()) buffer.write(' []');
    if (changesInstanceProperty()) buffer.write(' field');
    if (changesStaticProperty()) buffer.write(' static');
    if (!hasSideEffects()) buffer.write(' nothing');
    buffer.write('.');
    return buffer.toString();
  }
}
