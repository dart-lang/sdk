// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as type show Arguments, Expression;

import '../builder/builder.dart' as type;

import '../kernel/expression_generator.dart' as type;

import '../scanner.dart' as type show Token;

import '../scope.dart' as type;

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

  static const ValueKind ArgumentsOrNull =
      _SingleValueKind<type.Arguments>(NullValue.Arguments);
  static const ValueKind Expression = _SingleValueKind<type.Expression>();
  static const ValueKind Identifier = _SingleValueKind<type.Identifier>();
  static const ValueKind Integer = _SingleValueKind<int>();
  static const ValueKind Generator = _SingleValueKind<type.Generator>();
  static const ValueKind Name = _SingleValueKind<String>();
  static const ValueKind NameOrNull = _SingleValueKind<String>(NullValue.Name);
  static const ValueKind NameOrParserRecovery =
      _UnionValueKind([Name, ParserRecovery]);
  static const ValueKind MetadataListOrNull =
      _SingleValueKind<List<type.MetadataBuilder>>(NullValue.Metadata);
  static const ValueKind ParserRecovery =
      _SingleValueKind<type.ParserRecovery>();
  static const ValueKind ProblemBuilder =
      _SingleValueKind<type.ProblemBuilder>();
  static const ValueKind Token = _SingleValueKind<type.Token>();
  static const ValueKind TokenOrNull =
      _SingleValueKind<type.Token>(NullValue.Token);
  static const ValueKind TypeArgumentsOrNull =
      _SingleValueKind<List<type.UnresolvedType>>(NullValue.TypeArguments);
  static const ValueKind TypeBuilder = _SingleValueKind<type.TypeBuilder>();
  static const ValueKind TypeVariableListOrNull =
      _SingleValueKind<List<type.TypeVariableBuilder>>(NullValue.TypeVariables);
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
}

/// Helper method for creating a list of [ValueKind]s of the given length
/// [count].
List<ValueKind> repeatedKinds(ValueKind kind, int count) {
  return new List.generate(count, (_) => kind);
}

/// Helper method for creating a union of a list of [ValueKind]s.
ValueKind unionOfKinds(List<ValueKind> kinds) {
  return _UnionValueKind(kinds);
}
