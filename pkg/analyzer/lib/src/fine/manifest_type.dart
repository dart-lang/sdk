// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart'
    as shared
    show Variance;
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/fine/manifest_ast.dart';
import 'package:analyzer/src/fine/manifest_context.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

final class ManifestDynamicType extends ManifestType {
  static final instance = ManifestDynamicType._();

  ManifestDynamicType._() : super(nullabilitySuffix: NullabilitySuffix.none);

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
  final ManifestMetadata metadata;
  final bool isRequired;
  final bool isCovariant;
  final bool isInitializingFormal;
  final bool isSuperFormal;
  final ManifestType type;
  final ManifestNode? defaultValue;

  ManifestFunctionFormalParameter({
    required this.metadata,
    required this.isRequired,
    required this.isCovariant,
    required this.isInitializingFormal,
    required this.isSuperFormal,
    required this.type,
    required this.defaultValue,
  });

  bool match(MatchContext context, InternalFormalParameterElement element) {
    return metadata.match(context, element.metadata) &&
        element.isRequired == isRequired &&
        element.isCovariant == isCovariant &&
        element.isInitializingFormal == isInitializingFormal &&
        element.isSuperFormal == isSuperFormal &&
        type.match(context, element.type) &&
        defaultValue.match(context, element.constantInitializer);
  }

  void write(BufferedSink sink) {
    metadata.write(sink);
    sink.writeBool(isRequired);
    sink.writeBool(isCovariant);
    sink.writeBool(isInitializingFormal);
    sink.writeBool(isSuperFormal);
    type.write(sink);
    defaultValue.writeOptional(sink);
  }
}

class ManifestFunctionNamedFormalParameter
    extends ManifestFunctionFormalParameter {
  final String name;

  factory ManifestFunctionNamedFormalParameter.encode(
    EncodeContext context,
    InternalFormalParameterElement element,
  ) {
    return ManifestFunctionNamedFormalParameter._(
      metadata: ManifestMetadata.encode(context, element.metadata),
      isRequired: element.isRequired,
      isCovariant: element.isCovariant,
      isInitializingFormal: element.isInitializingFormal,
      isSuperFormal: element.isSuperFormal,
      type: element.type.encode(context),
      defaultValue: element.constantInitializer?.encode(context),
      name: element.name ?? '',
    );
  }

  factory ManifestFunctionNamedFormalParameter.read(SummaryDataReader reader) {
    return ManifestFunctionNamedFormalParameter._(
      metadata: ManifestMetadata.read(reader),
      isRequired: reader.readBool(),
      isCovariant: reader.readBool(),
      isInitializingFormal: reader.readBool(),
      isSuperFormal: reader.readBool(),
      type: ManifestType.read(reader),
      defaultValue: ManifestNode.readOptional(reader),
      name: reader.readStringUtf8(),
    );
  }

  ManifestFunctionNamedFormalParameter._({
    required super.metadata,
    required super.isRequired,
    required super.isCovariant,
    required super.isInitializingFormal,
    required super.isSuperFormal,
    required super.type,
    required super.defaultValue,
    required this.name,
  });

  @override
  bool match(MatchContext context, InternalFormalParameterElement element) {
    return element.isNamed &&
        super.match(context, element) &&
        element.name == name;
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeStringUtf8(name);
  }
}

class ManifestFunctionPositionalFormalParameter
    extends ManifestFunctionFormalParameter {
  factory ManifestFunctionPositionalFormalParameter.encode(
    EncodeContext context,
    InternalFormalParameterElement element,
  ) {
    return ManifestFunctionPositionalFormalParameter._(
      metadata: ManifestMetadata.encode(context, element.metadata),
      isRequired: element.isRequiredPositional,
      isCovariant: element.isCovariant,
      isInitializingFormal: element.isInitializingFormal,
      isSuperFormal: element.isSuperFormal,
      type: element.type.encode(context),
      defaultValue: element.constantInitializer?.encode(context),
    );
  }

  factory ManifestFunctionPositionalFormalParameter.read(
    SummaryDataReader reader,
  ) {
    return ManifestFunctionPositionalFormalParameter._(
      metadata: ManifestMetadata.read(reader),
      isRequired: reader.readBool(),
      isCovariant: reader.readBool(),
      isInitializingFormal: reader.readBool(),
      isSuperFormal: reader.readBool(),
      type: ManifestType.read(reader),
      defaultValue: ManifestNode.readOptional(reader),
    );
  }

  ManifestFunctionPositionalFormalParameter._({
    required super.metadata,
    required super.isRequired,
    required super.isCovariant,
    required super.isInitializingFormal,
    required super.isSuperFormal,
    required super.type,
    required super.defaultValue,
  });

  @override
  bool match(MatchContext context, InternalFormalParameterElement element) {
    return element.isPositional && super.match(context, element);
  }
}

final class ManifestFunctionType extends ManifestType {
  final List<ManifestTypeParameter> typeParameters;
  final ManifestType returnType;
  final List<ManifestFunctionPositionalFormalParameter> positional;
  final List<ManifestFunctionNamedFormalParameter> named;

  factory ManifestFunctionType.encode(
    EncodeContext context,
    FunctionTypeImpl type,
  ) {
    return context.withTypeParameters(type.typeParameters, (typeParameters) {
      return ManifestFunctionType._(
        typeParameters: typeParameters,
        returnType: type.returnType.encode(context),
        positional: type.formalParameters
            .where((element) => element.isPositional)
            .map((element) {
              return ManifestFunctionPositionalFormalParameter.encode(
                context,
                element,
              );
            })
            .toFixedList(),
        named: type.sortedNamedParametersShared.map((element) {
          return ManifestFunctionNamedFormalParameter.encode(context, element);
        }).toFixedList(),
        nullabilitySuffix: type.nullabilitySuffix,
      );
    });
  }

  factory ManifestFunctionType.read(SummaryDataReader reader) {
    return ManifestFunctionType._(
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

  ManifestFunctionType._({
    required this.typeParameters,
    required this.returnType,
    required this.positional,
    required this.named,
    required super.nullabilitySuffix,
  });

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! FunctionTypeImpl) {
      return false;
    }

    return context.withTypeParameters(type.typeParameters, () {
      if (!typeParameters.match(context, type.typeParameters)) {
        return false;
      }

      if (!returnType.match(context, type.returnType)) {
        return false;
      }

      var formalParameters = type.formalParameters;
      var index = 0;

      for (var i = 0; i < positional.length; i++) {
        if (index >= formalParameters.length) {
          return false;
        }
        var manifest = positional[i];
        var element = formalParameters[index++];
        if (!manifest.match(context, element)) {
          return false;
        }
      }

      for (var i = 0; i < named.length; i++) {
        if (index >= formalParameters.length) {
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
    writeNoTag(sink);
  }

  void writeNoTag(BufferedSink sink) {
    sink.writeList(typeParameters, (e) => e.write(sink));
    returnType.write(sink);
    sink.writeList(positional, (e) => e.write(sink));
    sink.writeList(named, (e) => e.write(sink));
    sink.writeEnum(nullabilitySuffix);
  }
}

final class ManifestInterfaceType extends ManifestType {
  final ManifestElement element;
  final List<ManifestType> arguments;

  factory ManifestInterfaceType.encode(
    EncodeContext context,
    InterfaceType type,
  ) {
    return ManifestInterfaceType._(
      element: ManifestElement.encode(context, type.element),
      arguments: type.typeArguments.encode(context),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  factory ManifestInterfaceType.read(SummaryDataReader reader) {
    return ManifestInterfaceType._(
      element: ManifestElement.read(reader),
      arguments: reader.readTypedList(() {
        return ManifestType.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  ManifestInterfaceType._({
    required this.element,
    required this.arguments,
    required super.nullabilitySuffix,
  });

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    if (!element.match(context, type.element)) {
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
}

final class ManifestInvalidType extends ManifestType {
  static final instance = ManifestInvalidType._();

  ManifestInvalidType._() : super(nullabilitySuffix: NullabilitySuffix.none);

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
  factory ManifestNeverType.encode(NeverTypeImpl type) {
    return ManifestNeverType._(nullabilitySuffix: type.nullabilitySuffix);
  }

  factory ManifestNeverType.read(SummaryDataReader reader) {
    return ManifestNeverType._(
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  ManifestNeverType._({required super.nullabilitySuffix});

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
}

final class ManifestRecordType extends ManifestType {
  final List<ManifestType> positionalFields;
  final List<ManifestRecordTypeNamedField> namedFields;

  factory ManifestRecordType.encode(
    EncodeContext context,
    RecordTypeImpl type,
  ) {
    return ManifestRecordType._(
      positionalFields: type.positionalFields
          .map((field) {
            return field.type;
          })
          .encode(context),
      namedFields: type.namedFields.map((field) {
        return ManifestRecordTypeNamedField.encode(context, field);
      }).toFixedList(),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  factory ManifestRecordType.read(SummaryDataReader reader) {
    return ManifestRecordType._(
      positionalFields: reader.readTypedList(() {
        return ManifestType.read(reader);
      }),
      namedFields: reader.readTypedList(() {
        return ManifestRecordTypeNamedField.read(reader);
      }),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  ManifestRecordType._({
    required this.positionalFields,
    required this.namedFields,
    required super.nullabilitySuffix,
  });

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
}

class ManifestRecordTypeNamedField {
  final String name;
  final ManifestType type;

  factory ManifestRecordTypeNamedField.encode(
    EncodeContext context,
    RecordTypeNamedField field,
  ) {
    return ManifestRecordTypeNamedField._(
      name: field.name,
      type: field.type.encode(context),
    );
  }

  factory ManifestRecordTypeNamedField.read(SummaryDataReader reader) {
    return ManifestRecordTypeNamedField._(
      name: reader.readStringUtf8(),
      type: ManifestType.read(reader),
    );
  }

  ManifestRecordTypeNamedField._({required this.name, required this.type});

  bool match(MatchContext context, RecordTypeNamedField field) {
    return field.name == name && type.match(context, field.type);
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    type.write(sink);
  }
}

sealed class ManifestType {
  final NullabilitySuffix nullabilitySuffix;

  ManifestType({required this.nullabilitySuffix});

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

  static List<ManifestType> readList(SummaryDataReader reader) {
    return reader.readTypedList(() => ManifestType.read(reader));
  }

  static ManifestType? readOptional(SummaryDataReader reader) {
    return reader.readOptionalObject(() => ManifestType.read(reader));
  }
}

class ManifestTypeParameter {
  final shared.Variance variance;
  final ManifestType? bound;

  factory ManifestTypeParameter.encode(
    EncodeContext context,
    TypeParameterElementImpl element,
  ) {
    return ManifestTypeParameter._(
      variance: element.variance,
      bound: element.bound?.encode(context),
    );
  }

  factory ManifestTypeParameter.read(SummaryDataReader reader) {
    return ManifestTypeParameter._(
      variance: reader.readEnum(shared.Variance.values),
      bound: ManifestType.readOptional(reader),
    );
  }

  ManifestTypeParameter._({required this.variance, required this.bound});

  bool match(MatchContext context, TypeParameterElementImpl element) {
    return element.variance == variance && bound.match(context, element.bound);
  }

  void write(BufferedSink sink) {
    sink.writeEnum(variance);
    bound.writeOptional(sink);
  }

  static List<ManifestTypeParameter> readList(SummaryDataReader reader) {
    return reader.readTypedList(() => ManifestTypeParameter.read(reader));
  }
}

final class ManifestTypeParameterType extends ManifestType {
  final int index;

  factory ManifestTypeParameterType.encode(
    EncodeContext context,
    TypeParameterTypeImpl type,
  ) {
    return ManifestTypeParameterType._(
      index: context.indexOfTypeParameter(type.element),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  factory ManifestTypeParameterType.read(SummaryDataReader reader) {
    return ManifestTypeParameterType._(
      index: reader.readUint30(),
      nullabilitySuffix: reader.readEnum(NullabilitySuffix.values),
    );
  }

  ManifestTypeParameterType._({
    required this.index,
    required super.nullabilitySuffix,
  });

  @override
  bool match(MatchContext context, DartType type) {
    if (type is! TypeParameterTypeImpl) {
      return false;
    }

    var elementIndex = context.indexOfTypeParameter(type.element);
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
    sink.writeUint30(index);
    sink.writeEnum(nullabilitySuffix);
  }
}

final class ManifestVoidType extends ManifestType {
  static final instance = ManifestVoidType._();

  ManifestVoidType._() : super(nullabilitySuffix: NullabilitySuffix.none);

  @override
  bool match(MatchContext context, DartType type) {
    return type is VoidTypeImpl;
  }

  @override
  void write(BufferedSink sink) {
    sink.writeEnum(_ManifestTypeKind.void_);
  }
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
        return ManifestNeverType.encode(type);
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

extension FunctionTypeImplExtension on FunctionTypeImpl {
  ManifestFunctionType encode(EncodeContext context) {
    return ManifestFunctionType.encode(context, this);
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

  void writeList(BufferedSink sink) {
    sink.writeList(this, (x) => x.write(sink));
  }
}

extension ListOfManifestTypeParameterExtension on List<ManifestTypeParameter> {
  bool match(MatchContext context, List<TypeParameterElementImpl> elements) {
    if (elements.length != length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!this[i].match(context, elements[i])) {
        return false;
      }
    }
    return true;
  }

  void write(BufferedSink sink) {
    sink.writeList(this, (x) => x.write(sink));
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

  void writeOptional(BufferedSink sink) {
    sink.writeOptionalObject(this, (x) => x.write(sink));
  }
}

extension _AstNodeExtension on AstNode {
  ManifestNode encode(EncodeContext context) {
    return ManifestNode.encode(context, this);
  }
}
