// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.registry;

import '../common/resolution.dart' show ResolutionImpact;
import '../constants/values.dart';
import '../elements/entities.dart' show ClassEntity, MemberEntity;
import '../elements/types.dart';
import '../native/behavior.dart' show NativeBehavior;
import '../universe/feature.dart';
import '../universe/world_impact.dart' show WorldImpact, WorldImpactBuilderImpl;
import '../util/enumset.dart' show EnumSet;
import '../util/util.dart' show Setlet;

class ResolutionWorldImpactBuilder extends WorldImpactBuilderImpl
    implements ResolutionImpact {
  final DartTypes _dartTypes;
  @override
  final MemberEntity member;
  EnumSet<Feature> _features;
  Setlet<MapLiteralUse> _mapLiterals;
  Setlet<SetLiteralUse> _setLiterals;
  Setlet<ListLiteralUse> _listLiterals;
  Setlet<String> _constSymbolNames;
  Setlet<ConstantValue> _constantLiterals;
  Setlet<NativeBehavior> _nativeData;
  Setlet<ClassEntity> _seenClasses;
  Set<RuntimeTypeUse> _runtimeTypeUses;
  Set<GenericInstantiation> _genericInstantiations;

  ResolutionWorldImpactBuilder(this._dartTypes, this.member);

  @override
  bool get isEmpty => false;

  void registerMapLiteral(MapLiteralUse mapLiteralUse) {
    assert(mapLiteralUse != null);
    _mapLiterals ??= Setlet();
    _mapLiterals.add(mapLiteralUse);
  }

  @override
  Iterable<MapLiteralUse> get mapLiterals => _mapLiterals ?? const [];

  void registerSetLiteral(SetLiteralUse setLiteralUse) {
    assert(setLiteralUse != null);
    _setLiterals ??= Setlet();
    _setLiterals.add(setLiteralUse);
  }

  @override
  Iterable<SetLiteralUse> get setLiterals => _setLiterals ?? const [];

  void registerListLiteral(ListLiteralUse listLiteralUse) {
    assert(listLiteralUse != null);
    _listLiterals ??= Setlet();
    _listLiterals.add(listLiteralUse);
  }

  @override
  Iterable<ListLiteralUse> get listLiterals => _listLiterals ?? const [];

  void registerRuntimeTypeUse(RuntimeTypeUse runtimeTypeUse) {
    assert(runtimeTypeUse != null);
    _runtimeTypeUses ??= Setlet();
    _runtimeTypeUses.add(runtimeTypeUse);
  }

  @override
  Iterable<RuntimeTypeUse> get runtimeTypeUses => _runtimeTypeUses ?? const [];

  void registerConstSymbolName(String name) {
    _constSymbolNames ??= Setlet();
    _constSymbolNames.add(name);
  }

  @override
  Iterable<String> get constSymbolNames => _constSymbolNames ?? const [];

  void registerFeature(Feature feature) {
    _features ??= EnumSet();
    _features.add(feature);
  }

  @override
  Iterable<Feature> get features {
    return _features != null
        ? _features.iterable(Feature.values)
        : const <Feature>[];
  }

  void registerConstantLiteral(ConstantValue constant) {
    _constantLiterals ??= Setlet();
    _constantLiterals.add(constant);
  }

  @override
  Iterable<ConstantValue> get constantLiterals => _constantLiterals ?? const [];

  void registerNativeData(NativeBehavior nativeData) {
    assert(nativeData != null);
    _nativeData ??= Setlet();
    _nativeData.add(nativeData);
  }

  @override
  Iterable<NativeBehavior> get nativeData => _nativeData ?? const [];

  void registerSeenClass(ClassEntity seenClass) {
    _seenClasses ??= Setlet();
    _seenClasses.add(seenClass);
  }

  @override
  Iterable<ClassEntity> get seenClasses => _seenClasses ?? const [];

  void registerInstantiation(GenericInstantiation instantiation) {
    _genericInstantiations ??= Setlet();
    _genericInstantiations.add(instantiation);
  }

  @override
  Iterable<GenericInstantiation> get genericInstantiations =>
      _genericInstantiations ?? const [];

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('ResolutionWorldImpactBuilder($member)');
    WorldImpact.printOn(sb, this);
    if (_features != null) {
      sb.write('\n features:');
      for (Feature feature in _features.iterable(Feature.values)) {
        sb.write('\n  $feature');
      }
    }
    if (_mapLiterals != null) {
      sb.write('\n map-literals:');
      for (MapLiteralUse use in _mapLiterals) {
        sb.write('\n  $use');
      }
    }
    if (_setLiterals != null) {
      sb.write('\n set-literals:');
      for (SetLiteralUse use in _setLiterals) {
        sb.write('\n  $use');
      }
    }
    if (_listLiterals != null) {
      sb.write('\n list-literals:');
      for (ListLiteralUse use in _listLiterals) {
        sb.write('\n  $use');
      }
    }
    if (_constantLiterals != null) {
      sb.write('\n const-literals:');
      for (ConstantValue constant in _constantLiterals) {
        sb.write('\n  ${constant.toDartText(_dartTypes)}');
      }
    }
    if (_constSymbolNames != null) {
      sb.write('\n const-symbol-names: $_constSymbolNames');
    }
    if (_nativeData != null) {
      sb.write('\n native-data:');
      for (var data in _nativeData) {
        sb.write('\n  $data');
      }
    }
    if (_genericInstantiations != null) {
      sb.write('\n instantiations:');
      for (var data in _genericInstantiations) {
        sb.write('\n  $data');
      }
    }
    return sb.toString();
  }
}
