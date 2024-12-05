// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:analyzer/src/summary2/macro_type_location.dart';

class TypeAnnotationLocationReader {
  final SummaryDataReader reader;
  final Element? Function() readElement;

  TypeAnnotationLocationReader({
    required this.reader,
    required this.readElement,
  });

  TypeAnnotationLocation read() {
    var kind = reader.readEnum(_LocationKind.values);
    switch (kind) {
      case _LocationKind.aliasedType:
        var parent = read();
        return AliasedTypeLocation(parent);
      case _LocationKind.element:
        var element = readElement()!;
        return ElementTypeLocation(element);
      case _LocationKind.extendsClause:
        var parent = read();
        return ExtendsClauseTypeLocation(parent);
      case _LocationKind.formalParameter:
        return FormalParameterTypeLocation(
          read(),
          reader.readUInt30(),
        );
      case _LocationKind.listIndex:
        return ListIndexTypeLocation(
          read(),
          reader.readUInt30(),
        );
      case _LocationKind.recordNamedField:
        return RecordNamedFieldTypeLocation(
          read(),
          reader.readUInt30(),
        );
      case _LocationKind.recordPositionalField:
        return RecordPositionalFieldTypeLocation(
          read(),
          reader.readUInt30(),
        );
      case _LocationKind.returnType:
        var parent = read();
        return ReturnTypeLocation(parent);
      case _LocationKind.variableType:
        var parent = read();
        return VariableTypeLocation(parent);
    }
  }
}

class TypeAnnotationLocationWriter {
  final BufferedSink sink;
  final void Function(Element element) writeElement;

  TypeAnnotationLocationWriter({
    required this.sink,
    required this.writeElement,
  });

  void write(TypeAnnotationLocation location) {
    switch (location) {
      case AliasedTypeLocation():
        sink.writeEnum(_LocationKind.aliasedType);
        write(location.parent);
      case ElementTypeLocation():
        sink.writeEnum(_LocationKind.element);
        writeElement(location.element);
      case ExtendsClauseTypeLocation():
        sink.writeEnum(_LocationKind.extendsClause);
        write(location.parent);
      case FormalParameterTypeLocation():
        sink.writeEnum(_LocationKind.formalParameter);
        write(location.parent);
        sink.writeUInt30(location.index);
      case ListIndexTypeLocation():
        sink.writeEnum(_LocationKind.listIndex);
        write(location.parent);
        sink.writeUInt30(location.index);
      case RecordNamedFieldTypeLocation():
        sink.writeEnum(_LocationKind.recordNamedField);
        write(location.parent);
        sink.writeUInt30(location.index);
      case RecordPositionalFieldTypeLocation():
        sink.writeEnum(_LocationKind.recordPositionalField);
        write(location.parent);
        sink.writeUInt30(location.index);
      case ReturnTypeLocation():
        sink.writeEnum(_LocationKind.returnType);
        write(location.parent);
      case VariableTypeLocation():
        sink.writeEnum(_LocationKind.variableType);
        write(location.parent);
      default:
        // TODO(scheglov): Handle this case.
        throw UnimplementedError('${location.runtimeType}');
    }
  }
}

enum _LocationKind {
  aliasedType,
  element,
  extendsClause,
  formalParameter,
  listIndex,
  recordNamedField,
  recordPositionalField,
  returnType,
  variableType,
}
