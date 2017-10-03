// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.impact;

import '../common/resolution.dart';
import '../constants/expressions.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../universe/feature.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart';
import '../util/enumset.dart';
import 'keys.dart';
import 'serialization.dart';
import 'serialization_util.dart';

/// Visitor that serializes a [ResolutionImpact] object using an
/// [ObjectEncoder].
class ImpactSerializer implements WorldImpactVisitor {
  final Element element;
  final ObjectEncoder objectEncoder;
  final ListEncoder staticUses;
  final ListEncoder dynamicUses;
  final ListEncoder typeUses;
  final SerializerPlugin nativeDataSerializer;

  ImpactSerializer(
      this.element, ObjectEncoder objectEncoder, this.nativeDataSerializer)
      : this.objectEncoder = objectEncoder,
        staticUses = objectEncoder.createList(Key.STATIC_USES),
        dynamicUses = objectEncoder.createList(Key.DYNAMIC_USES),
        typeUses = objectEncoder.createList(Key.TYPE_USES);

  void serialize(ResolutionImpact resolutionImpact) {
    resolutionImpact.apply(this);
    objectEncoder.setStrings(Key.SYMBOLS, resolutionImpact.constSymbolNames);
    objectEncoder.setConstants(
        Key.CONSTANTS, resolutionImpact.constantLiterals);
    objectEncoder.setEnums(Key.FEATURES, resolutionImpact.features);
    if (resolutionImpact.listLiterals.isNotEmpty) {
      ListEncoder encoder = objectEncoder.createList(Key.LISTS);
      for (ListLiteralUse use in resolutionImpact.listLiterals) {
        ObjectEncoder useEncoder = encoder.createObject();
        ResolutionInterfaceType type = use.type;
        useEncoder.setType(Key.TYPE, type);
        useEncoder.setBool(Key.IS_CONST, use.isConstant);
        useEncoder.setBool(Key.IS_EMPTY, use.isEmpty);
      }
    }
    if (resolutionImpact.mapLiterals.isNotEmpty) {
      ListEncoder encoder = objectEncoder.createList(Key.MAPS);
      for (MapLiteralUse use in resolutionImpact.mapLiterals) {
        ObjectEncoder useEncoder = encoder.createObject();
        ResolutionInterfaceType type = use.type;
        useEncoder.setType(Key.TYPE, type);
        useEncoder.setBool(Key.IS_CONST, use.isConstant);
        useEncoder.setBool(Key.IS_EMPTY, use.isEmpty);
      }
    }
    if (resolutionImpact.nativeData.isNotEmpty) {
      ListEncoder encoder = objectEncoder.createList(Key.NATIVE);
      for (dynamic data in resolutionImpact.nativeData) {
        nativeDataSerializer.onData(data, encoder.createObject());
      }
    }
  }

  @override
  void visitDynamicUse(DynamicUse dynamicUse) {
    ObjectEncoder object = dynamicUses.createObject();
    serializeSelector(dynamicUse.selector, object);
  }

  @override
  void visitStaticUse(StaticUse staticUse) {
    ObjectEncoder object = staticUses.createObject();
    object.setEnum(Key.KIND, staticUse.kind);
    serializeElementReference(
        element, Key.ELEMENT, Key.NAME, object, staticUse.element);
    if (staticUse.type != null) {
      object.setType(Key.TYPE, staticUse.type);
    }
  }

  @override
  void visitTypeUse(TypeUse typeUse) {
    ObjectEncoder object = typeUses.createObject();
    object.setEnum(Key.KIND, typeUse.kind);
    object.setType(Key.TYPE, typeUse.type);
  }

  @override
  void visitConstantUse(ConstantUse typeUse) {
    throw new UnsupportedError("ConstantUse serialization is not supported.");
  }
}

/// A deserialized [WorldImpact] object.
class DeserializedResolutionImpact extends WorldImpact
    implements ResolutionImpact {
  final Iterable<String> constSymbolNames;
  final Iterable<ConstantExpression> constantLiterals;
  final Iterable<DynamicUse> dynamicUses;
  final EnumSet<Feature> _features;
  final Iterable<ListLiteralUse> listLiterals;
  final Iterable<MapLiteralUse> mapLiterals;
  final Iterable<StaticUse> staticUses;
  final Iterable<TypeUse> typeUses;
  final Iterable<dynamic> nativeData;
  final Iterable<ClassEntity> seenClasses;

  DeserializedResolutionImpact(
      {this.constSymbolNames: const <String>[],
      this.constantLiterals: const <ConstantExpression>[],
      this.dynamicUses: const <DynamicUse>[],
      EnumSet<Feature> features,
      this.listLiterals: const <ListLiteralUse>[],
      this.mapLiterals: const <MapLiteralUse>[],
      this.staticUses: const <StaticUse>[],
      this.typeUses: const <TypeUse>[],
      this.nativeData: const <dynamic>[],
      this.seenClasses: const <ClassEntity>[]})
      : this._features = features;

  @override
  bool get isEmpty => false;

  Iterable<Feature> get features {
    return _features != null
        ? _features.iterable(Feature.values)
        : const <Feature>[];
  }
}

class ImpactDeserializer {
  /// Deserializes a [WorldImpact] from [objectDecoder].
  static ResolutionImpact deserializeImpact(Element element,
      ObjectDecoder objectDecoder, DeserializerPlugin nativeDataDeserializer) {
    ListDecoder staticUseDecoder = objectDecoder.getList(Key.STATIC_USES);
    List<StaticUse> staticUses = <StaticUse>[];
    for (int index = 0; index < staticUseDecoder.length; index++) {
      ObjectDecoder object = staticUseDecoder.getObject(index);
      StaticUseKind kind = object.getEnum(Key.KIND, StaticUseKind.values);
      Element usedElement =
          deserializeElementReference(element, Key.ELEMENT, Key.NAME, object);
      ResolutionDartType type = object.getType(Key.TYPE, isOptional: true);
      staticUses.add(new StaticUse.internal(usedElement, kind, type));
    }

    ListDecoder dynamicUseDecoder = objectDecoder.getList(Key.DYNAMIC_USES);
    List<DynamicUse> dynamicUses = <DynamicUse>[];
    for (int index = 0; index < dynamicUseDecoder.length; index++) {
      ObjectDecoder object = dynamicUseDecoder.getObject(index);
      Selector selector = deserializeSelector(object);
      dynamicUses.add(new DynamicUse(selector, null));
    }

    ListDecoder typeUseDecoder = objectDecoder.getList(Key.TYPE_USES);
    List<TypeUse> typeUses = <TypeUse>[];
    for (int index = 0; index < typeUseDecoder.length; index++) {
      ObjectDecoder object = typeUseDecoder.getObject(index);
      TypeUseKind kind = object.getEnum(Key.KIND, TypeUseKind.values);
      ResolutionDartType type = object.getType(Key.TYPE);
      typeUses.add(new TypeUse.internal(type, kind));
    }

    List<String> constSymbolNames =
        objectDecoder.getStrings(Key.SYMBOLS, isOptional: true);

    List<ConstantExpression> constantLiterals =
        objectDecoder.getConstants(Key.CONSTANTS, isOptional: true);

    EnumSet<Feature> features =
        objectDecoder.getEnums(Key.FEATURES, isOptional: true);

    ListDecoder listLiteralDecoder =
        objectDecoder.getList(Key.LISTS, isOptional: true);
    List<ListLiteralUse> listLiterals = const <ListLiteralUse>[];
    if (listLiteralDecoder != null) {
      listLiterals = <ListLiteralUse>[];
      for (int i = 0; i < listLiteralDecoder.length; i++) {
        ObjectDecoder useDecoder = listLiteralDecoder.getObject(i);
        ResolutionInterfaceType type = useDecoder.getType(Key.TYPE);
        bool isConstant = useDecoder.getBool(Key.IS_CONST);
        bool isEmpty = useDecoder.getBool(Key.IS_EMPTY);
        listLiterals.add(
            new ListLiteralUse(type, isConstant: isConstant, isEmpty: isEmpty));
      }
    }

    ListDecoder mapLiteralDecoder =
        objectDecoder.getList(Key.MAPS, isOptional: true);
    List<MapLiteralUse> mapLiterals = const <MapLiteralUse>[];
    if (mapLiteralDecoder != null) {
      mapLiterals = <MapLiteralUse>[];
      for (int i = 0; i < mapLiteralDecoder.length; i++) {
        ObjectDecoder useDecoder = mapLiteralDecoder.getObject(i);
        ResolutionInterfaceType type = useDecoder.getType(Key.TYPE);
        bool isConstant = useDecoder.getBool(Key.IS_CONST);
        bool isEmpty = useDecoder.getBool(Key.IS_EMPTY);
        mapLiterals.add(
            new MapLiteralUse(type, isConstant: isConstant, isEmpty: isEmpty));
      }
    }

    ListDecoder nativeDataDecoder =
        objectDecoder.getList(Key.NATIVE, isOptional: true);
    List<dynamic> nativeData = const <dynamic>[];
    if (nativeDataDecoder != null) {
      nativeData = <dynamic>[];
      for (int i = 0; i < nativeDataDecoder.length; i++) {
        dynamic data =
            nativeDataDeserializer.onData(nativeDataDecoder.getObject(i));
        if (data != null) {
          nativeData.add(data);
        }
      }
    }

    return new DeserializedResolutionImpact(
        constSymbolNames: constSymbolNames,
        constantLiterals: constantLiterals,
        dynamicUses: dynamicUses,
        features: features,
        listLiterals: listLiterals,
        mapLiterals: mapLiterals,
        staticUses: staticUses,
        typeUses: typeUses,
        nativeData: nativeData);
  }
}
