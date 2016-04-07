// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.types;

import '../dart_types.dart';
import 'serialization.dart';
import 'keys.dart';

/// Visitor that serializes a [DartType] by encoding it into an [ObjectEncoder].
///
/// This class is called from the [Serializer] when a [DartType] needs
/// serialization. The [ObjectEncoder] ensures that any [Element], and other
/// [DartType] that the serialized [DartType] depends upon are also serialized.
class TypeSerializer extends DartTypeVisitor<dynamic, ObjectEncoder> {
  const TypeSerializer();

  void visitType(DartType type, ObjectEncoder encoder) {
    throw new UnsupportedError('Unsupported type: $type');
  }

  void visitVoidType(VoidType type, ObjectEncoder encoder) {}

  void visitTypeVariableType(TypeVariableType type, ObjectEncoder encoder) {
    encoder.setElement(Key.ELEMENT, type.element);
  }

  void visitFunctionType(FunctionType type, ObjectEncoder encoder) {
    // TODO(johnniwinther): Support encoding of `type.element`.
    encoder.setType(Key.RETURN_TYPE, type.returnType);
    encoder.setTypes(Key.PARAMETER_TYPES, type.parameterTypes);
    encoder.setTypes(Key.OPTIONAL_PARAMETER_TYPES, type.optionalParameterTypes);
    encoder.setStrings(Key.NAMED_PARAMETERS, type.namedParameters);
    encoder.setTypes(Key.NAMED_PARAMETER_TYPES, type.namedParameterTypes);
  }

  void visitMalformedType(MalformedType type, ObjectEncoder encoder) {}

  void visitInterfaceType(InterfaceType type, ObjectEncoder encoder) {
    encoder.setElement(Key.ELEMENT, type.element);
    encoder.setTypes(Key.TYPE_ARGUMENTS, type.typeArguments);
  }

  void visitTypedefType(TypedefType type, ObjectEncoder encoder) {
    encoder.setElement(Key.ELEMENT, type.element);
    encoder.setTypes(Key.TYPE_ARGUMENTS, type.typeArguments);
  }

  void visitDynamicType(DynamicType type, ObjectEncoder encoder) {}
}

/// Utility class for deserializing [DartType]s.
///
/// This is used by the [Deserializer].
class TypeDeserializer {
  /// Deserializes a [DartType] from an [ObjectDecoder].
  ///
  /// The class is called from the [Deserializer] when a [DartType] needs
  /// deserialization. The [ObjectDecoder] ensures that any [Element], other
  /// [DartType] that the deserialized [DartType] depends upon are available.
  static DartType deserialize(ObjectDecoder decoder) {
    TypeKind typeKind = decoder.getEnum(Key.KIND, TypeKind.values);
    switch (typeKind) {
      case TypeKind.INTERFACE:
        return new InterfaceType(decoder.getElement(Key.ELEMENT),
            decoder.getTypes(Key.TYPE_ARGUMENTS, isOptional: true));
      case TypeKind.FUNCTION:
        // TODO(johnniwinther): Support decoding of `type.element`.
        return new FunctionType.synthesized(
            decoder.getType(Key.RETURN_TYPE),
            decoder.getTypes(Key.PARAMETER_TYPES, isOptional: true),
            decoder.getTypes(Key.OPTIONAL_PARAMETER_TYPES, isOptional: true),
            decoder.getStrings(Key.NAMED_PARAMETERS, isOptional: true),
            decoder.getTypes(Key.NAMED_PARAMETER_TYPES, isOptional: true));
      case TypeKind.TYPE_VARIABLE:
        return new TypeVariableType(decoder.getElement(Key.ELEMENT));
      case TypeKind.TYPEDEF:
        return new TypedefType(decoder.getElement(Key.ELEMENT),
            decoder.getTypes(Key.TYPE_ARGUMENTS, isOptional: true));
      case TypeKind.STATEMENT:
      case TypeKind.MALFORMED_TYPE:
        throw new UnsupportedError("Unexpected type kind '${typeKind}.");
      case TypeKind.DYNAMIC:
        return const DynamicType();
      case TypeKind.VOID:
        return const VoidType();
    }
  }
}
