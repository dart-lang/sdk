// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;

/// Instance or static field used in CFG IR.
extension type CField(ast.Field _raw) {
  bool get isStatic => _raw.isStatic;
  bool get isLate => _raw.isLate;
  bool get isFinal => _raw.isFinal;
  bool get hasInitializer => _raw.initializer != null;
  CType get type => CType.fromStaticType(_raw.type);
  ast.Class get enclosingClass => _raw.enclosingClass!;
  ast.Field get astField => _raw;

  bool get isSynthetic => _raw is SyntheticField;
  SyntheticField get asSynthetic => _raw as SyntheticField;
}

/// Synthetic field, not present in the Dart program.
sealed class SyntheticField extends ast.Field {
  SyntheticField(
    String name, {
    required super.type,
    super.isFinal = false,
    super.isLate = false,
  }) : super.mutable(ast.Name(name), fileUri: ast.dummyUri);
}

/// Field of the context object.
/// Context fields hold values of captured variables.
final class ContextField extends SyntheticField {
  final ast.VariableDeclaration variable;
  final int index;

  ContextField(this.variable, this.index)
    : super(
        '#context-field:${variable.name}',
        type: variable.type,
        isFinal: variable.isFinal,
        isLate: variable.isLate,
      );
}

/// Field of the closure object.
/// Closure fields hold captured contexts.
final class ClosureField extends SyntheticField {
  final int index;

  ClosureField(this.index)
    : super(
        '#closure-field[$index]',
        type: const ast.DynamicType(),
        isFinal: true,
      );
}
