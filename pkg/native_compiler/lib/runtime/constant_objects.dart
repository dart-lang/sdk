// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast;
import 'package:kernel/src/printer.dart' as ast_printer show AstPrinter;
import 'package:kernel/type_environment.dart' show StaticTypeContext;

/// Kind of the unique VM object.
///
/// These unique objects are created by the VM at runtime,
/// so they are basically "runtime constants".
enum RuntimeConstantObjectKind {
  // A unique `Object::uninitialized_index()` object.
  // Result of '_uninitializedIndex' from dart:_compact_hash.
  uninitializedIndex,

  // A unique `Object::uninitialized_data()` object.
  // Result of '_uninitializedData' from dart:_compact_hash.
  uninitializedData,
}

/// Constant representing the unique VM object.
///
/// These objects are constant and canonical at runtime,
/// but they are not representable with regular Dart constants.
final class RuntimeConstantObject(final RuntimeConstantObjectKind kind)
    extends ast.AuxiliaryConstant {
  @override
  void visitChildren(ast.Visitor v) {}

  @override
  void toTextInternal(ast_printer.AstPrinter printer) {
    printer.write('#runtime-constant-object ${kind.name}');
  }

  @override
  String toString() => 'RuntimeConstantObject(${kind.name})';

  @override
  int get hashCode => kind.hashCode;

  @override
  bool operator ==(Object other) =>
      other is RuntimeConstantObject && other.kind == kind;

  @override
  ast.DartType getType(StaticTypeContext context) {
    final coreTypes = context.typeEnvironment.coreTypes;
    return switch (kind) {
      .uninitializedIndex => coreTypes.nonNullableRawType(
        coreTypes.index.getClass('dart:typed_data', 'Uint32List'),
      ),
      .uninitializedData => coreTypes.listNonNullableRawType,
    };
  }
}
