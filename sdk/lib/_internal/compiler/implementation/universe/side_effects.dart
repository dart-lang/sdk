// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of universe;

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

  int flags = 0;

  SideEffects() {
    setAllSideEffects();
    setDependsOnSomething();
  }

  SideEffects.empty();

  bool operator==(other) => flags == other.flags;

  int get hashCode => throw new UnsupportedError('SideEffects.hashCode');

  bool getFlag(int position) => (flags & (1 << position)) != 0;
  void setFlag(int position) { flags |= (1 << position); }

  int getChangesFlags() => flags & ((1 << FLAG_CHANGES_COUNT) - 1);
  int getDependsOnFlags() {
    return (flags & ((1 << FLAG_DEPENDS_ON_COUNT) - 1)) >> FLAG_CHANGES_COUNT;
  }

  bool hasSideEffects() => getChangesFlags() != 0;
  bool dependsOnSomething() => getDependsOnFlags() != 0;

  void setAllSideEffects() { flags |= ((1 << FLAG_CHANGES_COUNT) - 1); }

  void clearAllSideEffects() { flags &= ~((1 << FLAG_CHANGES_COUNT) - 1); }

  void setDependsOnSomething() {
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    flags |= (((1 << count) - 1) << FLAG_CHANGES_COUNT);
  }
  void clearAllDependencies() {
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    flags &= ~(((1 << count) - 1) << FLAG_CHANGES_COUNT);
  }

  bool dependsOnStaticPropertyStore() {
    return getFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }
  void setDependsOnStaticPropertyStore() {
    setFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }
  void setChangesStaticProperty() { setFlag(FLAG_CHANGES_STATIC_PROPERTY); }
  bool changesStaticProperty() => getFlag(FLAG_CHANGES_STATIC_PROPERTY);

  bool dependsOnIndexStore() => getFlag(FLAG_DEPENDS_ON_INDEX_STORE);
  void setDependsOnIndexStore() { setFlag(FLAG_DEPENDS_ON_INDEX_STORE); }
  void setChangesIndex() { setFlag(FLAG_CHANGES_INDEX); }
  bool changesIndex() => getFlag(FLAG_CHANGES_INDEX);

  bool dependsOnInstancePropertyStore() {
    return getFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }
  void setDependsOnInstancePropertyStore() {
    setFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }
  void setChangesInstanceProperty() { setFlag(FLAG_CHANGES_INSTANCE_PROPERTY); }
  bool changesInstanceProperty() => getFlag(FLAG_CHANGES_INSTANCE_PROPERTY);

  static int computeDependsOnFlags(int flags) => flags << FLAG_CHANGES_COUNT;

  bool dependsOn(int dependsFlags) => (flags & dependsFlags) != 0;

  void add(SideEffects other) {
    flags |= other.flags;
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
