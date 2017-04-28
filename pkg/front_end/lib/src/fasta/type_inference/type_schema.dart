// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart';
import 'package:kernel/import_table.dart';
import 'package:kernel/text/ast_to_text.dart';

/// Converts a [DartType] to a string, representing the unknown type as `?`.
String typeSchemaToString(DartType schema) {
  StringBuffer buffer = new StringBuffer();
  new TypeSchemaPrinter(buffer, syntheticNames: globalDebuggingNames)
      .writeNode(schema);
  return '$buffer';
}

/// Extension of [Printer] that represents the unknown type as `?`.
class TypeSchemaPrinter extends Printer implements TypeSchemaVisitor<Null> {
  TypeSchemaPrinter(StringSink sink,
      {NameSystem syntheticNames,
      bool showExternal,
      bool showOffsets: false,
      ImportTable importTable,
      Annotator annotator})
      : super(sink,
            syntheticNames: syntheticNames,
            showExternal: showExternal,
            showOffsets: showOffsets,
            importTable: importTable,
            annotator: annotator);

  @override
  visitUnknownType(UnknownType node) {
    writeWord('?');
  }
}

/// Extension of [DartTypeVisitor] which can visit [UnknownType].
class TypeSchemaVisitor<R> extends DartTypeVisitor<R> {
  /// Called when [UnknownType] is visited.
  R visitUnknownType(UnknownType node) => defaultDartType(node);
}

/// The unknown type (denoted `?`) is an object which can appear anywhere that
/// a type is expected.  It represents a component of a type which has not yet
/// been fixed by inference.
///
/// The unknown type cannot appear in programs or in final inferred types: it is
/// purely part of the local inference process.
class UnknownType extends DartType {
  const UnknownType();

  bool operator ==(Object other) {
    // This class doesn't have any fields so all instances of `UnknownType` are
    // equal.
    return other is UnknownType;
  }

  @override
  accept(DartTypeVisitor v) {
    if (v is TypeSchemaVisitor) {
      return v.visitUnknownType(this);
    } else {
      // Note: in principle it seems like this should throw, since any visitor
      // that operates on a type schema ought to inherit from TypeSchemaVisitor.
      // However, that would make it impossible to use toString() on any type
      // schema, since toString() uses the kernel's Printer visitor, which can't
      // possibly inherit from TypeSchemaVisitor since it's inside kernel.
      return v.defaultDartType(this);
    }
  }

  @override
  visitChildren(Visitor v) {}
}
