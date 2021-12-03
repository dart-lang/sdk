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

import '../identifiers.dart' as type;

import '../kernel/body_builder.dart' as type show FormalParameters;
import '../kernel/expression_generator.dart' as type;

import '../modifier.dart' as type;

import '../operator.dart' as type;

import '../scope.dart' as type;

import '../source/outline_builder.dart' as type;

import '../constant_context.dart' as type;

class ValueKinds {
  static const ValueKind AnnotationList =
      const SingleValueKind<List<type.Expression>>();
  static const ValueKind AnnotationListOrNull =
      const SingleValueKind<List<type.Expression>>(NullValue.Metadata);
  static const ValueKind Arguments = const SingleValueKind<type.Arguments>();
  static const ValueKind ArgumentsOrNull =
      const SingleValueKind<type.Arguments>(NullValue.Arguments);
  static const ValueKind AsyncMarker =
      const SingleValueKind<type.AsyncMarker>();
  static const ValueKind Bool = const SingleValueKind<bool>();
  static const ValueKind ConstantContext =
      const SingleValueKind<type.ConstantContext>();
  static const ValueKind Expression = const SingleValueKind<type.Expression>();
  static const ValueKind ExpressionOrNull =
      const SingleValueKind<type.Expression>(NullValue.Expression);
  static const ValueKind FieldInitializerOrNull =
      const SingleValueKind<type.Expression>(NullValue.FieldInitializer);
  static const ValueKind Identifier = const SingleValueKind<type.Identifier>();
  static const ValueKind IdentifierOrNull =
      const SingleValueKind<type.Identifier>(NullValue.Identifier);
  static const ValueKind Integer = const SingleValueKind<int>();
  static const ValueKind AsyncModifier =
      const SingleValueKind<type.AsyncMarker>();
  static const ValueKind FormalParameters =
      const SingleValueKind<type.FormalParameters>();
  static const ValueKind FormalList =
      const SingleValueKind<List<type.FormalParameterBuilder>>();
  static const ValueKind FormalListOrNull =
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
  static const ValueKind NameListOrNull =
      const SingleValueKind<List<String>>(NullValue.IdentifierList);
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
  static const ValueKind OperatorListOrNull =
      const SingleValueKind<List<type.Operator>>(NullValue.OperatorList);
  static const ValueKind ParserRecovery =
      const SingleValueKind<type.ParserRecovery>();
  static const ValueKind ProblemBuilder =
      const SingleValueKind<type.ProblemBuilder>();
  static const ValueKind QualifiedName =
      const SingleValueKind<type.QualifiedName>();
  static const ValueKind Scope = const SingleValueKind<type.Scope>();
  static const ValueKind Selector = const SingleValueKind<type.Selector>();
  static const ValueKind SwitchScopeOrNull =
      const SingleValueKind<type.Scope>(NullValue.SwitchScope);
  static const ValueKind Statement = const SingleValueKind<type.Statement>();
  static const ValueKind StatementOrNull =
      const SingleValueKind<type.Statement>(NullValue.Block);
  static const ValueKind Token = const SingleValueKind<type.Token>();
  static const ValueKind TokenOrNull =
      const SingleValueKind<type.Token>(NullValue.Token);
  static const ValueKind TypeOrNull =
      const SingleValueKind<type.TypeBuilder>(NullValue.TypeBuilder);
  static const ValueKind TypeArguments =
      const SingleValueKind<List<type.TypeBuilder>>();
  static const ValueKind TypeArgumentsOrNull =
      const SingleValueKind<List<type.TypeBuilder>>(NullValue.TypeArguments);
  static const ValueKind TypeBuilder =
      const SingleValueKind<type.TypeBuilder>();
  static const ValueKind TypeBuilderOrNull =
      const SingleValueKind<type.TypeBuilder>(NullValue.TypeBuilder);
  static const ValueKind TypeBuilderListOrNull =
      const SingleValueKind<List<type.TypeBuilder>>(NullValue.TypeBuilderList);
  static const ValueKind TypeVariableListOrNull =
      const SingleValueKind<List<type.TypeVariableBuilder>>(
          NullValue.TypeVariables);
}
