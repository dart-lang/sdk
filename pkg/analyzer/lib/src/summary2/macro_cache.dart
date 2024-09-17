// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/macro_declarations.dart';
import 'package:analyzer/src/summary2/macro_type_location.dart';
import 'package:analyzer/src/summary2/macro_type_location_storage.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:macros/macros.dart' as macro;
import 'package:macros/src/executor.dart' as macro;
import 'package:macros/src/executor/introspection_impls.dart' as macro;
import 'package:macros/src/executor/response_impls.dart' as macro;

macro.MacroExecutionResult readMacroExecutionResult({
  required DeclarationBuilder declarationBuilder,
  required Uint8List bytes,
}) {
  return _MacroResultReader(
    declarationBuilder: declarationBuilder,
    reader: SummaryDataReader(bytes),
  ).read();
}

Uint8List writeMacroExecutionResult(macro.MacroExecutionResult object) {
  var byteSink = ByteSink();
  var sink = BufferedSink(byteSink);

  _MacroResultWriter(
    sink: sink,
  ).write(object);

  return sink.flushAndTake();
}

class MacroCacheBundle {
  final List<MacroCacheLibrary> libraries;

  MacroCacheBundle({
    required this.libraries,
  });

  factory MacroCacheBundle.fromBytes(
    LibraryCycle cycle,
    Uint8List bytes,
  ) {
    return MacroCacheBundle.read(
      cycle,
      SummaryDataReader(bytes),
    );
  }

  factory MacroCacheBundle.read(
    LibraryCycle cycle,
    SummaryDataReader reader,
  ) {
    return MacroCacheBundle(
      libraries: reader.readTypedList(
        () => MacroCacheLibrary.read(cycle, reader),
      ),
    );
  }

  Uint8List toBytes() {
    var byteSink = ByteSink();
    var sink = BufferedSink(byteSink);
    write(sink);
    return sink.flushAndTake();
  }

  void write(BufferedSink sink) {
    sink.writeList(libraries, (library) {
      library.write(sink);
    });
  }
}

class MacroCacheLibrary {
  /// The file view of the library.
  final LibraryFileKind kind;

  /// The combination of API signatures of all library files.
  final Uint8List apiSignature;

  /// Whether any macro of the library introspected anything.
  final bool hasAnyIntrospection;

  final String code;

  MacroCacheLibrary({
    required this.kind,
    required this.apiSignature,
    required this.hasAnyIntrospection,
    required this.code,
  });

  factory MacroCacheLibrary.read(
    LibraryCycle cycle,
    SummaryDataReader reader,
  ) {
    var path = reader.readStringUtf8();
    return MacroCacheLibrary(
      // This is safe because the key of the bundle depends on paths.
      kind: cycle.libraries.firstWhere((e) => e.file.path == path),
      apiSignature: reader.readUint8List(),
      hasAnyIntrospection: reader.readBool(),
      code: reader.readStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(kind.file.path);
    sink.writeUint8List(apiSignature);
    sink.writeBool(hasAnyIntrospection);
    sink.writeStringUtf8(code);
  }
}

enum _ElementLocationKind {
  dynamic,
  formalParameter,
  reference,
  typeParameter,
}

enum _IdentifierKind {
  declared,
  element,
  void_,
}

enum _MacroCodeKind {
  comment,
  declaration,
  expression,
  functionBody,
  functionTypeAnnotation,
  namedTypeAnnotation,
  nullableTypeAnnotation,
  omittedTypeAnnotation,
  parameter,
  raw,
  rawTypeAnnotation,
  recordField,
  recordTypeAnnotation,
  typeParameter,
}

enum _MacroCodePartKind {
  code,
  identifier,
  string,
}

class _MacroResultReader {
  final DeclarationBuilder declarationBuilder;
  final SummaryDataReader reader;

  _MacroResultReader({
    required this.declarationBuilder,
    required this.reader,
  });

  macro.MacroExecutionResult read() {
    return macro.MacroExecutionResultImpl(
      diagnostics: [],
      enumValueAugmentations: reader.readMap(
        readKey: _readIdentifier,
        readValue: _readCodeList,
      ),
      extendsTypeAugmentations: reader.readMap(
        readKey: _readIdentifier,
        readValue: _readNamedTypeAnnotationCode,
      ),
      interfaceAugmentations: reader.readMap(
        readKey: _readIdentifier,
        readValue: _readTypeAnnotationCodeList,
      ),
      libraryAugmentations: _readCodeList(),
      mixinAugmentations: reader.readMap(
        readKey: _readIdentifier,
        readValue: _readTypeAnnotationCodeList,
      ),
      newTypeNames: reader.readStringUtf8List(),
      typeAugmentations: reader.readMap(
        readKey: _readIdentifier,
        readValue: _readCodeList,
      ),
    );
  }

  T _readCode<T extends macro.Code>() {
    return _readCodeSome() as T;
  }

  List<T> _readCodeList<T extends macro.Code>() {
    return reader.readTypedList(_readCode);
  }

  Object _readCodePart() {
    var kind = reader.readEnum(_MacroCodePartKind.values);
    switch (kind) {
      case _MacroCodePartKind.code:
        return _readCode();
      case _MacroCodePartKind.identifier:
        return _readIdentifier();
      case _MacroCodePartKind.string:
        return reader.readStringUtf8();
    }
  }

  macro.Code _readCodeSome() {
    var codeKind = reader.readEnum(_MacroCodeKind.values);
    switch (codeKind) {
      case _MacroCodeKind.comment:
        var parts = reader.readTypedList(_readCodePart);
        return macro.CommentCode.fromParts(parts);
      case _MacroCodeKind.declaration:
        var parts = reader.readTypedList(_readCodePart);
        return macro.DeclarationCode.fromParts(parts);
      case _MacroCodeKind.expression:
        var parts = reader.readTypedList(_readCodePart);
        return macro.ExpressionCode.fromParts(parts);
      case _MacroCodeKind.functionBody:
        var parts = reader.readTypedList(_readCodePart);
        return macro.FunctionBodyCode.fromParts(parts);
      case _MacroCodeKind.functionTypeAnnotation:
        return macro.FunctionTypeAnnotationCode(
          namedParameters: _readCodeList(),
          optionalPositionalParameters: _readCodeList(),
          positionalParameters: _readCodeList(),
          returnType: _readOptionalCode(),
          typeParameters: _readCodeList(),
        );
      case _MacroCodeKind.namedTypeAnnotation:
        return macro.NamedTypeAnnotationCode(
          name: _readIdentifier(),
          typeArguments: _readCodeList(),
        );
      case _MacroCodeKind.nullableTypeAnnotation:
        var underlyingType = _readTypeAnnotationCode();
        return macro.NullableTypeAnnotationCode(underlyingType);
      case _MacroCodeKind.omittedTypeAnnotation:
        var typeAnnotation = _readOmittedTypeAnnotation();
        return macro.OmittedTypeAnnotationCode(typeAnnotation);
      case _MacroCodeKind.parameter:
        return macro.ParameterCode(
          defaultValue: _readOptionalCode(),
          keywords: reader.readStringUtf8List(),
          name: reader.readOptionalStringUtf8(),
          style: reader.readEnum(macro.ParameterStyle.values),
          type: _readOptionalCode(),
        );
      case _MacroCodeKind.rawTypeAnnotation:
        var parts = reader.readTypedList(_readCodePart);
        return macro.RawTypeAnnotationCode.fromParts(parts);
      case _MacroCodeKind.raw:
        var parts = reader.readTypedList(_readCodePart);
        return macro.RawCode.fromParts(parts);
      case _MacroCodeKind.recordField:
        return macro.RecordFieldCode(
          name: reader.readOptionalStringUtf8(),
          type: _readTypeAnnotationCode(),
        );
      case _MacroCodeKind.recordTypeAnnotation:
        return macro.RecordTypeAnnotationCode(
          namedFields: _readCodeList(),
          positionalFields: _readCodeList(),
        );
      case _MacroCodeKind.typeParameter:
        return macro.TypeParameterCode(
          bound: _readOptionalCode(),
          name: reader.readStringUtf8(),
        );
    }
  }

  Element _readElement() {
    var kind = reader.readEnum(_ElementLocationKind.values);
    switch (kind) {
      case _ElementLocationKind.dynamic:
        return DynamicElementImpl.instance;
      case _ElementLocationKind.formalParameter:
        var executable = _readElement();
        executable as ExecutableElement;
        var index = reader.readUInt30();
        return executable.parameters[index];
      case _ElementLocationKind.reference:
        var reference = _readReference();
        return reference.element!;
      case _ElementLocationKind.typeParameter:
        var executable = _readElement();
        executable as ExecutableElement;
        var index = reader.readUInt30();
        return executable.typeParameters[index];
    }
  }

  macro.IdentifierImpl _readIdentifier() {
    var kind = reader.readEnum(_IdentifierKind.values);
    switch (kind) {
      case _IdentifierKind.declared:
        var element = _readElement();
        return declarationBuilder.identifierDeclared(
          name: element.name!,
          element: element,
        );
      case _IdentifierKind.element:
        var element = _readElement();
        return declarationBuilder.identifierFromElement(
          name: element.name!,
          element: element,
        );
      case _IdentifierKind.void_:
        return declarationBuilder.voidIdentifier;
    }
  }

  macro.NamedTypeAnnotationCode _readNamedTypeAnnotationCode() {
    return _readCode() as macro.NamedTypeAnnotationCode;
  }

  macro.OmittedTypeAnnotation _readOmittedTypeAnnotation() {
    var kind = reader.readEnum(_OmittedTypeAnnotationKind.values);
    switch (kind) {
      case _OmittedTypeAnnotationKind.dynamic:
        var location = _readTypeAnnotationLocation();
        return OmittedTypeAnnotationDynamic(location);
      case _OmittedTypeAnnotationKind.returnType:
        var location = _readTypeAnnotationLocation();
        var element = location.element as ExecutableElement;
        return OmittedTypeAnnotationFunctionReturnType(element, location);
      case _OmittedTypeAnnotationKind.variable:
        var location = _readTypeAnnotationLocation();
        var element = location.element as VariableElement;
        return OmittedTypeAnnotationVariable(element, location);
    }
  }

  T? _readOptionalCode<T extends macro.Code>() {
    return reader.readOptionalObject((_) {
      return _readCode();
    });
  }

  Reference _readReference() {
    var reference = declarationBuilder.rootReference;
    var components = reader.readStringUtf8List();
    for (var component in components) {
      reference = reference[component]!;
    }
    return reference;
  }

  macro.TypeAnnotationCode _readTypeAnnotationCode() {
    return _readCode() as macro.TypeAnnotationCode;
  }

  List<macro.TypeAnnotationCode> _readTypeAnnotationCodeList() {
    return reader.readTypedList(_readTypeAnnotationCode);
  }

  TypeAnnotationLocation _readTypeAnnotationLocation() {
    return TypeAnnotationLocationReader(
      reader: reader,
      readElement: _readElement,
    ).read();
  }
}

class _MacroResultWriter {
  final BufferedSink sink;

  _MacroResultWriter({
    required this.sink,
  });

  void write(macro.MacroExecutionResult object) {
    // TODO(scheglov): diagnostics
    // TODO(scheglov): exception

    sink.writeMap(
      object.enumValueAugmentations,
      writeKey: _writeIdentifier,
      writeValue: _writeCodeIterable,
    );

    sink.writeMap(
      object.extendsTypeAugmentations,
      writeKey: _writeIdentifier,
      writeValue: _writeCode,
    );

    sink.writeMap(
      object.interfaceAugmentations,
      writeKey: _writeIdentifier,
      writeValue: _writeCodeIterable,
    );

    sink.writeIterable(object.libraryAugmentations, _writeCode);

    sink.writeMap(
      object.mixinAugmentations,
      writeKey: _writeIdentifier,
      writeValue: _writeCodeIterable,
    );

    sink.writeStringUtf8Iterable(object.newTypeNames);

    sink.writeMap(
      object.typeAugmentations,
      writeKey: _writeIdentifier,
      writeValue: _writeCodeIterable,
    );
  }

  void _writeCode(macro.Code object) {
    switch (object) {
      case macro.CommentCode():
        sink.writeEnum(_MacroCodeKind.comment);
        sink.writeList(object.parts, _writeCodePart);
      case macro.DeclarationCode():
        sink.writeEnum(_MacroCodeKind.declaration);
        sink.writeList(object.parts, _writeCodePart);
      case macro.FunctionBodyCode():
        sink.writeEnum(_MacroCodeKind.functionBody);
        sink.writeList(object.parts, _writeCodePart);
      case macro.FunctionTypeAnnotationCode():
        sink.writeEnum(_MacroCodeKind.functionTypeAnnotation);
        _writeCodeList(object.namedParameters);
        _writeCodeList(object.optionalPositionalParameters);
        _writeCodeList(object.positionalParameters);
        _writeOptionalCode(object.returnType);
        _writeCodeList(object.typeParameters);
      case macro.NamedTypeAnnotationCode():
        sink.writeEnum(_MacroCodeKind.namedTypeAnnotation);
        _writeIdentifier(object.name);
        _writeCodeList(object.typeArguments);
      case macro.ExpressionCode():
        sink.writeEnum(_MacroCodeKind.expression);
        sink.writeList(object.parts, _writeCodePart);
      case macro.NullableTypeAnnotationCode():
        sink.writeEnum(_MacroCodeKind.nullableTypeAnnotation);
        _writeCode(object.underlyingType);
      case macro.OmittedTypeAnnotationCode():
        sink.writeEnum(_MacroCodeKind.omittedTypeAnnotation);
        _writeOmittedTypeAnnotation(object.typeAnnotation);
      case macro.ParameterCode():
        sink.writeEnum(_MacroCodeKind.parameter);
        _writeOptionalCode(object.defaultValue);
        sink.writeStringUtf8Iterable(object.keywords);
        sink.writeOptionalStringUtf8(object.name);
        sink.writeEnum(object.style);
        _writeOptionalCode(object.type);
      case macro.RawTypeAnnotationCode():
        sink.writeEnum(_MacroCodeKind.rawTypeAnnotation);
        sink.writeList(object.parts, _writeCodePart);
      case macro.RawCode():
        sink.writeEnum(_MacroCodeKind.raw);
        sink.writeList(object.parts, _writeCodePart);
      case macro.RecordFieldCode():
        sink.writeEnum(_MacroCodeKind.recordField);
        sink.writeOptionalStringUtf8(object.name);
        _writeCode(object.type);
      case macro.RecordTypeAnnotationCode():
        sink.writeEnum(_MacroCodeKind.recordTypeAnnotation);
        _writeCodeList(object.namedFields);
        _writeCodeList(object.positionalFields);
      case macro.TypeParameterCode():
        sink.writeEnum(_MacroCodeKind.typeParameter);
        _writeOptionalCode(object.bound);
        sink.writeStringUtf8(object.name);
    }
  }

  void _writeCodeIterable(Iterable<macro.Code> objects) {
    sink.writeIterable(objects, _writeCode);
  }

  void _writeCodeList(List<macro.Code> objects) {
    sink.writeList(objects, _writeCode);
  }

  void _writeCodePart(Object object) {
    switch (object) {
      case macro.Code():
        sink.writeEnum(_MacroCodePartKind.code);
        _writeCode(object);
      case macro.Identifier():
        sink.writeEnum(_MacroCodePartKind.identifier);
        _writeIdentifier(object);
      case String():
        sink.writeEnum(_MacroCodePartKind.string);
        sink.writeStringUtf8(object);
      default:
        throw UnimplementedError('${object.runtimeType}');
    }
  }

  void _writeElement(Element element) {
    switch (element) {
      case DynamicElementImpl():
        sink.writeEnum(_ElementLocationKind.dynamic);
      case ParameterElement():
        sink.writeEnum(_ElementLocationKind.formalParameter);
        var executable = element.enclosingElement3 as ExecutableElement;
        var index = executable.parameters.indexOf(element);
        _writeElement(executable);
        sink.writeUInt30(index);
      case TypeParameterElement():
        sink.writeEnum(_ElementLocationKind.typeParameter);
        var executable = element.enclosingElement3 as ExecutableElement;
        var index = executable.typeParameters.indexOf(element);
        _writeElement(executable);
        sink.writeUInt30(index);
      default:
        sink.writeEnum(_ElementLocationKind.reference);
        var reference = (element as ElementImpl).reference;
        _writeReference(reference!);
    }
  }

  void _writeIdentifier(macro.Identifier object) {
    switch (object) {
      case IdentifierImplDeclared():
        sink.writeEnum(_IdentifierKind.declared);
        _writeElement(object.element);
      case IdentifierImplVoid():
        sink.writeEnum(_IdentifierKind.void_);
      case IdentifierImpl():
        sink.writeEnum(_IdentifierKind.element);
        _writeElement(object.element!);
      default:
        throw UnimplementedError('${object.runtimeType}');
    }
  }

  void _writeOmittedTypeAnnotation(macro.OmittedTypeAnnotation object) {
    object as OmittedTypeAnnotation;
    switch (object) {
      case OmittedTypeAnnotationDynamic():
        sink.writeEnum(_OmittedTypeAnnotationKind.dynamic);
        _writeTypeAnnotationLocation(object.location);
      case OmittedTypeAnnotationFunctionReturnType():
        sink.writeEnum(_OmittedTypeAnnotationKind.returnType);
        _writeTypeAnnotationLocation(object.location);
      case OmittedTypeAnnotationVariable():
        sink.writeEnum(_OmittedTypeAnnotationKind.variable);
        _writeTypeAnnotationLocation(object.location);
    }
  }

  void _writeOptionalCode(macro.Code? object) {
    sink.writeOptionalObject(object, _writeCode);
  }

  void _writeReference(Reference reference) {
    var components = <String>[];
    while (!reference.isRoot) {
      components.add(reference.name);
      reference = reference.parent!;
    }
    sink.writeStringUtf8Iterable(components.reversed);
  }

  void _writeTypeAnnotationLocation(TypeAnnotationLocation location) {
    TypeAnnotationLocationWriter(
      sink: sink,
      writeElement: _writeElement,
    ).write(location);
  }
}

enum _OmittedTypeAnnotationKind {
  dynamic,
  returnType,
  variable,
}
