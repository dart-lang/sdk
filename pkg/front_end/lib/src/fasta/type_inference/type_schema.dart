// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show
        DartType,
        DartTypeVisitor,
        DartTypeVisitor1,
        FunctionType,
        FutureOrType,
        InterfaceType,
        NamedType,
        Nullability,
        TypedefType,
        Visitor;
import 'package:kernel/src/assumptions.dart';
import 'package:kernel/src/printer.dart';

import 'package:kernel/import_table.dart' show ImportTable;

import 'package:kernel/text/ast_to_text.dart'
    show Annotator, NameSystem, Printer, globalDebuggingNames;

/// Determines whether a type schema contains `?` somewhere inside it.
bool isKnown(DartType schema) => schema.accept(const _IsKnownVisitor());

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
      {NameSystem syntheticNames,
      bool showOffsets: false,
      ImportTable importTable,
      Annotator annotator})
      : super(sink,
            syntheticNames: syntheticNames,
            showOffsets: showOffsets,
            importTable: importTable,
            annotator: annotator);

  @override
  defaultDartType(covariant UnknownType node) {
    writeWord('?');
  }
}

/// The unknown type (denoted `?`) is an object which can appear anywhere that
/// a type is expected.  It represents a component of a type which has not yet
/// been fixed by inference.
///
/// The unknown type cannot appear in programs or in final inferred types: it is
/// purely part of the local inference process.
class UnknownType extends DartType {
  const UnknownType();

  @override
  Nullability get declaredNullability => null;

  @override
  Nullability get nullability => null;

  @override
  bool operator ==(Object other) => equals(other, null);

  @override
  bool equals(Object other, Assumptions assumptions) {
    // This class doesn't have any fields so all instances of `UnknownType` are
    // equal.
    return other is UnknownType;
  }

  @override
  R accept<R>(DartTypeVisitor<R> v) {
    return v.defaultDartType(this);
  }

  @override
  R accept1<R, A>(DartTypeVisitor1<R, A> v, arg) =>
      v.defaultDartType(this, arg);

  @override
  void visitChildren(Visitor<dynamic> v) {}

  @override
  UnknownType withDeclaredNullability(Nullability nullability) => this;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('?');
  }

  @override
  String toString() {
    return "UnknownType(${toStringInternal()})";
  }
}

/// Visitor that computes [isKnown].
class _IsKnownVisitor extends DartTypeVisitor<bool> {
  const _IsKnownVisitor();

  @override
  bool defaultDartType(DartType node) => node is! UnknownType;

  @override
  bool visitFunctionType(FunctionType node) {
    if (!node.returnType.accept(this)) return false;
    for (DartType parameterType in node.positionalParameters) {
      if (!parameterType.accept(this)) return false;
    }
    for (NamedType namedParameterType in node.namedParameters) {
      if (!namedParameterType.type.accept(this)) return false;
    }
    if (node.typedefType != null && !node.typedefType.accept(this)) {
      return false;
    }
    return true;
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    for (DartType typeArgument in node.typeArguments) {
      if (!typeArgument.accept(this)) return false;
    }
    return true;
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return node.typeArgument.accept(this);
  }

  @override
  bool visitTypedefType(TypedefType node) {
    for (DartType typeArgument in node.typeArguments) {
      if (!typeArgument.accept(this)) return false;
    }
    return true;
  }
}
