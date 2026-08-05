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
  final ast.Variable variable;
  final int index;

  ContextField(this.variable, this.index)
    : super(
        '#context-field:${variable.cosmeticName}',
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

/// Defines assignment of the closure elements.
class ClosureLayout {
  static const int hasDelayedTypeArgsFlag = 1 << 0;
  static const int hasClassTypeArgsFlag = 1 << 1;
  static const int hasFunctionTypeArgsFlag = 1 << 2;

  final int _flags;

  /// Total number of closure elements.
  final int length;

  ClosureLayout(
    int numContexts, {
    required bool hasDelayedTypeArgs,
    required bool hasClassTypeArgs,
    required bool hasFunctionTypeArgs,
  }) : _flags =
           (hasDelayedTypeArgs ? hasDelayedTypeArgsFlag : 0) |
           (hasClassTypeArgs ? hasClassTypeArgsFlag : 0) |
           (hasFunctionTypeArgs ? hasFunctionTypeArgsFlag : 0),
       length =
           (hasDelayedTypeArgs ? 1 : 0) +
           (hasClassTypeArgs ? 1 : 0) +
           (hasFunctionTypeArgs ? 1 : 0) +
           numContexts {
    assert(length == firstContextIndex + numContexts);
  }

  /// Whether closure has an element for delayed type arguments.
  bool get hasDelayedTypeArgs => (_flags & hasDelayedTypeArgsFlag) != 0;

  /// Whether closure has an element for enclosing class type arguments.
  bool get hasClassTypeArgs => (_flags & hasClassTypeArgsFlag) != 0;

  /// Whether closure has an element for enclosing function type arguments.
  bool get hasFunctionTypeArgs => (_flags & hasFunctionTypeArgsFlag) != 0;

  /// Index of the delayed type arguments element.
  int get delayedTypeArgsIndex {
    assert(hasDelayedTypeArgs);
    return 0;
  }

  /// Index of the enclosing class type arguments element.
  int get classTypeArgsIndex {
    assert(hasClassTypeArgs);
    return hasDelayedTypeArgs ? 1 : 0;
  }

  /// Index of the enclosing function type arguments element.
  int get functionTypeArgsIndex {
    assert(hasFunctionTypeArgs);
    return (hasDelayedTypeArgs ? 1 : 0) + (hasClassTypeArgs ? 1 : 0);
  }

  int get firstContextIndex {
    return (hasDelayedTypeArgs ? 1 : 0) +
        (hasClassTypeArgs ? 1 : 0) +
        (hasFunctionTypeArgs ? 1 : 0);
  }
}

/// Field of the record object.
final class RecordField extends SyntheticField {
  final RecordShape shape;
  final int index;

  RecordField(this.shape, this.index)
    : super(
        '#record-field[$index${index >= shape.positional ? ':${shape.named[index - shape.positional]}' : ''}]',
        type: const ast.DynamicType(),
        isFinal: true,
      );
}
