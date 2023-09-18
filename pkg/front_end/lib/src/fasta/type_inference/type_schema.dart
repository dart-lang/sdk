// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/find_type_visitor.dart';
import 'package:kernel/src/printer.dart';

import 'package:kernel/import_table.dart' show ImportTable;

import 'package:kernel/text/ast_to_text.dart'
    show Annotator, NameSystem, Printer, globalDebuggingNames;

/// Determines whether a type schema contains `?` somewhere inside it.
bool isKnown(DartType schema) => !schema.accept(const _HasUnknownVisitor());

/// Converts a [DartType] to a string, representing the unknown type as `?`.
String typeSchemaToString(DartType schema) {
  StringBuffer buffer = new StringBuffer();
  new TypeSchemaPrinter(buffer, syntheticNames: globalDebuggingNames)
      .writeNode(schema);
  return '$buffer';
}

/// Extension of [Printer] that represents the unknown type as `?`.
class TypeSchemaPrinter extends Printer {
  TypeSchemaPrinter(StringSink sink,
      {NameSystem? syntheticNames,
      bool showOffsets = false,
      ImportTable? importTable,
      Annotator? annotator})
      : super(sink,
            syntheticNames: syntheticNames,
            showOffsets: showOffsets,
            importTable: importTable,
            annotator: annotator);

  @override
  void defaultDartType(covariant UnknownType node) {
    writeWord('?');
  }
}

/// The unknown type (denoted `?`) is an object which can appear anywhere that
/// a type is expected.  It represents a component of a type which has not yet
/// been fixed by inference.
///
/// The unknown type cannot appear in programs or in final inferred types: it is
/// purely part of the local inference process.
class UnknownType extends AuxiliaryType {
  const UnknownType();

  @override
  Nullability get declaredNullability => Nullability.undetermined;

  @override
  Nullability get nullability => Nullability.undetermined;

  @override
  DartType get resolveTypeParameterType => this;

  @override
  bool equals(Object other, Assumptions? assumptions) {
    // This class doesn't have any fields so all instances of `UnknownType` are
    // equal.
    return other is UnknownType;
  }

  @override
  void visitChildren(Visitor<dynamic> v) {}

  @override
  UnknownType withDeclaredNullability(Nullability nullability) => this;

  @override
  UnknownType toNonNull() => this;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('?');
  }

  @override
  String toString() {
    return "UnknownType(${toStringInternal()})";
  }
}

/// Visitor used to compute [isKnown].
class _HasUnknownVisitor extends FindTypeVisitor {
  const _HasUnknownVisitor();

  @override
  bool visitAuxiliaryType(AuxiliaryType node) => node is UnknownType;
}
