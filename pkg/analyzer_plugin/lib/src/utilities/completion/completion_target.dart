// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/source.dart';

/// A CompletionTarget represents an edge in the parse tree which connects an
/// AST node (the [containingNode] of the completion) to one of its children
/// (the [entity], which represents the place in the parse tree where the newly
/// completed text will be inserted).
///
/// To illustrate, consider the following snippet of code, and its associated
/// parse tree. (T's represent tokens, N's represent AST nodes. Some trivial
/// AST nodes are not shown).
///
///            ___N        (function declaration)
///           /    \
///          /    __N_______  (function body)
///         /    /  |a      \
///        /    /   N______  \  (statement)
///       /    /   /       \  \
///      /    /   N____     \  \  (assignment expression)
///     |    /   /|    \     \  \
///     .   |   / |    _N___  \  |  ("as" expression)
///     .   |  |  |   / |   \c | |
///     .   |  N  |  N  |b   N | |  (simple identifiers)
///         |  |  |  |  |    | | |
///         T  T  T  T  T    T T T
///     m() { foo = bar as  Baz; }
///
/// The Completion target is usually placed as high in the tree as possible so
/// that we can produce the most meaningful completions with minimal effort.
/// For instance, if the cursor is inside the identifier "foo", the completion
/// target will be the edge marked "a", so that we will produce all completions
/// that could possibly start a statement, even those which would conflict with
/// the current parse (such as the keyword "for", which begins a "for"
/// statement). As a consequence of this, the [entity] will usually not be the
/// first child of the [containingNode] node.
///
/// Note that the [containingNode] is always an AST node, but the [entity] may
/// not be. For instance, if the cursor is inside the keyword "as", the
/// completion target will be the edge marked "b", so the [entity] is the token
/// "as".
///
/// If the cursor is between tokens, the completion target is usually associated
/// with the token that follows the cursor (since that's the token that will be
/// displaced when the new text is inserted). For example, if the cursor is
/// after the "{" character, then the completion target will be the edge marked
/// "a", just as it is if the cursor is inside the identifier "foo". However
/// there is one exception: if the cursor is at the rightmost edge of a keyword
/// or identifier, then the completion target is associated with that token,
/// since any further letters typed will change the meaning of the identifier or
/// keyword, rather than creating a new token. So for instance, if the cursor
/// is just after the "s" of "as", the completion target will be the edge marked
/// "b", but if the cursor target is after the first space following "as", then
/// the completion target will be the edge marked "c".
///
/// If the file is empty, or the cursor is after all the text in the file, then
/// there may be no edge in the parse tree which is appropriate to act as the
/// completion target; in this case, [entity] is set to null and
/// [containingNode] is set to the CompilationUnit.
///
/// Clients may not extend, implement or mix-in this class.
class CompletionTarget {
  /// The compilation unit in which the completion is occurring.
  final CompilationUnit unit;

  /// The offset within the source at which the completion is being requested.
  final int offset;

  /// The context in which the completion is occurring. This is the AST node
  /// which is a direct parent of [entity].
  final AstNode containingNode;

  /// The "dropped" identifier or keyword which the completed text will replace,
  /// or `null` if none.
  ///
  /// For the purposes of code completion, a "dropped" token is an identifier
  /// or keyword that is part of the token stream, but that the parser has
  /// skipped and not reported in to the parser listeners, meaning that it is
  /// not part of the AST.
  Token droppedToken;

  /// The entity which the completed text will replace (or which will be
  /// displaced once the completed text is inserted). This may be an AstNode or
  /// a Token, or it may be null if the cursor is after all tokens in the file.
  ///
  /// Usually, the entity won't be the first child of the [containingNode] (this
  /// is a consequence of placing the completion target as high in the tree as
  /// possible). However, there is one exception: when the cursor is inside of
  /// a multi-character token which is not a keyword or identifier (e.g. a
  /// comment, or a token like "+=", the entity will be always be the token.
  final SyntacticEntity entity;

  /// The [entity] is a comment token, which is either not a documentation
  /// comment or the position is not in a [CommentReference].
  final bool isCommentText;

  /// If the target is an argument in an [ArgumentList], then this is the index
  /// of the argument in the list, otherwise this is `null`.
  final int argIndex;

  /// If the target is an argument in an [ArgumentList], then this is the
  /// invoked [ExecutableElement], otherwise this is `null`.
  ExecutableElement _executableElement;

  /// If the target is an argument in an [ArgumentList], then this is the
  /// corresponding [ParameterElement] in the invoked [ExecutableElement],
  /// otherwise this is `null`.
  ParameterElement _parameterElement;

  /// Compute the appropriate [CompletionTarget] for the given [offset] within
  /// the [compilationUnit].
  ///
  /// Optionally, start the search from within [entryPoint] instead of using
  /// the [compilationUnit], which is useful for analyzing ASTs that have no
  /// [compilationUnit] such as dart expressions within angular templates.
  factory CompletionTarget.forOffset(
      CompilationUnit compilationUnit, int offset,
      {AstNode entryPoint}) {
    // The precise algorithm is as follows. We perform a depth-first search of
    // all edges in the parse tree (both those that point to AST nodes and
    // those that point to tokens), visiting parents before children. The
    // first edge which points to an entity satisfying either _isCandidateToken
    // or _isCandidateNode is the completion target. If no edge is found that
    // satisfies these two predicates, then we set the completion target entity
    // to null and the containingNode to the entryPoint.
    //
    // Note that if a token is not a candidate target, then none of the tokens
    // that precede it are candidate targets either. Therefore any entity
    // whose last token is not a candidate target can be skipped. This lets us
    // prune the search to the point where no recursion is necessary; at each
    // step in the process we know exactly which child node we need to proceed
    // to.
    entryPoint ??= compilationUnit;
    var containingNode = entryPoint;
    outerLoop:
    while (true) {
      if (containingNode is Comment) {
        // Comments are handled specially: we descend into any CommentReference
        // child node that contains the cursor offset.
        var comment = containingNode as Comment;
        for (var commentReference in comment.references) {
          if (commentReference.offset <= offset &&
              offset <= commentReference.end) {
            containingNode = commentReference;
            continue outerLoop;
          }
        }
      }
      for (var entity in containingNode.childEntities) {
        if (entity is Token) {
          if (_isCandidateToken(containingNode, entity, offset)) {
            // Try to replace with a comment token.
            var commentToken = _getContainingCommentToken(entity, offset);
            if (commentToken != null) {
              return CompletionTarget._(
                  compilationUnit, offset, containingNode, commentToken, true);
            }
            // Target found.
            return CompletionTarget._(
                compilationUnit, offset, containingNode, entity, false);
          } else {
            // Since entity is a token, we don't need to look inside it; just
            // proceed to the next entity.
            continue;
          }
        } else if (entity is AstNode) {
          // If the last token in the node isn't a candidate target, then
          // neither the node nor any of its descendants can possibly be the
          // completion target, so we can skip the node entirely.
          if (!_isCandidateToken(containingNode, entity.endToken, offset)) {
            continue;
          }

          // If the node is a candidate target, then we are done.
          if (_isCandidateNode(entity, offset)) {
            // Check to see if the offset is in a preceding comment
            var commentToken =
                _getContainingCommentToken(entity.beginToken, offset);
            if (commentToken != null) {
              // If the preceding comment is dartdoc token, then update
              // the containing node to be the dartdoc comment.
              // Otherwise completion is not required.
              var docComment =
                  _getContainingDocComment(containingNode, commentToken);
              if (docComment != null) {
                return CompletionTarget._(
                    compilationUnit, offset, docComment, commentToken, false);
              } else {
                return CompletionTarget._(compilationUnit, offset,
                    compilationUnit, commentToken, true);
              }
            }
            return CompletionTarget._(
                compilationUnit, offset, containingNode, entity, false);
          }

          // Otherwise, the completion target is somewhere inside the entity,
          // so we need to jump to the start of the outer loop to examine its
          // contents.
          containingNode = entity;
          continue outerLoop;
        } else {
          // Unexpected entity found (all entities in a parse tree should be
          // AST nodes or tokens).
          assert(false);
        }
      }

      // No completion target found. It should only be possible to reach here
      // the first time through the outer loop (since we only jump to the start
      // of the outer loop after determining that the completion target is
      // inside an entity). We can check that assumption by verifying that
      // containingNode is still the entryPoint.
      assert(identical(containingNode, entryPoint));

      // Since no completion target was found, we set the completion target
      // entity to null and use the entryPoint as the parent.
      return CompletionTarget._(
          compilationUnit, offset, entryPoint, null, false);
    }
  }

  /// Create a [CompletionTarget] holding the given [containingNode] and
  /// [entity].
  CompletionTarget._(this.unit, this.offset, AstNode containingNode,
      SyntacticEntity entity, this.isCommentText)
      : containingNode = containingNode,
        entity = entity,
        argIndex = _computeArgIndex(containingNode, entity),
        droppedToken = _computeDroppedToken(containingNode, entity, offset);

  /// If the target is an argument in an argument list, and the invocation is
  /// resolved, return the invoked [ExecutableElement].
  ExecutableElement get executableElement {
    if (_executableElement == null) {
      var argumentList = containingNode;
      if (argumentList is NamedExpression) {
        argumentList = argumentList.parent;
      }
      if (argumentList is! ArgumentList) {
        return null;
      }

      var invocation = argumentList.parent;

      Element executable;
      if (invocation is Annotation) {
        executable = invocation.element;
      } else if (invocation is InstanceCreationExpression) {
        executable = invocation.constructorName.staticElement;
      } else if (invocation is MethodInvocation) {
        executable = invocation.methodName.staticElement;
      } else if (invocation is SuperConstructorInvocation) {
        executable = invocation.staticElement;
      }

      if (executable is ExecutableElement) {
        _executableElement = executable;
      }
    }
    return _executableElement;
  }

  /// Return `true` if the [containingNode] is a cascade
  /// and the completion insertion is not between the two dots.
  /// For example, `..d^` and `..^d` are considered a cascade
  /// from a completion standpoint, but `.^.d` is not.
  bool get isCascade {
    var node = containingNode;
    if (node is PropertyAccess) {
      return node.isCascaded && offset > node.operator.offset + 1;
    }
    if (node is MethodInvocation) {
      return node.isCascaded && offset > node.operator.offset + 1;
    }
    return false;
  }

  /// If the target is an argument in an argument list, and the invocation is
  /// resolved, return the corresponding [ParameterElement].
  ParameterElement get parameterElement {
    if (_parameterElement == null) {
      var executable = executableElement;
      if (executable != null) {
        _parameterElement = _getParameterElement(
            executable.parameters, containingNode, argIndex);
      }
    }
    return _parameterElement;
  }

  /// Return a source range that represents the region of text that should be
  /// replaced when a suggestion based on this target is selected, given that
  /// the completion was requested at the given [requestOffset].
  SourceRange computeReplacementRange(int requestOffset) {
    bool isKeywordOrIdentifier(Token token) =>
        token.type.isKeyword || token.type == TokenType.IDENTIFIER;

    var token = droppedToken ??
        (entity is AstNode ? (entity as AstNode).beginToken : entity as Token);
    if (token != null && requestOffset < token.offset) {
      token = containingNode.findPrevious(token);
    }
    if (token != null) {
      if (requestOffset == token.offset && !isKeywordOrIdentifier(token)) {
        // If the insertion point is at the beginning of the current token
        // and the current token is not an identifier
        // then check the previous token to see if it should be replaced
        token = containingNode.findPrevious(token);
      }
      if (token != null && isKeywordOrIdentifier(token)) {
        if (token.offset <= requestOffset && requestOffset <= token.end) {
          // Replacement range for typical identifier completion
          return SourceRange(token.offset, token.length);
        }
      }
      if (token is StringToken) {
        var uri = astFactory.simpleStringLiteral(token, token.lexeme);
        var keyword = containingNode.findPrevious(token)?.keyword;
        if (keyword == Keyword.IMPORT ||
            keyword == Keyword.EXPORT ||
            keyword == Keyword.PART) {
          var start = uri.contentsOffset;
          var end = uri.contentsEnd;
          if (start <= requestOffset && requestOffset <= end) {
            // Replacement range for import URI
            return SourceRange(start, end - start);
          }
        }
      }
    }
    return SourceRange(requestOffset, 0);
  }

  /// Return `true` if the target is a double or int literal.
  bool isDoubleOrIntLiteral() {
    var entity = this.entity;
    if (entity is Token) {
      var previousTokenType = containingNode.findPrevious(entity)?.type;
      return previousTokenType == TokenType.DOUBLE ||
          previousTokenType == TokenType.INT;
    }
    return false;
  }

  /// Return `true` if the target is a functional argument in an argument list.
  /// The target [AstNode] hierarchy *must* be resolved for this to work.
  bool isFunctionalArgument() {
    return parameterElement?.type is FunctionType;
  }

  /// Given that the [node] contains the [offset], return the [FormalParameter]
  /// that encloses the [offset], or `null`.
  static FormalParameter findFormalParameter(
    FormalParameterList node,
    int offset,
  ) {
    assert(node.offset < offset && offset < node.end);
    var parameters = node.parameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (i == 0 && offset < parameter.offset) {
        return parameter;
      }
      if (parameter.offset <= offset) {
        if (i < parameters.length - 1) {
          if (offset < parameters[i + 1].offset) {
            return parameter;
          }
        } else if (offset <= node.rightParenthesis.offset) {
          return parameter;
        }
      }
    }
    return null;
  }

  static int _computeArgIndex(AstNode containingNode, Object entity) {
    var argList = containingNode;
    if (argList is NamedExpression) {
      entity = argList;
      argList = argList.parent;
    }
    if (argList is ArgumentList) {
      var args = argList.arguments;
      for (var index = 0; index < args.length; ++index) {
        if (entity == args[index]) {
          return index;
        }
      }
      if (args.isEmpty) {
        return 0;
      }
      if (entity == argList.rightParenthesis) {
        // Parser ignores trailing commas
        var previous = containingNode.findPrevious(argList.rightParenthesis);
        if (previous?.lexeme == ',') {
          return args.length;
        }
        return args.length - 1;
      }
    }
    return null;
  }

  static Token _computeDroppedToken(
      AstNode containingNode, Object entity, int offset) {
    // Find the last token of the member before the entity.
    var previousMember;
    for (var member in containingNode.childEntities) {
      if (entity == member) {
        break;
      }
      if (member is! Comment && member is! CommentToken) {
        previousMember = member;
      }
    }
    Token token;
    if (previousMember is AstNode) {
      token = previousMember.endToken;
    } else if (previousMember is Token) {
      token = previousMember;
    }
    if (token == null) {
      return null;
    }

    // Find the first token of the entity (which may be the entity itself).
    Token endSearch;
    if (entity is AstNode) {
      endSearch = entity.beginToken;
    } else if (entity is Token) {
      endSearch = entity;
    }
    if (endSearch == null) {
      return null;
    }

    // Find a dropped token that overlaps the offset.
    token = token.next;
    while (token != endSearch && !token.isEof) {
      if (token.isKeywordOrIdentifier &&
          token.offset <= offset &&
          offset <= token.end) {
        return token;
      }
      token = token.next;
    }
    return null;
  }

  /// Determine if the offset is contained in a preceding comment token
  /// and return that token, otherwise return `null`.
  static Token _getContainingCommentToken(Token token, int offset) {
    if (token == null) {
      return null;
    }
    if (offset >= token.offset) {
      return null;
    }
    token = token.precedingComments;
    while (token != null) {
      if (offset <= token.offset) {
        return null;
      }
      if (offset <= token.end) {
        if (token.type == TokenType.SINGLE_LINE_COMMENT || offset < token.end) {
          return token;
        }
      }
      token = token.next;
    }
    return null;
  }

  /// Determine if the given token is part of the given node's dart doc.
  static Comment _getContainingDocComment(AstNode node, Token token) {
    if (node is AnnotatedNode) {
      var docComment = node.documentationComment;
      if (docComment != null && docComment.tokens.contains(token)) {
        return docComment;
      }
    }
    return null;
  }

  /// Return the [ParameterElement] that corresponds to the given [argumentNode]
  /// at the given [argumentIndex].
  static ParameterElement _getParameterElement(
    List<ParameterElement> parameters,
    AstNode argumentNode,
    int argumentIndex,
  ) {
    if (argumentNode is NamedExpression) {
      var name = argumentNode.name?.label?.name;
      for (var parameter in parameters) {
        if (parameter.name == name) {
          return parameter;
        }
      }
      return null;
    }

    if (argumentIndex < parameters.length) {
      return parameters[argumentIndex];
    }

    return null;
  }

  /// Determine whether [node] could possibly be the [entity] for a
  /// [CompletionTarget] associated with the given [offset].
  static bool _isCandidateNode(AstNode node, int offset) {
    // If the node's first token is a keyword or identifier, then the node is a
    // candidate entity if its first token is.
    var beginToken = node.beginToken;
    if (beginToken.type.isKeyword || beginToken.type == TokenType.IDENTIFIER) {
      return _isCandidateToken(node, beginToken, offset);
    }

    // Otherwise, the node is a candidate entity only if the offset is before
    // the beginning of the node. This ensures that completions within a token
    // (e.g. inside a literal string or inside a comment) are evaluated within
    // the context of the token itself.
    return offset <= node.offset;
  }

  /// Determine whether [token] could possibly be the [entity] for a
  /// [CompletionTarget] associated with the given [offset].
  static bool _isCandidateToken(AstNode node, Token token, int offset) {
    if (token == null) {
      return false;
    }
    // A token is considered a candidate entity if the cursor offset is (a)
    // before the start of the token, (b) within the token, (c) at the end of
    // the token and the token is a keyword or identifier, or (d) at the
    // location of the token and the token is zero length.
    if (offset < token.end) {
      return true;
    } else if (offset == token.end) {
      return token.type.isKeyword ||
          token.type == TokenType.IDENTIFIER ||
          token.length == 0;
    } else if (!token.isSynthetic) {
      return false;
    }
    // If the current token is synthetic, then check the previous token
    // because it may have been dropped from the parse tree
    var previous = node.findPrevious(token);
    if (previous == null) {
      // support dangling expression completion, where previous may be null.
      return false;
    } else if (offset < previous.end) {
      return true;
    } else if (offset == previous.end) {
      return token.type.isKeyword || previous.type == TokenType.IDENTIFIER;
    } else {
      return false;
    }
  }
}
