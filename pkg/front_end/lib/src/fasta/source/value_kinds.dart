// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as type;

import '../builder/builder.dart' as type;

import '../kernel/expression_generator.dart' as type;

import '../modifier.dart' as type;

import '../operator.dart' as type;

import '../scanner.dart' as type show Token;

import '../scope.dart' as type;

import '../source/outline_builder.dart' as type;

import 'stack_listener.dart' show NullValue;

import 'stack_listener.dart' as type;

/// [ValueKind] is used in [StackListener.checkState] to document and check the
/// expected values of the stack.
///
/// Add new value kinds as needed for documenting and checking the various stack
/// listener implementations.
abstract class ValueKind {
  const ValueKind();

  /// Checks the [value] an returns `true` if the value is of the expected kind.
  bool check(Object value);

  static const ValueKind Arguments = const _SingleValueKind<type.Arguments>();
  static const ValueKind ArgumentsOrNull =
      const _SingleValueKind<type.Arguments>(NullValue.Arguments);
  static const ValueKind Expression = const _SingleValueKind<type.Expression>();
  static const ValueKind ExpressionOrNull =
      const _SingleValueKind<type.Expression>(NullValue.Expression);
  static const ValueKind Identifier = const _SingleValueKind<type.Identifier>();
  static const ValueKind IdentifierOrNull =
      const _SingleValueKind<type.Identifier>(NullValue.Identifier);
  static const ValueKind Integer = const _SingleValueKind<int>();
  static const ValueKind Formals =
      const _SingleValueKind<List<type.FormalParameterBuilder>>();
  static const ValueKind FormalsOrNull =
      const _SingleValueKind<List<type.FormalParameterBuilder>>(
          NullValue.FormalParameters);
  static const ValueKind Generator = const _SingleValueKind<type.Generator>();
  static const ValueKind Initializer =
      const _SingleValueKind<type.Initializer>();
  static const ValueKind MethodBody = const _SingleValueKind<type.MethodBody>();
  static const ValueKind Modifiers =
      const _SingleValueKind<List<type.Modifier>>();
  static const ValueKind ModifiersOrNull =
      const _SingleValueKind<List<type.Modifier>>(NullValue.Modifiers);
  static const ValueKind Name = const _SingleValueKind<String>();
  static const ValueKind NameOrNull =
      const _SingleValueKind<String>(NullValue.Name);
  static const ValueKind NameOrOperator =
      const _UnionValueKind([Name, Operator]);
  static const ValueKind NameOrQualifiedNameOrOperator =
      const _UnionValueKind([Name, QualifiedName, Operator]);
  static const ValueKind NameOrParserRecovery =
      const _UnionValueKind([Name, ParserRecovery]);
  static const ValueKind MetadataListOrNull =
      const _SingleValueKind<List<type.MetadataBuilder>>(NullValue.Metadata);
  static const ValueKind ObjectList = const _SingleValueKind<List<Object>>();
  static const ValueKind Operator = const _SingleValueKind<type.Operator>();
  static const ValueKind ParserRecovery =
      const _SingleValueKind<type.ParserRecovery>();
  static const ValueKind ProblemBuilder =
      const _SingleValueKind<type.ProblemBuilder>();
  static const ValueKind QualifiedName =
      const _SingleValueKind<type.QualifiedName>();
  static const ValueKind Statement = const _SingleValueKind<type.Statement>();
  static const ValueKind Token = const _SingleValueKind<type.Token>();
  static const ValueKind TokenOrNull =
      const _SingleValueKind<type.Token>(NullValue.Token);
  static const ValueKind TypeArgumentsOrNull =
      const _SingleValueKind<List<type.UnresolvedType>>(
          NullValue.TypeArguments);
  static const ValueKind TypeBuilder =
      const _SingleValueKind<type.TypeBuilder>();
  static const ValueKind TypeBuilderOrNull =
      const _SingleValueKind<type.TypeBuilder>(NullValue.Type);
  static const ValueKind TypeVariableListOrNull =
      const _SingleValueKind<List<type.TypeVariableBuilder>>(
          NullValue.TypeVariables);
}

/// A [ValueKind] for a particular type [T], optionally with a recognized
/// [NullValue].
class _SingleValueKind<T> implements ValueKind {
  final NullValue nullValue;

  const _SingleValueKind([this.nullValue]);

  @override
  bool check(Object value) {
    if (nullValue != null && value == nullValue) {
      return true;
    }
    return value is T;
  }

  String toString() {
    if (nullValue != null) {
      return '$T or $nullValue';
    }
    return '$T';
  }
}

/// A [ValueKind] for the union of a list of [ValueKind]s.
class _UnionValueKind implements ValueKind {
  final List<ValueKind> kinds;

  const _UnionValueKind(this.kinds);

  @override
  bool check(Object value) {
    for (ValueKind kind in kinds) {
      if (kind.check(value)) {
        return true;
      }
    }
    return false;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    String or = '';
    for (ValueKind kind in kinds) {
      sb.write(or);
      sb.write(kind);
      or = ' or ';
    }
    return sb.toString();
  }
}

/// Helper method for creating a list of [ValueKind]s of the given length
/// [count].
List<ValueKind> repeatedKinds(ValueKind kind, int count) {
  return new List.generate(count, (_) => kind);
}

/// Helper method for creating a union of a list of [ValueKind]s.
ValueKind unionOfKinds(List<ValueKind> kinds) {
  return new _UnionValueKind(kinds);
}
