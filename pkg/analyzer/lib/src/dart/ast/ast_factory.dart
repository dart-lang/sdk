// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// The instance of [AstFactoryImpl].
final AstFactoryImpl astFactory = AstFactoryImpl();

class AstFactoryImpl {
  CommentImpl blockComment(List<Token> tokens) =>
      CommentImpl.createBlockComment(tokens);

  CommentImpl documentationComment(List<Token> tokens,
          [List<CommentReference>? references]) =>
      CommentImpl.createDocumentationCommentWithReferences(
          tokens, references ?? <CommentReference>[]);

  CommentImpl endOfLineComment(List<Token> tokens) =>
      CommentImpl.createEndOfLineComment(tokens);

  NodeListImpl<E> nodeList<E extends AstNode>(AstNode owner) =>
      NodeListImpl<E>(owner as AstNodeImpl);

  SimpleIdentifierImpl simpleIdentifier(Token token,
      {bool isDeclaration = false}) {
    if (isDeclaration) {
      return DeclaredSimpleIdentifier(token);
    }
    return SimpleIdentifierImpl(token);
  }
}
