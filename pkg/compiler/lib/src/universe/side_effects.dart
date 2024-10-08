// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.side_effects;

import '../elements/entities.dart';
import '../serialization/serialization.dart';
import '../util/enumset.dart';

typedef SideEffectsFlags = EnumSet<SideEffectsFlag>;

enum SideEffectsFlag {
  // Changes flags.
  changesIndex,
  changesInstanceProperty,
  changesStaticProperty,

  // Depends flags (one for each changes flag).
  dependsOnIndexStore,
  dependsOnInstancePropertyStore,
  dependsOnStaticPropertyStore,
  ;

  static final int _changesCount = dependsOnIndexStore.index;
  static final int _dependsCount = values.length - _changesCount;
}

class SideEffects {
  /// Tag used for identifying serialized [SideEffects] objects in a debugging
  /// data stream.
  static const String tag = 'side-effects';

  EnumSet<SideEffectsFlag> _flags = EnumSet.empty();

  static final EnumSet<SideEffectsFlag> allChanges =
      EnumSet((1 << SideEffectsFlag._changesCount) - 1);

  static final EnumSet<SideEffectsFlag> allDepends = EnumSet(
      ((1 << SideEffectsFlag._dependsCount) - 1) <<
          SideEffectsFlag._changesCount);

  SideEffects() {
    setAllSideEffects();
    setDependsOnSomething();
  }

  SideEffects.empty() {
    clearAllDependencies();
    clearAllSideEffects();
  }

  SideEffects.fromFlags(this._flags);

  /// Deserializes a [SideEffects] object from [source].
  factory SideEffects.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    int flags = source.readInt();
    source.end(tag);
    return SideEffects.fromFlags(EnumSet(flags));
  }

  /// Serializes this [SideEffects] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeInt(_flags.mask);
    sink.end(tag);
  }

  @override
  bool operator ==(Object other) =>
      other is SideEffects && _flags == other._flags;

  @override
  int get hashCode => throw UnsupportedError('SideEffects.hashCode');

  bool _getFlag(SideEffectsFlag flag) => _flags.contains(flag);

  bool _setFlag(SideEffectsFlag flag) {
    final before = _flags;
    _flags += flag;
    return before != _flags;
  }

  bool _clearFlag(SideEffectsFlag flag) {
    final before = _flags;
    _flags -= flag;
    return before != _flags;
  }

  EnumSet<SideEffectsFlag> getChangesFlags() => _flags.intersection(allChanges);

  EnumSet<SideEffectsFlag> getDependsOnFlags() =>
      _flags.intersection(allDepends);

  bool hasSideEffects() => getChangesFlags() != 0;
  bool dependsOnSomething() => getDependsOnFlags() != 0;

  bool setAllSideEffects() {
    final before = _flags;
    _flags = _flags.union(allChanges);
    return before != _flags;
  }

  bool clearAllSideEffects() {
    final before = _flags;
    _flags = _flags.setMinus(allChanges);
    return before != _flags;
  }

  bool setDependsOnSomething() {
    final before = _flags;
    _flags = _flags.union(allDepends);
    return before != _flags;
  }

  bool clearAllDependencies() {
    final before = _flags;
    _flags = _flags.setMinus(allDepends);
    return before != _flags;
  }

  bool dependsOnStaticPropertyStore() =>
      _getFlag(SideEffectsFlag.dependsOnStaticPropertyStore);

  bool setDependsOnStaticPropertyStore() =>
      _setFlag(SideEffectsFlag.dependsOnStaticPropertyStore);

  bool clearDependsOnStaticPropertyStore() =>
      _clearFlag(SideEffectsFlag.dependsOnStaticPropertyStore);

  bool setChangesStaticProperty() =>
      _setFlag(SideEffectsFlag.changesStaticProperty);

  bool clearChangesStaticProperty() =>
      _clearFlag(SideEffectsFlag.changesStaticProperty);

  bool changesStaticProperty() =>
      _getFlag(SideEffectsFlag.changesStaticProperty);

  bool dependsOnIndexStore() => _getFlag(SideEffectsFlag.dependsOnIndexStore);

  bool setDependsOnIndexStore() =>
      _setFlag(SideEffectsFlag.dependsOnIndexStore);

  bool clearDependsOnIndexStore() =>
      _clearFlag(SideEffectsFlag.dependsOnIndexStore);

  bool setChangesIndex() => _setFlag(SideEffectsFlag.changesIndex);

  bool clearChangesIndex() => _clearFlag(SideEffectsFlag.changesIndex);

  bool changesIndex() => _getFlag(SideEffectsFlag.changesIndex);

  bool dependsOnInstancePropertyStore() =>
      _getFlag(SideEffectsFlag.dependsOnInstancePropertyStore);

  bool setDependsOnInstancePropertyStore() =>
      _setFlag(SideEffectsFlag.dependsOnInstancePropertyStore);

  bool clearDependsOnInstancePropertyStore() =>
      _setFlag(SideEffectsFlag.dependsOnInstancePropertyStore);

  bool setChangesInstanceProperty() =>
      _setFlag(SideEffectsFlag.changesInstanceProperty);

  bool clearChangesInstanceProperty() =>
      _clearFlag(SideEffectsFlag.changesInstanceProperty);

  bool changesInstanceProperty() =>
      _getFlag(SideEffectsFlag.changesInstanceProperty);

  static EnumSet<SideEffectsFlag> computeDependsOnFlags(
          EnumSet<SideEffectsFlag> flags) =>
      EnumSet(flags.mask << SideEffectsFlag._changesCount);

  bool dependsOn(EnumSet<SideEffectsFlag> dependsFlags) =>
      _flags.intersects(dependsFlags);

  bool add(SideEffects other) {
    final before = _flags;
    _flags = _flags.union(other._flags);
    return before != _flags;
  }

  void setTo(SideEffects other) {
    _flags = other._flags;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('SideEffects(reads');
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
    buffer.write(')');
    return buffer.toString();
  }
}

class SideEffectsBuilder {
  final MemberEntity _member;
  final SideEffects _sideEffects = SideEffects.empty();
  final bool _free;
  Set<SideEffectsBuilder>? _depending;

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
    (input._depending ??= {}).add(this);
  }

  bool add(SideEffects input) {
    if (_free) return false;
    return _sideEffects.add(input);
  }

  SideEffects get sideEffects => _sideEffects;

  Iterable<SideEffectsBuilder> get depending => _depending ?? const [];

  MemberEntity get member => _member;

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('SideEffectsBuilder(member=$member,');
    sb.write('free=$_free,');
    sb.write('sideEffects=$sideEffects,');
    sb.write('depending=${depending.map((s) => s.member).join(',')},');
    return sb.toString();
  }
}
