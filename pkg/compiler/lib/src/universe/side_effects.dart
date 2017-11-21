// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.side_effects;

import '../elements/entities.dart';

class SideEffects {
  // Changes flags.
  static const int FLAG_CHANGES_INDEX = 0;
  static const int FLAG_CHANGES_INSTANCE_PROPERTY = FLAG_CHANGES_INDEX + 1;
  static const int FLAG_CHANGES_STATIC_PROPERTY =
      FLAG_CHANGES_INSTANCE_PROPERTY + 1;
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

  SideEffects.fromFlags(this._flags);

  bool operator ==(other) => _flags == other._flags;

  int get hashCode => throw new UnsupportedError('SideEffects.hashCode');

  bool _getFlag(int position) {
    return (_flags & (1 << position)) != 0;
  }

  bool _setFlag(int position) {
    int before = _flags;
    _flags |= (1 << position);
    return before != _flags;
  }

  bool _clearFlag(int position) {
    int before = _flags;
    _flags &= ~(1 << position);
    return before != _flags;
  }

  int getChangesFlags() {
    return _flags & ((1 << FLAG_CHANGES_COUNT) - 1);
  }

  int getDependsOnFlags() {
    return (_flags & ((1 << FLAG_DEPENDS_ON_COUNT) - 1)) >> FLAG_CHANGES_COUNT;
  }

  bool hasSideEffects() => getChangesFlags() != 0;
  bool dependsOnSomething() => getDependsOnFlags() != 0;

  bool setAllSideEffects() {
    int before = _flags;
    _flags |= ((1 << FLAG_CHANGES_COUNT) - 1);
    return before != _flags;
  }

  bool clearAllSideEffects() {
    int before = _flags;
    _flags &= ~((1 << FLAG_CHANGES_COUNT) - 1);
    return before != _flags;
  }

  bool setDependsOnSomething() {
    int before = _flags;
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    _flags |= (((1 << count) - 1) << FLAG_CHANGES_COUNT);
    return before != _flags;
  }

  bool clearAllDependencies() {
    int before = _flags;
    int count = FLAG_DEPENDS_ON_COUNT - FLAG_CHANGES_COUNT;
    _flags &= ~(((1 << count) - 1) << FLAG_CHANGES_COUNT);
    return before != _flags;
  }

  bool dependsOnStaticPropertyStore() {
    return _getFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }

  bool setDependsOnStaticPropertyStore() {
    return _setFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }

  bool clearDependsOnStaticPropertyStore() {
    return _clearFlag(FLAG_DEPENDS_ON_STATIC_PROPERTY_STORE);
  }

  bool setChangesStaticProperty() {
    return _setFlag(FLAG_CHANGES_STATIC_PROPERTY);
  }

  bool clearChangesStaticProperty() {
    return _clearFlag(FLAG_CHANGES_STATIC_PROPERTY);
  }

  bool changesStaticProperty() => _getFlag(FLAG_CHANGES_STATIC_PROPERTY);

  bool dependsOnIndexStore() => _getFlag(FLAG_DEPENDS_ON_INDEX_STORE);

  bool setDependsOnIndexStore() {
    return _setFlag(FLAG_DEPENDS_ON_INDEX_STORE);
  }

  bool clearDependsOnIndexStore() {
    return _clearFlag(FLAG_DEPENDS_ON_INDEX_STORE);
  }

  bool setChangesIndex() {
    return _setFlag(FLAG_CHANGES_INDEX);
  }

  bool clearChangesIndex() {
    return _clearFlag(FLAG_CHANGES_INDEX);
  }

  bool changesIndex() => _getFlag(FLAG_CHANGES_INDEX);

  bool dependsOnInstancePropertyStore() {
    return _getFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }

  bool setDependsOnInstancePropertyStore() {
    return _setFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }

  bool clearDependsOnInstancePropertyStore() {
    return _setFlag(FLAG_DEPENDS_ON_INSTANCE_PROPERTY_STORE);
  }

  bool setChangesInstanceProperty() {
    return _setFlag(FLAG_CHANGES_INSTANCE_PROPERTY);
  }

  bool clearChangesInstanceProperty() {
    return _clearFlag(FLAG_CHANGES_INSTANCE_PROPERTY);
  }

  bool changesInstanceProperty() => _getFlag(FLAG_CHANGES_INSTANCE_PROPERTY);

  static int computeDependsOnFlags(int flags) => flags << FLAG_CHANGES_COUNT;

  bool dependsOn(int dependsFlags) {
    return (_flags & dependsFlags) != 0;
  }

  bool add(SideEffects other) {
    int before = _flags;
    _flags |= other._flags;
    return before != _flags;
  }

  void setTo(SideEffects other) {
    _flags = other._flags;
  }

  bool contains(SideEffects other) {
    return (_flags | other._flags) == _flags;
  }

  int get flags => _flags;

  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Reads');
    if (!dependsOnSomething()) {
      buffer.write(' nothing');
    } else if (dependsOnIndexStore() &&
        dependsOnInstancePropertyStore() &&
        dependsOnStaticPropertyStore()) {
      buffer.write(' anything');
    } else {
      String comma = '';
      if (dependsOnIndexStore()) {
        buffer.write(' index');
        comma = ',';
      }
      if (dependsOnInstancePropertyStore()) {
        buffer.write('$comma field');
        comma = ',';
      }
      if (dependsOnStaticPropertyStore()) {
        buffer.write('$comma static');
      }
    }
    buffer.write('; writes');
    if (!hasSideEffects()) {
      buffer.write(' nothing');
    } else if (changesIndex() &&
        changesInstanceProperty() &&
        changesStaticProperty()) {
      buffer.write(' anything');
    } else {
      String comma = '';
      if (changesIndex()) {
        buffer.write(' index');
        comma = ',';
      }
      if (changesInstanceProperty()) {
        buffer.write('$comma field');
        comma = ',';
      }
      if (changesStaticProperty()) {
        buffer.write('$comma static');
      }
    }
    buffer.write('.');
    return buffer.toString();
  }
}

class SideEffectsBuilder {
  final MemberEntity _member;
  final SideEffects _sideEffects = new SideEffects.empty();
  final bool _free;
  Set<SideEffectsBuilder> _depending;

  SideEffectsBuilder(this._member) : _free = false;

  SideEffectsBuilder.free(this._member) : _free = true;

  void setChangesInstanceProperty() {
    if (_free) return;
    _sideEffects.setChangesInstanceProperty();
  }

  void setDependsOnInstancePropertyStore() {
    if (_free) return;
    _sideEffects.setDependsOnInstancePropertyStore();
  }

  void setChangesStaticProperty() {
    if (_free) return;
    _sideEffects.setChangesStaticProperty();
  }

  void setDependsOnStaticPropertyStore() {
    if (_free) return;
    _sideEffects.setDependsOnStaticPropertyStore();
  }

  void setAllSideEffectsAndDependsOnSomething() {
    if (_free) return;
    _sideEffects.setAllSideEffects();
    _sideEffects.setDependsOnSomething();
  }

  void setAllSideEffects() {
    if (_free) return;
    _sideEffects.setAllSideEffects();
  }

  void addInput(SideEffectsBuilder input) {
    if (_free) return;
    (input._depending ??= new Set<SideEffectsBuilder>()).add(this);
  }

  bool add(SideEffects input) {
    if (_free) return false;
    return _sideEffects.add(input);
  }

  SideEffects get sideEffects => _sideEffects;

  Iterable<SideEffectsBuilder> get depending =>
      _depending != null ? _depending : const <SideEffectsBuilder>[];

  MemberEntity get member => _member;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('SideEffectsBuilder(member=$member,');
    sb.write('free=$_free,');
    sb.write('sideEffects=$sideEffects,');
    sb.write('depending=${depending.map((s) => s.member).join(',')},');
    return sb.toString();
  }
}
