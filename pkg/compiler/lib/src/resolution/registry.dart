// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.registry;

import '../common/resolution.dart' show ResolutionImpact;
import '../constants/expressions.dart';
import '../elements/entities.dart' show ClassEntity;
import '../universe/feature.dart';
import '../universe/world_impact.dart' show WorldImpact, WorldImpactBuilderImpl;
import '../util/enumset.dart' show EnumSet;
import '../util/util.dart' show Setlet;

class ResolutionWorldImpactBuilder extends WorldImpactBuilderImpl
    implements ResolutionImpact {
  final String name;
  EnumSet<Feature> _features;
  Setlet<MapLiteralUse> _mapLiterals;
  Setlet<ListLiteralUse> _listLiterals;
  Setlet<String> _constSymbolNames;
  Setlet<ConstantExpression> _constantLiterals;
  Setlet<dynamic> _nativeData;
  Setlet<ClassEntity> _seenClasses;
  Set<RuntimeTypeUse> _runtimeTypeUses;
  Set<GenericInstantiation> _genericInstantiations;

  ResolutionWorldImpactBuilder(this.name);

  @override
  bool get isEmpty => false;

  void registerMapLiteral(MapLiteralUse mapLiteralUse) {
    assert(mapLiteralUse != null);
    _mapLiterals ??= new Setlet<MapLiteralUse>();
    _mapLiterals.add(mapLiteralUse);
  }

  @override
  Iterable<MapLiteralUse> get mapLiterals {
    return _mapLiterals != null ? _mapLiterals : const <MapLiteralUse>[];
  }

  void registerListLiteral(ListLiteralUse listLiteralUse) {
    assert(listLiteralUse != null);
    _listLiterals ??= new Setlet<ListLiteralUse>();
    _listLiterals.add(listLiteralUse);
  }

  @override
  Iterable<ListLiteralUse> get listLiterals {
    return _listLiterals != null ? _listLiterals : const <ListLiteralUse>[];
  }

  void registerRuntimeTypeUse(RuntimeTypeUse runtimeTypeUse) {
    assert(runtimeTypeUse != null);
    _runtimeTypeUses ??= new Setlet<RuntimeTypeUse>();
    _runtimeTypeUses.add(runtimeTypeUse);
  }

  @override
  Iterable<RuntimeTypeUse> get runtimeTypeUses {
    return _runtimeTypeUses != null
        ? _runtimeTypeUses
        : const <RuntimeTypeUse>[];
  }

  void registerConstSymbolName(String name) {
    _constSymbolNames ??= new Setlet<String>();
    _constSymbolNames.add(name);
  }

  @override
  Iterable<String> get constSymbolNames {
    return _constSymbolNames != null ? _constSymbolNames : const <String>[];
  }

  void registerFeature(Feature feature) {
    _features ??= new EnumSet<Feature>();
    _features.add(feature);
  }

  @override
  Iterable<Feature> get features {
    return _features != null
        ? _features.iterable(Feature.values)
        : const <Feature>[];
  }

  void registerConstantLiteral(ConstantExpression constant) {
    _constantLiterals ??= new Setlet<ConstantExpression>();
    _constantLiterals.add(constant);
  }

  Iterable<ConstantExpression> get constantLiterals {
    return _constantLiterals != null
        ? _constantLiterals
        : const <ConstantExpression>[];
  }

  void registerNativeData(dynamic nativeData) {
    assert(nativeData != null);
    _nativeData ??= new Setlet<dynamic>();
    _nativeData.add(nativeData);
  }

  @override
  Iterable<dynamic> get nativeData {
    return _nativeData != null ? _nativeData : const <dynamic>[];
  }

  void registerSeenClass(ClassEntity seenClass) {
    _seenClasses ??= new Setlet<ClassEntity>();
    _seenClasses.add(seenClass);
  }

  @override
  Iterable<ClassEntity> get seenClasses {
    return _seenClasses ?? const <ClassEntity>[];
  }

  void registerInstantiation(GenericInstantiation instantiation) {
    _genericInstantiations ??= new Set<GenericInstantiation>();
    _genericInstantiations.add(instantiation);
  }

  @override
  Iterable<GenericInstantiation> get genericInstantiations {
    return _genericInstantiations ?? const <GenericInstantiation>[];
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('_ResolutionWorldImpact($name)');
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
    if (_listLiterals != null) {
      sb.write('\n list-literals:');
      for (ListLiteralUse use in _listLiterals) {
        sb.write('\n  $use');
      }
    }
    if (_constantLiterals != null) {
      sb.write('\n const-literals:');
      for (ConstantExpression constant in _constantLiterals) {
        sb.write('\n  ${constant.toDartText()}');
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
