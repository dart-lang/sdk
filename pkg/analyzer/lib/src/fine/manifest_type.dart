// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';

final class ManifestDynamicType extends ManifestType {
  static final instance = ManifestDynamicType._();

  ManifestDynamicType._()
      : super(
          nullabilitySuffix: NullabilitySuffix.none,
        );

  @override
  bool match(MatchContext context, DartType type) {
    return type is DynamicTypeImpl;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.dynamic);
  }
}

sealed class ManifestFunctionFormalParameter {
  final bool isRequired;
  final ManifestType type;

  ManifestFunctionFormalParameter({
    required this.isRequired,
    required this.type,
  });

  factory ManifestFunctionFormalParameter.read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestFunctionFormalParameterKind.values);
    switch (kind) {
      case _ManifestFunctionFormalParameterKind.positional:
        return ManifestFunctionPositionalFormalParameter.read(reader);
      case _ManifestFunctionFormalParameterKind.named:
        return ManifestFunctionNamedFormalParameter.read(reader);
    }
  }

  void write(BufferedSink sink);
}

class ManifestFunctionNamedFormalParameter
    extends ManifestFunctionFormalParameter {
  final String name;

  ManifestFunctionNamedFormalParameter({
    required super.isRequired,
    required super.type,
    required this.name,
  });

  factory ManifestFunctionNamedFormalParameter.read(SummaryDataReader reader) {
    return ManifestFunctionNamedFormalParameter(
      isRequired: reader.readBool(),
      type: ManifestType.read(reader),
      name: reader.readStringUtf8(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestFunctionNamedFormalParameter &&
        other.name == name &&
        other.type == type;
  }

  bool match(MatchContext context, FormalParameterElementMixin element) {
    return element.isNamed &&
        element.isRequired == isRequired &&
        type.match(context, element.type) &&
        element.name3 == name;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestFunctionFormalParameterKind.named);
    sink.writeBool(isRequired);
    type.write(sink);
    sink.writeStringUtf8(name);
  }

  static ManifestFunctionNamedFormalParameter encode(
    EncodeContext context, {
    required bool isRequired,
    required DartType type,
    required String name,
  }) {
    return ManifestFunctionNamedFormalParameter(
      isRequired: isRequired,
      type: type.encode(context),
      name: name,
    );
  }
}

class ManifestFunctionPositionalFormalParameter
    extends ManifestFunctionFormalParameter {
  ManifestFunctionPositionalFormalParameter({
    required super.isRequired,
    required super.type,
  });

  factory ManifestFunctionPositionalFormalParameter.read(
    SummaryDataReader reader,
  ) {
    return ManifestFunctionPositionalFormalParameter(
      isRequired: reader.readBool(),
      type: ManifestType.read(reader),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestFunctionPositionalFormalParameter &&
        other.isRequired == isRequired &&
        other.type == type;
  }

  bool match(MatchContext context, FormalParameterElementMixin element) {
    return element.isPositional &&
        element.isRequired == isRequired &&
        type.match(context, element.type);
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestFunctionFormalParameterKind.positional);
    sink.writeBool(isRequired);
    type.write(sink);
  }

  static ManifestFunctionPositionalFormalParameter encode(
    EncodeContext context, {
    required bool isRequired,
    required DartType type,
  }) {
    return ManifestFunctionPositionalFormalParameter(
      isRequired: isRequired,
      type: type.encode(context),
    );
  }
}

final class ManifestFunctionType extends ManifestType {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType returnType;
  final List<ManifestFunctionPositionalFormalParameter> positional;
  final List<ManifestFunctionNamedFormalParameter> named;

  ManifestFunctionType({
    required this.typeParameters,
    required this.returnType,
    required this.positional,
    required this.named,
    required super.nullabilitySuffix,
  });

  factory ManifestFunctionType.read(SummaryDataReader reader) {
    return ManifestFunctionType(
      typeParameters: reader.readTypedList(() {
        return ManifestTypeParameter.read(reader);
      }),
      returnType: ManifestType.read(reader),
      positional: reader.readTypedList(() {
        return ManifestFunctionPositionalFormalParameter.read(reader);
      }),
      named: reader.readTypedList(() {
        return ManifestFunctionNamedFormalParameter.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestFunctionType &&
        const ListEquality<ManifestFunctionPositionalFormalParameter>()
            .equals(other.positional, positional) &&
        const ListEquality<ManifestFunctionNamedFormalParameter>()
            .equals(other.named, named) &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! FunctionTypeImpl) {
      return false;
    }

    return context.withTypeParameters(type.typeParameters, () {
      if (!ManifestTypeParameter.matchList(
          context, typeParameters, type.typeParameters)) {
        return false;
      }

      if (!returnType.match(context, type.returnType)) {
        return false;
      }

      var formalParameters = type.formalParameters;
      var index = 0;

      for (var i = 0; i < positional.length; i++) {
        if (i >= formalParameters.length) {
          return false;
        }
        var manifest = positional[i];
        var element = formalParameters[index++];
        if (!manifest.match(context, element)) {
          return false;
        }
      }

      for (var i = 0; i < named.length; i++) {
        if (i >= formalParameters.length) {
          return false;
        }
        var manifest = named[i];
        var element = formalParameters[index++];
        if (!manifest.match(context, element)) {
          return false;
        }
      }

      // Fail if there are more formal parameters than in the manifest.
      if (index != formalParameters.length) {
        return false;
      }

      if (type.nullabilitySuffix != nullabilitySuffix) {
        return false;
      }

      return true;
    });
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.function);
    sink.writeList(typeParameters, (e) => e.write(sink));
    returnType.write(sink);
    sink.writeList(positional, (e) => e.write(sink));
    sink.writeList(named, (e) => e.write(sink));
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestFunctionType encode(
    EncodeContext context,
    FunctionTypeImpl type,
  ) {
    return context.withTypeParameters(
      type.typeParameters,
      (typeParameters) {
        return ManifestFunctionType(
          typeParameters: typeParameters,
          returnType: type.returnType.encode(context),
          positional: type.positionalParameterTypes.indexed.map((pair) {
            return ManifestFunctionPositionalFormalParameter(
              isRequired: pair.$1 < type.requiredPositionalParameterCount,
              type: pair.$2.encode(context),
            );
          }).toFixedList(),
          named: type.sortedNamedParametersShared.map((element) {
            return ManifestFunctionNamedFormalParameter(
              isRequired: element.isRequired,
              type: element.type.encode(context),
              name: element.name3!,
            );
          }).toFixedList(),
          nullabilitySuffix: type.nullabilitySuffix,
        );
      },
    );
  }
}

final class ManifestInterfaceType extends ManifestType {
  final ManifestElement element;
  final List<ManifestType> arguments;

  ManifestInterfaceType({
    required this.element,
    required this.arguments,
    required super.nullabilitySuffix,
  });

  factory ManifestInterfaceType.read(SummaryDataReader reader) {
    return ManifestInterfaceType(
      element: ManifestElement.read(reader),
      arguments: reader.readTypedList(() {
        return ManifestType.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestInterfaceType &&
        other.element == element &&
        const ListEquality<ManifestType>().equals(other.arguments, arguments) &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    if (!element.match(context, type.element3)) {
      return false;
    }

    if (type.typeArguments.length != arguments.length) {
      return false;
    }
    for (var i = 0; i < arguments.length; i++) {
      if (!arguments[i].match(context, type.typeArguments[i])) {
        return false;
      }
    }

    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.interface);
    element.write(sink);
    sink.writeList(arguments, (argument) {
      argument.write(sink);
    });
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestInterfaceType encode(
    EncodeContext context,
    InterfaceType type,
  ) {
    return ManifestInterfaceType(
      element: ManifestElement.encode(context, type.element3),
      arguments: type.typeArguments.encode(context),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

final class ManifestInvalidType extends ManifestType {
  static final instance = ManifestInvalidType._();

  ManifestInvalidType._()
      : super(
          nullabilitySuffix: NullabilitySuffix.none,
        );

  @override
  bool match(MatchContext context, DartType type) {
    return type is InvalidTypeImpl;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.invalid);
  }
}

final class ManifestNeverType extends ManifestType {
  ManifestNeverType({
    required super.nullabilitySuffix,
  });

  factory ManifestNeverType.read(SummaryDataReader reader) {
    return ManifestNeverType(
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestNeverType &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! NeverTypeImpl) {
      return false;
    }
    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }
    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.never);
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestNeverType encode(
    EncodeContext context,
    NeverTypeImpl type,
  ) {
    return ManifestNeverType(
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

final class ManifestRecordType extends ManifestType {
  final List<ManifestType> positionalFields;
  final List<ManifestRecordTypeNamedField> namedFields;

  ManifestRecordType({
    required this.positionalFields,
    required this.namedFields,
    required super.nullabilitySuffix,
  });

  factory ManifestRecordType.read(SummaryDataReader reader) {
    return ManifestRecordType(
      positionalFields: reader.readTypedList(() {
        return ManifestType.read(reader);
      }),
      namedFields: reader.readTypedList(() {
        return ManifestRecordTypeNamedField.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestRecordType &&
        const ListEquality<ManifestType>()
            .equals(other.positionalFields, positionalFields) &&
        const ListEquality<ManifestRecordTypeNamedField>()
            .equals(other.namedFields, namedFields) &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! RecordType) {
      return false;
    }

    if (type.positionalFields.length != positionalFields.length) {
      return false;
    }
    for (var i = 0; i < positionalFields.length; i++) {
      var manifestType = positionalFields[i];
      var typeType = type.positionalFields[i].type;
      if (!manifestType.match(context, typeType)) {
        return false;
      }
    }

    if (type.namedFields.length != namedFields.length) {
      return false;
    }
    for (var i = 0; i < namedFields.length; i++) {
      var manifestField = namedFields[i];
      var typeField = type.namedFields[i];
      if (!manifestField.match(context, typeField)) {
        return false;
      }
    }

    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.record);
    sink.writeList(positionalFields, (e) => e.write(sink));
    sink.writeList(namedFields, (e) => e.write(sink));
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestRecordType encode(
    EncodeContext context,
    RecordTypeImpl type,
  ) {
    return ManifestRecordType(
      positionalFields: type.positionalFields.map((field) {
        return field.type;
      }).encode(context),
      namedFields: type.namedFields.map((field) {
        return ManifestRecordTypeNamedField.encode(context, field);
      }).toFixedList(),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

class ManifestRecordTypeNamedField {
  final String name;
  final ManifestType type;

  ManifestRecordTypeNamedField({
    required this.name,
    required this.type,
  });

  factory ManifestRecordTypeNamedField.read(SummaryDataReader reader) {
    return ManifestRecordTypeNamedField(
      name: reader.readStringUtf8(),
      type: ManifestType.read(reader),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestRecordTypeNamedField &&
        other.name == name &&
        other.type == type;
  }

  bool match(MatchContext context, RecordTypeNamedField field) {
    return field.name == name && type.match(context, field.type);
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    type.write(sink);
  }

  static ManifestRecordTypeNamedField encode(
    EncodeContext context,
    RecordTypeNamedField field,
  ) {
    return ManifestRecordTypeNamedField(
      name: field.name,
      type: field.type.encode(context),
    );
  }
}

sealed class ManifestType {
  final NullabilitySuffix nullabilitySuffix;

  ManifestType({
    required this.nullabilitySuffix,
  });

  bool match(MatchContext context, DartType type);

  void write(BufferedSink sink);

  static ManifestType read(SummaryDataReader reader) {
    var kind = reader.readEnum(_ManifestTypeKind.values);
    switch (kind) {
      case _ManifestTypeKind.dynamic:
        return ManifestDynamicType.instance;
      case _ManifestTypeKind.function:
        return ManifestFunctionType.read(reader);
      case _ManifestTypeKind.interface:
        return ManifestInterfaceType.read(reader);
      case _ManifestTypeKind.invalid:
        return ManifestInvalidType.instance;
      case _ManifestTypeKind.never:
        return ManifestNeverType.read(reader);
      case _ManifestTypeKind.record:
        return ManifestRecordType.read(reader);
      case _ManifestTypeKind.typeParameter:
        return ManifestTypeParameterType.read(reader);
      case _ManifestTypeKind.void_:
        return ManifestVoidType.instance;
    }
  }

  static ManifestType? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestType.read(reader));
  }
}

class ManifestTypeParameter {
  final ManifestType? bound;

  ManifestTypeParameter({
    required this.bound,
  });

  factory ManifestTypeParameter.read(
    SummaryDataReader reader,
  ) {
    return ManifestTypeParameter(
      bound: ManifestType.readOptional(reader),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestTypeParameter && other.bound == bound;
  }

  bool match(MatchContext context, TypeParameterElement2 element) {
    return bound.match(context, element.bound);
  }

  void write(BufferedSink sink) {
    sink.writeOptionalObject(bound, (bound) => bound.write(sink));
  }

  static bool matchList(
    MatchContext context,
    List<ManifestTypeParameter> manifests,
    List<TypeParameterElement2> elements,
  ) {
    if (manifests.length != elements.length) {
      return false;
    }

    for (var i = 0; i < manifests.length; i++) {
      var manifest = manifests[i];
      var element = elements[i];
      if (!manifest.match(context, element)) {
        return false;
      }
    }

    return true;
  }
}

final class ManifestTypeParameterType extends ManifestType {
  final int index;

  ManifestTypeParameterType({
    required this.index,
    required super.nullabilitySuffix,
  });

  factory ManifestTypeParameterType.read(SummaryDataReader reader) {
    return ManifestTypeParameterType(
      index: reader.readUInt30(),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManifestTypeParameterType &&
        other.index == index &&
        other.nullabilitySuffix == nullabilitySuffix;
  }

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! TypeParameterTypeImpl) {
      return false;
    }

    var elementIndex = context.indexOfTypeParameter(type.element3);
    if (elementIndex != index) {
      return false;
    }

    if (type.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }

    return true;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.typeParameter);
    sink.writeUInt30(index);
    sink.writeEnum(nullabilitySuffix);
  }

  static ManifestTypeParameterType encode(
    EncodeContext context,
    TypeParameterTypeImpl type,
  ) {
    return ManifestTypeParameterType(
      index: context.indexOfTypeParameter(type.element3),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }
}

final class ManifestVoidType extends ManifestType {
  static final instance = ManifestVoidType._();

  ManifestVoidType._()
      : super(
          nullabilitySuffix: NullabilitySuffix.none,
        );

  @override
  bool match(MatchContext context, DartType type) {
    return type is VoidTypeImpl;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.void_);
  }
}

enum _ManifestFunctionFormalParameterKind {
  positional,
  named,
}

enum _ManifestTypeKind {
  dynamic,
  function,
  interface,
  invalid,
  never,
  record,
  typeParameter,
  void_,
}

extension DartTypeExtension on DartType {
  ManifestType encode(EncodeContext context) {
    var type = this;
    switch (type) {
      case DynamicTypeImpl():
        return ManifestDynamicType.instance;
      case FunctionTypeImpl():
        return ManifestFunctionType.encode(context, type);
      case InterfaceTypeImpl():
        return ManifestInterfaceType.encode(context, type);
      case InvalidTypeImpl():
        return ManifestInvalidType.instance;
      case NeverTypeImpl():
        return ManifestNeverType.encode(context, type);
      case RecordTypeImpl():
        return ManifestRecordType.encode(context, type);
      case TypeParameterTypeImpl():
        return ManifestTypeParameterType.encode(context, type);
      case VoidTypeImpl():
        return ManifestVoidType.instance;
      default:
        throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }
}

extension IterableOfDartTypeExtension on Iterable<DartType> {
  List<ManifestType> encode(EncodeContext context) {
    return map((type) => type.encode(context)).toFixedList();
  }
}

extension ListOfManifestTypeExtension on List<ManifestType> {
  bool match(MatchContext context, List<DartType> types) {
    if (types.length != length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!this[i].match(context, types[i])) {
        return false;
      }
    }
    return true;
  }
}

extension ManifestTypeOrNullExtension on ManifestType? {
  bool match(MatchContext context, DartType? type) {
    var self = this;
    if (self == null || type == null) {
      return self == null && type == null;
    }
    return self.match(context, type);
  }
}
