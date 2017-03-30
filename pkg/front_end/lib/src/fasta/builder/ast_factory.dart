// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show DartType, TreeNode;

import 'shadow_ast.dart';

/// An abstract class containing factory methods that create AST objects.
///
/// Itended for use by [BodyBuilder] so that it can create either analyzer or
/// kernel ASTs depending on which concrete factory it is connected to.
///
/// This class is defined in terms of the builder's shadow AST mixins (which are
/// shared between kernel and analyzer shadow AST representations).
///
/// Note that the analyzer AST representation closely parallels Dart syntax,
/// whereas the kernel AST representation is desugared.  The factory methods in
/// this class correspond to the full language (prior to desugaring).  If
/// desugaring is needed, it will be performed by the concrete factory class.
///
/// TODO(paulberry): add missing methods.
///
/// TODO(paulberry): modify [BodyBuilder] so that it creates all kernel objects
/// using this interface.
///
/// TODO(paulberry): change the API to use tokens rather than charOffset, since
/// that's what analyzer ASTs need.  Note that analyzer needs multiple tokens
/// for many AST constructs, not just one.  Note also that for kernel codegen
/// we want to be very careful not to keep tokens around too long, so consider
/// having a `toLocation` method on AstFactory that changes tokens to an
/// abstract type (`int` for kernel, `Token` for analyzer).
///
/// TODO(paulberry): in order to interface with analyzer, we'll need to
/// shadow-ify [DartType], since analyzer ASTs need to be able to record the
/// exact tokens that were used to specify a type.
abstract class AstFactory {
  /// Creates a statement block.
  ShadowBlock block(List<ShadowStatement> statements, int charOffset);

  /// Creates an integer literal.
  ShadowIntLiteral intLiteral(value, int charOffset);

  /// Creates a list literal expression.
  ///
  /// If the list literal did not have an explicitly declared type argument,
  /// [typeArgument] should be `null`.
  ShadowListLiteral listLiteral(List<ShadowExpression> expressions,
      DartType typeArgument, bool isConst, int charOffset);

  /// Creates a null literal expression.
  ShadowNullLiteral nullLiteral(int charOffset);

  /// Creates a return statement.
  ShadowStatement returnStatement(ShadowExpression expression, int charOffset);

  /// Creates a variable declaration statement declaring one variable.
  ///
  /// TODO(paulberry): analyzer makes a distinction between a single variable
  /// declaration and a variable declaration statement (which can contain
  /// multiple variable declarations).  Currently this API only makes sense for
  /// kernel, which desugars each variable declaration to its own statement.
  ///
  /// If the variable declaration did not have an explicitly declared type,
  /// [type] should be `null`.
  ShadowVariableDeclaration variableDeclaration(String name,
      {DartType type,
      ShadowExpression initializer,
      int charOffset: TreeNode.noOffset,
      bool isFinal: false,
      bool isConst: false});
}
