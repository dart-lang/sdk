// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe.side_effects;

import '../elements/entities.dart';
import '../serialization/serialization.dart';
import '../util/bitset.dart';
import '../util/enumset.dart';

enum SideEffectsFlag {
  index_,
  instanceProperty,
  staticProperty,
}

final _changes = EnumSetDomain<SideEffectsFlag>(0, SideEffectsFlag.values);
final _depends =
    EnumSetDomain<SideEffectsFlag>(_changes.nextOffset, SideEffectsFlag.values);

class SideEffects {
  /// Tag used for identifying serialized [SideEffects] objects in a debugging
  /// data stream.
  static const String tag = 'side-effects';

  Bitset _flags = Bitset.empty();

  static final Bitset allChanges = _changes.allValues;

  static final Bitset allDepends = _depends.allValues;

  SideEffects() {
    setAllSideEffects();
    setDependsOnSomething();
  }

  SideEffects.empty() {
    clearAllDependencies();
    clearAllSideEffects();
  }

  SideEffects._fromBits(int bits) : _flags = Bitset(bits);

  /// Deserializes a [SideEffects] object from [source].
  factory SideEffects.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    int bits = source.readInt();
    source.end(tag);
    return SideEffects._fromBits(bits);
  }

  /// Serializes this [SideEffects] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeInt(_flags.bits);
    sink.end(tag);
  }

  @override
  bool operator ==(Object other) =>
      other is SideEffects && _flags == other._flags;

  @override
  int get hashCode => throw UnsupportedError('SideEffects.hashCode');

  bool _getChangesFlag(SideEffectsFlag flag) => _changes.contains(_flags, flag);

  bool _getDependsFlag(SideEffectsFlag flag) => _depends.contains(_flags, flag);

  bool _setChangesFlag(SideEffectsFlag flag) {
    final before = _flags;
    _flags = _changes.add(_flags, flag);
    return before != _flags;
  }

  bool _setDependsFlag(SideEffectsFlag flag) {
    final before = _flags;
    _flags = _depends.add(_flags, flag);
    return before != _flags;
  }

  bool _clearChangesFlag(SideEffectsFlag flag) {
    final before = _flags;
    _flags = _changes.remove(_flags, flag);
    return before != _flags;
  }

  bool _clearDependsFlag(SideEffectsFlag flag) {
    final before = _flags;
    _flags = _depends.remove(_flags, flag);
    return before != _flags;
  }

  Bitset getChangesFlags() => _flags.intersection(allChanges);

  Bitset getDependsOnFlags() => _flags.intersection(allDepends);

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
      _getDependsFlag(SideEffectsFlag.staticProperty);

  bool setDependsOnStaticPropertyStore() =>
      _setDependsFlag(SideEffectsFlag.staticProperty);

  bool clearDependsOnStaticPropertyStore() =>
      _clearDependsFlag(SideEffectsFlag.staticProperty);

  bool setChangesStaticProperty() =>
      _setChangesFlag(SideEffectsFlag.staticProperty);

  bool clearChangesStaticProperty() =>
      _clearChangesFlag(SideEffectsFlag.staticProperty);

  bool changesStaticProperty() =>
      _getChangesFlag(SideEffectsFlag.staticProperty);

  bool dependsOnIndexStore() => _getDependsFlag(SideEffectsFlag.index_);

  bool setDependsOnIndexStore() => _setDependsFlag(SideEffectsFlag.index_);

  bool clearDependsOnIndexStore() => _clearDependsFlag(SideEffectsFlag.index_);

  bool setChangesIndex() => _setChangesFlag(SideEffectsFlag.index_);

  bool clearChangesIndex() => _clearChangesFlag(SideEffectsFlag.index_);

  bool changesIndex() => _getChangesFlag(SideEffectsFlag.index_);

  bool dependsOnInstancePropertyStore() =>
      _getDependsFlag(SideEffectsFlag.instanceProperty);

  bool setDependsOnInstancePropertyStore() =>
      _setDependsFlag(SideEffectsFlag.instanceProperty);

  bool clearDependsOnInstancePropertyStore() =>
      _setDependsFlag(SideEffectsFlag.instanceProperty);

  bool setChangesInstanceProperty() =>
      _setChangesFlag(SideEffectsFlag.instanceProperty);

  bool clearChangesInstanceProperty() =>
      _clearChangesFlag(SideEffectsFlag.instanceProperty);

  bool changesInstanceProperty() =>
      _getChangesFlag(SideEffectsFlag.instanceProperty);

  static Bitset computeDependsOnFlags(Bitset flags) =>
      Bitset(flags.bits << SideEffectsFlag.values.length);

  bool dependsOn(Bitset dependsFlags) => _flags.intersects(dependsFlags);

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
