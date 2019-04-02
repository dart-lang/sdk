// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';

/// An object used to build the details for each token in the code being
/// analyzed.
class TokenDetailBuilder {
  /// The list of details that were built.
  List<TokenDetails> details = [];

  /// Initialize a newly created builder.
  TokenDetailBuilder();

  /// Visit a [node] in the AST structure to build details for all of the tokens
  /// contained by that node.
  void visitNode(AstNode node) {
    for (SyntacticEntity entity in node.childEntities) {
      if (entity is Token) {
        _createDetails(entity, null);
      } else if (entity is SimpleIdentifier) {
        List<String> kinds = [];
        if (entity.inDeclarationContext()) {
          kinds.add('declaration');
        } else {
          kinds.add('identifier');
        }
        _createDetails(entity.token, kinds);
      } else if (entity is AstNode) {
        visitNode(entity);
      }
    }
  }

  /// Create the details for a single [token], using the given list of [kinds].
  void _createDetails(Token token, List<String> kinds) {
    details.add(new TokenDetails(token.lexeme, token.type.name,
        validElementKinds: kinds));
  }
}
