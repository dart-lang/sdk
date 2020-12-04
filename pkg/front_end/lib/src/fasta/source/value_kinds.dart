// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show NullValue;

import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart' as type;

import 'package:_fe_analyzer_shared/src/parser/value_kind.dart';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' as type
    show Token;

import 'package:kernel/ast.dart' as type;

import '../builder/formal_parameter_builder.dart' as type;
import '../builder/metadata_builder.dart' as type;
import '../builder/type_builder.dart' as type;
import '../builder/type_variable_builder.dart' as type;
import '../builder/unresolved_type.dart' as type;

import '../identifiers.dart' as type;

import '../kernel/expression_generator.dart' as type;

import '../modifier.dart' as type;

import '../operator.dart' as type;

import '../scope.dart' as type;

import '../source/outline_builder.dart' as type;

class ValueKinds {
  static const ValueKind Arguments = const SingleValueKind<type.Arguments>();
  static const ValueKind ArgumentsOrNull =
      const SingleValueKind<type.Arguments>(NullValue.Arguments);
  static const ValueKind Expression = const SingleValueKind<type.Expression>();
  static const ValueKind ExpressionOrNull =
      const SingleValueKind<type.Expression>(NullValue.Expression);
  static const ValueKind Identifier = const SingleValueKind<type.Identifier>();
  static const ValueKind IdentifierOrNull =
      const SingleValueKind<type.Identifier>(NullValue.Identifier);
  static const ValueKind Integer = const SingleValueKind<int>();
  static const ValueKind AsyncModifier =
      const SingleValueKind<type.AsyncMarker>();
  static const ValueKind Formals =
      const SingleValueKind<List<type.FormalParameterBuilder>>();
  static const ValueKind FormalsOrNull =
      const SingleValueKind<List<type.FormalParameterBuilder>>(
          NullValue.FormalParameters);
  static const ValueKind Generator = const SingleValueKind<type.Generator>();
  static const ValueKind Initializer =
      const SingleValueKind<type.Initializer>();
  static const ValueKind MethodBody = const SingleValueKind<type.MethodBody>();
  static const ValueKind Modifiers =
      const SingleValueKind<List<type.Modifier>>();
  static const ValueKind ModifiersOrNull =
      const SingleValueKind<List<type.Modifier>>(NullValue.Modifiers);
  static const ValueKind Name = const SingleValueKind<String>();
  static const ValueKind NameOrNull =
      const SingleValueKind<String>(NullValue.Name);
  static const ValueKind NameOrOperator =
      const UnionValueKind([Name, Operator]);
  static const ValueKind NameOrQualifiedNameOrOperator =
      const UnionValueKind([Name, QualifiedName, Operator]);
  static const ValueKind NameOrParserRecovery =
      const UnionValueKind([Name, ParserRecovery]);
  static const ValueKind MetadataListOrNull =
      const SingleValueKind<List<type.MetadataBuilder>>(NullValue.Metadata);
  static const ValueKind ObjectList = const SingleValueKind<List<Object>>();
  static const ValueKind Operator = const SingleValueKind<type.Operator>();
  static const ValueKind ParserRecovery =
      const SingleValueKind<type.ParserRecovery>();
  static const ValueKind ProblemBuilder =
      const SingleValueKind<type.ProblemBuilder>();
  static const ValueKind QualifiedName =
      const SingleValueKind<type.QualifiedName>();
  static const ValueKind Statement = const SingleValueKind<type.Statement>();
  static const ValueKind Token = const SingleValueKind<type.Token>();
  static const ValueKind TokenOrNull =
      const SingleValueKind<type.Token>(NullValue.Token);
  static const ValueKind TypeArgumentsOrNull =
      const SingleValueKind<List<type.UnresolvedType>>(NullValue.TypeArguments);
  static const ValueKind TypeBuilder =
      const SingleValueKind<type.TypeBuilder>();
  static const ValueKind TypeBuilderOrNull =
      const SingleValueKind<type.TypeBuilder>(NullValue.Type);
  static const ValueKind TypeVariableListOrNull =
      const SingleValueKind<List<type.TypeVariableBuilder>>(
          NullValue.TypeVariables);
}
