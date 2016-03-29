// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.impact;

import '../dart_types.dart';
import '../elements/elements.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../universe/world_impact.dart';
import '../universe/use.dart';

import 'keys.dart';
import 'serialization.dart';

/// Visitor that serializes a [WorldImpact] object using an [ObjectEncoder].
class ImpactSerializer implements WorldImpactVisitor {
  final ListEncoder staticUses;
  final ListEncoder dynamicUses;
  final ListEncoder typeUses;

  ImpactSerializer(ObjectEncoder objectEncoder)
      : staticUses = objectEncoder.createList(Key.STATIC_USES),
        dynamicUses = objectEncoder.createList(Key.DYNAMIC_USES),
        typeUses = objectEncoder.createList(Key.TYPE_USES);

  @override
  void visitDynamicUse(DynamicUse dynamicUse) {
    ObjectEncoder object = dynamicUses.createObject();
    object.setEnum(Key.KIND, dynamicUse.selector.kind);

    object.setInt(Key.ARGUMENTS,
        dynamicUse.selector.callStructure.argumentCount);
    object.setStrings(Key.NAMED_ARGUMENTS,
        dynamicUse.selector.callStructure.namedArguments);

    object.setString(Key.NAME,
        dynamicUse.selector.memberName.text);
    object.setBool(Key.IS_SETTER,
        dynamicUse.selector.memberName.isSetter);
    if (dynamicUse.selector.memberName.library != null) {
      object.setElement(Key.LIBRARY,
        dynamicUse.selector.memberName.library);
    }
  }

  @override
  void visitStaticUse(StaticUse staticUse) {
    if (staticUse.element.isGenerativeConstructor &&
        staticUse.element.enclosingClass.isUnnamedMixinApplication) {
      // TODO(johnniwinther): Handle static use of forwarding constructors.
      return;
    }
    ObjectEncoder object = staticUses.createObject();
    object.setEnum(Key.KIND, staticUse.kind);
    object.setElement(Key.ELEMENT, staticUse.element);
  }

  @override
  void visitTypeUse(TypeUse typeUse) {
    ObjectEncoder object = typeUses.createObject();
    object.setEnum(Key.KIND, typeUse.kind);
    object.setType(Key.TYPE, typeUse.type);
  }
}

/// A deserialized [WorldImpact] object.
class DeserializedWorldImpact extends WorldImpact with WorldImpactBuilder {}

class ImpactDeserializer {
  /// Deserializes a [WorldImpact] from [objectDecoder].
  static WorldImpact deserializeImpact(ObjectDecoder objectDecoder) {
    DeserializedWorldImpact worldImpact = new DeserializedWorldImpact();
    ListDecoder staticUses = objectDecoder.getList(Key.STATIC_USES);
    for (int index = 0; index < staticUses.length; index++) {
      ObjectDecoder object = staticUses.getObject(index);
      StaticUseKind kind = object.getEnum(Key.KIND, StaticUseKind.values);
      Element element = object.getElement(Key.ELEMENT);
      worldImpact.registerStaticUse(new StaticUse.internal(element, kind));
    }
    ListDecoder dynamicUses = objectDecoder.getList(Key.DYNAMIC_USES);
    for (int index = 0; index < dynamicUses.length; index++) {
      ObjectDecoder object = dynamicUses.getObject(index);
      SelectorKind kind = object.getEnum(Key.KIND, SelectorKind.values);
      int argumentCount = object.getInt(Key.ARGUMENTS);
      List<String> namedArguments =
          object.getStrings(Key.NAMED_ARGUMENTS, isOptional: true);
      String name = object.getString(Key.NAME);
      bool isSetter = object.getBool(Key.IS_SETTER);
      LibraryElement library = object.getElement(Key.LIBRARY, isOptional: true);
      worldImpact.registerDynamicUse(
          new DynamicUse(
              new Selector(
                  kind,
                  new Name(name, library, isSetter: isSetter),
                  new CallStructure(argumentCount, namedArguments)),
              null));
    }
    ListDecoder typeUses = objectDecoder.getList(Key.TYPE_USES);
    for (int index = 0; index < typeUses.length; index++) {
      ObjectDecoder object = typeUses.getObject(index);
      TypeUseKind kind = object.getEnum(Key.KIND, TypeUseKind.values);
      DartType type = object.getType(Key.TYPE);
      worldImpact.registerTypeUse(new TypeUse.internal(type, kind));
    }
    return worldImpact;
  }
}
