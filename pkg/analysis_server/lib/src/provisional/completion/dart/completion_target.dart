// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.provisional.completion.dart.completion_target;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

int _computeArgIndex(AstNode containingNode, Object entity) {
  var argList = containingNode;
  if (argList is NamedExpression) {
    entity = argList;
    argList = argList.parent;
  }
  if (argList is ArgumentList) {
    NodeList<Expression> args = argList.arguments;
    for (int index = 0; index < args.length; ++index) {
      if (entity == args[index]) {
        return index;
      }
    }
    if (args.isEmpty) {
      return 0;
    }
    if (entity == argList.rightParenthesis) {
      // Parser ignores trailing commas
      if (argList.rightParenthesis.previous?.lexeme == ',') {
        return args.length;
      }
      return args.length - 1;
    }
  }
  return null;
}

/**
 * A CompletionTarget represents an edge in the parse tree which connects an
 * AST node (the [containingNode] of the completion) to one of its children
 * (the [entity], which represents the place in the parse tree where the newly
 * completed text will be inserted).
 *
 * To illustrate, consider the following snippet of code, and its associated
 * parse tree.  (T's represent tokens, N's represent AST nodes.  Some trivial
 * AST nodes are not shown).
 *
 *            ___N        (function declaration)
 *           /    \
 *          /    __N_______  (function body)
 *         /    /  |a      \
 *        /    /   N______  \  (statement)
 *       /    /   /       \  \
 *      /    /   N____     \  \  (assignment expression)
 *     |    /   /|    \     \  \
 *     .   |   / |    _N___  \  |  ("as" expression)
 *     .   |  |  |   / |   \c | |
 *     .   |  N  |  N  |b   N | |  (simple identifiers)
 *         |  |  |  |  |    | | |
 *         T  T  T  T  T    T T T
 *     m() { foo = bar as  Baz; }
 *
 * The Completion target is usually placed as high in the tree as possible so
 * that we can produce the most meaningful completions with minimal effort.
 * For instance, if the cursor is inside the identifier "foo", the completion
 * target will be the edge marked "a", so that we will produce all completions
 * that could possibly start a statement, even those which would conflict with
 * the current parse (such as the keyword "for", which begins a "for"
 * statement).  As a consequence of this, the [entity] will usually not be the
 * first child of the [containingNode] node.
 *
 * Note that the [containingNode] is always an AST node, but the [entity] may
 * not be.  For instance, if the cursor is inside the keyword "as", the
 * completion target will be the edge marked "b", so the [entity] is the token
 * "as".
 *
 * If the cursor is between tokens, the completion target is usually associated
 * with the token that follows the cursor (since that's the token that will be
 * displaced when the new text is inserted).  For example, if the cursor is
 * after the "{" character, then the completion target will be the edge marked
 * "a", just as it is if the cursor is inside the identifier "foo".  However
 * there is one exception: if the cursor is at the rightmost edge of a keyword
 * or identifier, then the completion target is associated with that token,
 * since any further letters typed will change the meaning of the identifier or
 * keyword, rather than creating a new token.  So for instance, if the cursor
 * is just after the "s" of "as", the completion target will be the edge marked
 * "b", but if the cursor target is after the first space following "as", then
 * the completion target will be the edge marked "c".
 *
 * If the file is empty, or the cursor is after all the text in the file, then
 * there may be no edge in the parse tree which is appropriate to act as the
 * completion target; in this case, [entity] is set to null and
 * [containingNode] is set to the CompilationUnit.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionTarget {
  /**
   * The compilation unit in which the completion is occurring.
   */
  final CompilationUnit unit;

  /**
   * The offset within the source at which the completion is being requested.
   */
  final int offset;

  /**
   * The context in which the completion is occurring.  This is the AST node
   * which is a direct parent of [entity].
   */
  final AstNode containingNode;

  /**
   * The entity which the completed text will replace (or which will be
   * displaced once the completed text is inserted).  This may be an AstNode or
   * a Token, or it may be null if the cursor is after all tokens in the file.
   *
   * Usually, the entity won't be the first child of the [containingNode] (this
   * is a consequence of placing the completion target as high in the tree as
   * possible).  However, there is one exception: when the cursor is inside of
   * a multi-character token which is not a keyword or identifier (e.g. a
   * comment, or a token like "+=", the entity will be always be the token.
   */
  final Object entity;

  /**
   * The [entity] is a comment token, which is either not a documentation
   * comment or the position is not in a [CommentReference].
   */
  final bool isCommentText;

  /**
   * If the target is an argument in an [ArgumentList], then this is the index
   * of the argument in the list, otherwise this is `null`.
   */
  final int argIndex;

  /**
   * Compute the appropriate [CompletionTarget] for the given [offset] within
   * the [compilationUnit].
   *
   * Optionally, start the search from within [entryPoint] instead of using
   * the [compilationUnit], which is useful for analyzing ASTs that have no
   * [compilationUnit] such as dart expressions within angular templates.
   */
  factory CompletionTarget.forOffset(
      CompilationUnit compilationUnit, int offset,
      {AstNode entryPoint}) {
    // The precise algorithm is as follows.  We perform a depth-first search of
    // all edges in the parse tree (both those that point to AST nodes and
    // those that point to tokens), visiting parents before children.  The
    // first edge which points to an entity satisfying either _isCandidateToken
    // or _isCandidateNode is the completion target.  If no edge is found that
    // satisfies these two predicates, then we set the completion target entity
    // to null and the containingNode to the entryPoint.
    //
    // Note that if a token is not a candidate target, then none of the tokens
    // that precede it are candidate targets either.  Therefore any entity
    // whose last token is not a candidate target can be skipped.  This lets us
    // prune the search to the point where no recursion is necessary; at each
    // step in the process we know exactly which child node we need to proceed
    // to.
    entryPoint ??= compilationUnit;
    AstNode containingNode = entryPoint;
    outerLoop:
    while (true) {
      if (containingNode is Comment) {
        // Comments are handled specially: we descend into any CommentReference
        // child node that contains the cursor offset.
        Comment comment = containingNode;
        for (CommentReference commentReference in comment.references) {
          if (commentReference.offset <= offset &&
              offset <= commentReference.end) {
            containingNode = commentReference;
            continue outerLoop;
          }
        }
      }
      for (var entity in containingNode.childEntities) {
        if (entity is Token) {
          if (_isCandidateToken(entity, offset)) {
            // Try to replace with a comment token.
            Token commentToken = _getContainingCommentToken(entity, offset);
            if (commentToken != null) {
              return new CompletionTarget._(
                  compilationUnit, offset, containingNode, commentToken, true);
            }
            // Target found.
            return new CompletionTarget._(
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
          if (!_isCandidateToken(entity.endToken, offset)) {
            continue;
          }

          // If the node is a candidate target, then we are done.
          if (_isCandidateNode(entity, offset)) {
            // Check to see if the offset is in a preceding comment
            Token commentToken =
                _getContainingCommentToken(entity.beginToken, offset);
            if (commentToken != null) {
              // If the preceding comment is dartdoc token, then update
              // the containing node to be the dartdoc comment.
              // Otherwise completion is not required.
              Comment docComment =
                  _getContainingDocComment(containingNode, commentToken);
              if (docComment != null) {
                return new CompletionTarget._(
                    compilationUnit, offset, docComment, commentToken, false);
              } else {
                return new CompletionTarget._(compilationUnit, offset,
                    compilationUnit, commentToken, true);
              }
            }
            return new CompletionTarget._(
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

      // No completion target found.  It should only be possible to reach here
      // the first time through the outer loop (since we only jump to the start
      // of the outer loop after determining that the completion target is
      // inside an entity).  We can check that assumption by verifying that
      // containingNode is still the entryPoint.
      assert(identical(containingNode, entryPoint));

      // Since no completion target was found, we set the completion target
      // entity to null and use the entryPoint as the parent.
      return new CompletionTarget._(
          compilationUnit, offset, entryPoint, null, false);
    }
  }

  /**
   * Create a [CompletionTarget] holding the given [containingNode] and
   * [entity].
   */
  CompletionTarget._(this.unit, this.offset, AstNode containingNode,
      Object entity, this.isCommentText)
      : this.containingNode = containingNode,
        this.entity = entity,
        this.argIndex = _computeArgIndex(containingNode, entity);

  /**
   * Return `true` if the [containingNode] is a cascade
   * and the completion insertion is not between the two dots.
   * For example, `..d^` and `..^d` are considered a cascade
   * from a completion standpoint, but `.^.d` is not.
   */
  bool get isCascade {
    AstNode node = containingNode;
    if (node is PropertyAccess) {
      return node.isCascaded && offset > node.operator.offset + 1;
    }
    if (node is MethodInvocation) {
      return node.isCascaded && offset > node.operator.offset + 1;
    }
    return false;
  }

  /**
   * Return `true` if the target is a functional argument in an argument list.
   * The target [AstNode] hierarchy *must* be resolved for this to work.
   * See [maybeFunctionalArgument].
   */
  bool isFunctionalArgument() {
    if (!maybeFunctionalArgument()) {
      return false;
    }
    AstNode parent = containingNode.parent;
    if (parent is ArgumentList) {
      parent = parent.parent;
    }
    if (parent is InstanceCreationExpression) {
      DartType instType = parent.bestType;
      if (instType != null) {
        Element intTypeElem = instType.element;
        if (intTypeElem is ClassElement) {
          SimpleIdentifier constructorName = parent.constructorName.name;
          ConstructorElement constructor = constructorName != null
              ? intTypeElem.getNamedConstructor(constructorName.name)
              : intTypeElem.unnamedConstructor;
          return constructor != null &&
              _isFunctionalParameter(
                  constructor.parameters, argIndex, containingNode);
        }
      }
    } else if (parent is MethodInvocation) {
      SimpleIdentifier methodName = parent.methodName;
      if (methodName != null) {
        Element methodElem = methodName.bestElement;
        if (methodElem is MethodElement) {
          return _isFunctionalParameter(
              methodElem.parameters, argIndex, containingNode);
        } else if (methodElem is FunctionElement) {
          return _isFunctionalParameter(
              methodElem.parameters, argIndex, containingNode);
        }
      }
    }
    return false;
  }

  /**
   * Return `true` if the target maybe a functional argument in an argument list.
   * This is used in determining whether the target [AstNode] hierarchy
   * needs to be resolved so that [isFunctionalArgument] will work.
   */
  bool maybeFunctionalArgument() {
    if (argIndex != null) {
      if (containingNode is ArgumentList) {
        return true;
      }
      if (containingNode is NamedExpression) {
        if (containingNode.parent is ArgumentList) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Determine if the offset is contained in a preceding comment token
   * and return that token, otherwise return `null`.
   */
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

  /**
   * Determine if the given token is part of the given node's dart doc.
   */
  static Comment _getContainingDocComment(AstNode node, Token token) {
    if (node is AnnotatedNode) {
      Comment docComment = node.documentationComment;
      if (docComment != null && docComment.tokens.contains(token)) {
        return docComment;
      }
    }
    return null;
  }

  /**
   * Determine whether [node] could possibly be the [entity] for a
   * [CompletionTarget] associated with the given [offset].
   */
  static bool _isCandidateNode(AstNode node, int offset) {
    // If the node's first token is a keyword or identifier, then the node is a
    // candidate entity if its first token is.
    Token beginToken = node.beginToken;
    if (beginToken.type == TokenType.KEYWORD ||
        beginToken.type == TokenType.IDENTIFIER) {
      return _isCandidateToken(beginToken, offset);
    }

    // Otherwise, the node is a candidate entity only if the offset is before
    // the beginning of the node.  This ensures that completions within a token
    // (e.g. inside a literal string or inside a comment) are evaluated within
    // the context of the token itself.
    return offset <= node.offset;
  }

  /**
   * Determine whether [token] could possibly be the [entity] for a
   * [CompletionTarget] associated with the given [offset].
   */
  static bool _isCandidateToken(Token token, int offset) {
    // A token is considered a candidate entity if the cursor offset is (a)
    // before the start of the token, (b) within the token, (c) at the end of
    // the token and the token is a keyword or identifier, or (d) at the
    // location of the token and the token is zero length.
    if (offset < token.end) {
      return true;
    } else if (offset == token.end) {
      return token.type == TokenType.KEYWORD ||
          token.type == TokenType.IDENTIFIER ||
          token.length == 0;
    } else if (!token.isSynthetic) {
      return false;
    }
    // If the current token is synthetic, then check the previous token
    // because it may have been dropped from the parse tree
    Token previous = token.previous;
    if (offset < previous.end) {
      return true;
    } else if (offset == previous.end) {
      return token.type == TokenType.KEYWORD ||
          previous.type == TokenType.IDENTIFIER;
    } else {
      return false;
    }
  }

  /**
   * Return `true` if the parameter is a functional parameter.
   */
  static bool _isFunctionalParameter(List<ParameterElement> parameters,
      int paramIndex, AstNode containingNode) {
    DartType paramType;
    if (paramIndex < parameters.length) {
      ParameterElement param = parameters[paramIndex];
      if (param.parameterKind == ParameterKind.NAMED) {
        if (containingNode is NamedExpression) {
          String name = containingNode.name?.label?.name;
          param = parameters.firstWhere(
              (ParameterElement param) =>
                  param.parameterKind == ParameterKind.NAMED &&
                  param.name == name,
              orElse: () => null);
          paramType = param?.type;
        }
      } else {
        paramType = param.type;
      }
    }
    return paramType is FunctionType || paramType is FunctionTypeAlias;
  }
}
