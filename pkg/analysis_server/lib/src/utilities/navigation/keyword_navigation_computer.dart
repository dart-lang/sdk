// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';

/// Computes navigation targets for keywords like `break`, `continue` and
/// `return`.
class KeywordNavigationComputer {
  final NavigationCollector collector;
  final LibraryFragment libraryFrament;

  KeywordNavigationComputer(this.collector, this.libraryFrament);

  void compute(AstNode? node) {
    if (node is! Statement) return;

    var target = switch (node) {
      BreakStatement() ||
      ContinueStatement() => _findBreakOrContinueTarget(node),
      ReturnStatement() || YieldStatement() => _findReturnOrYieldTarget(node),
      _ => null,
    };

    if (target != null) {
      _addRegion(node.beginToken, target);
    }
  }

  void _addRegion(Token sourceToken, Token targetToken) {
    var targetStart = libraryFrament.lineInfo.getLocation(targetToken.offset);
    collector.addRegion(
      sourceToken.offset,
      sourceToken.length,
      protocol.ElementKind.UNKNOWN,
      protocol.Location(
        libraryFrament.source.fullName,
        targetToken.offset,
        targetToken.length,
        targetStart.lineNumber,
        targetStart.columnNumber,
      ),
    );
  }

  Token? _findBreakOrContinueTarget(Statement statement) {
    return switch (statement) {
      BreakStatement() => statement.target?.beginToken,
      ContinueStatement() => statement.target?.beginToken,
      _ => null,
    };
  }

  Token? _findReturnOrYieldTarget(Statement statement) {
    // Find the enclosing function, constructor or method.
    var function = statement.thisOrAncestorOfType<FunctionBody>()?.parent;
    return switch (function) {
      FunctionExpression(:FunctionDeclaration parent) => parent.name,
      // No name for closures, so just use the first token (the opening paren).
      FunctionExpression() => function.beginToken,
      MethodDeclaration() => function.name,
      ConstructorDeclaration() =>
        // For named constructors, return the name.
        // For unnamed constructors, use the return type / class name.
        function.name ?? function.returnType.beginToken,
      _ => null,
    };
  }
}
