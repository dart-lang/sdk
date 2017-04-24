// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.types;

import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import 'keys.dart';
import 'serialization.dart';

/// Visitor that serializes a [ResolutionDartType] by encoding it into an
/// [ObjectEncoder].
///
/// This class is called from the [Serializer] when a [ResolutionDartType] needs
/// serialization. The [ObjectEncoder] ensures that any [Element], and other
/// [ResolutionDartType] that the serialized [ResolutionDartType] depends upon
/// are also serialized.
class TypeSerializer extends ResolutionDartTypeVisitor<dynamic, ObjectEncoder> {
  const TypeSerializer();

  void visitType(ResolutionDartType type, ObjectEncoder encoder) {
    throw new UnsupportedError('Unsupported type: $type');
  }

  void visitVoidType(ResolutionVoidType type, ObjectEncoder encoder) {}

  void visitTypeVariableType(
      ResolutionTypeVariableType type, ObjectEncoder encoder) {
    encoder.setElement(Key.ELEMENT, type.element);
    encoder.setBool(
        Key.IS_METHOD_TYPE_VARIABLE_TYPE, type is MethodTypeVariableType);
  }

  void visitFunctionType(ResolutionFunctionType type, ObjectEncoder encoder) {
    // TODO(johnniwinther): Support encoding of `type.element`.
    encoder.setType(Key.RETURN_TYPE, type.returnType);
    encoder.setTypes(Key.PARAMETER_TYPES, type.parameterTypes);
    encoder.setTypes(Key.OPTIONAL_PARAMETER_TYPES, type.optionalParameterTypes);
    encoder.setStrings(Key.NAMED_PARAMETERS, type.namedParameters);
    encoder.setTypes(Key.NAMED_PARAMETER_TYPES, type.namedParameterTypes);
  }

  void visitMalformedType(MalformedType type, ObjectEncoder encoder) {
    encoder.setElement(Key.ELEMENT, type.element);
  }

  void visitInterfaceType(ResolutionInterfaceType type, ObjectEncoder encoder) {
    encoder.setElement(Key.ELEMENT, type.element);
    encoder.setTypes(Key.TYPE_ARGUMENTS, type.typeArguments);
  }

  void visitTypedefType(ResolutionTypedefType type, ObjectEncoder encoder) {
    encoder.setElement(Key.ELEMENT, type.element);
    encoder.setTypes(Key.TYPE_ARGUMENTS, type.typeArguments);
  }

  void visitDynamicType(ResolutionDynamicType type, ObjectEncoder encoder) {}
}

/// Utility class for deserializing [ResolutionDartType]s.
///
/// This is used by the [Deserializer].
class TypeDeserializer {
  /// Deserializes a [ResolutionDartType] from an [ObjectDecoder].
  ///
  /// The class is called from the [Deserializer] when a [ResolutionDartType]
  /// needs deserialization. The [ObjectDecoder] ensures that any [Element],
  /// other [ResolutionDartType] that the deserialized [ResolutionDartType]
  /// depends upon are available.
  // ignore: MISSING_RETURN
  static ResolutionDartType deserialize(ObjectDecoder decoder) {
    ResolutionTypeKind typeKind =
        decoder.getEnum(Key.KIND, ResolutionTypeKind.values);
    switch (typeKind) {
      case ResolutionTypeKind.INTERFACE:
        return new ResolutionInterfaceType(decoder.getElement(Key.ELEMENT),
            decoder.getTypes(Key.TYPE_ARGUMENTS, isOptional: true));
      case ResolutionTypeKind.FUNCTION:
        // TODO(johnniwinther): Support decoding of `type.element`.
        return new ResolutionFunctionType.synthesized(
            decoder.getType(Key.RETURN_TYPE),
            decoder.getTypes(Key.PARAMETER_TYPES, isOptional: true),
            decoder.getTypes(Key.OPTIONAL_PARAMETER_TYPES, isOptional: true),
            decoder.getStrings(Key.NAMED_PARAMETERS, isOptional: true),
            decoder.getTypes(Key.NAMED_PARAMETER_TYPES, isOptional: true));
      case ResolutionTypeKind.TYPE_VARIABLE:
        TypeVariableElement element = decoder.getElement(Key.ELEMENT);
        if (decoder.getBool(Key.IS_METHOD_TYPE_VARIABLE_TYPE)) {
          return new MethodTypeVariableType(element);
        }
        return new ResolutionTypeVariableType(element);
      case ResolutionTypeKind.TYPEDEF:
        return new ResolutionTypedefType(decoder.getElement(Key.ELEMENT),
            decoder.getTypes(Key.TYPE_ARGUMENTS, isOptional: true));
      case ResolutionTypeKind.MALFORMED_TYPE:
        // TODO(johnniwinther): Do we need the 'userProvidedBadType' or maybe
        // just a toString of it?
        return new MalformedType(decoder.getElement(Key.ELEMENT), null);
      case ResolutionTypeKind.DYNAMIC:
        return const ResolutionDynamicType();
      case ResolutionTypeKind.VOID:
        return const ResolutionVoidType();
    }
  }
}
