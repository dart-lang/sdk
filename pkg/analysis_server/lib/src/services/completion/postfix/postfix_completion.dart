// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/**
 * An enumeration of possible postfix completion kinds.
 */
class DartPostfixCompletion {
  static const NO_TEMPLATE =
      const PostfixCompletionKind('', 'no change', null, null);
  static const ALL_TEMPLATES = const [
    const PostfixCompletionKind("assert", "expr.assert -> assert(expr);",
        isAssertContext, expandAssert),
    const PostfixCompletionKind(
        "fori",
        "limit.fori -> for(var i = 0; i < limit; i++) {}",
        isIntContext,
        expandFori),
    const PostfixCompletionKind(
        "for",
        "values.for -> for(var value in values) {}",
        isIterableContext,
        expandFor),
    const PostfixCompletionKind(
        "iter",
        "values.iter -> for(var value in values) {}",
        isIterableContext,
        expandFor),
    const PostfixCompletionKind(
        "not", "bool.not -> !bool", isBoolContext, expandNegate),
    const PostfixCompletionKind(
        "!", "bool! -> !bool", isBoolContext, expandNegate),
    const PostfixCompletionKind(
        "else", "bool.else -> if (!bool) {}", isBoolContext, expandElse),
    const PostfixCompletionKind(
        "if", "bool.if -> if (bool) {}", isBoolContext, expandIf),
    const PostfixCompletionKind("nn", "expr.nn -> if (expr != null) {}",
        isObjectContext, expandNotNull),
    const PostfixCompletionKind("notnull",
        "expr.notnull -> if (expr != null) {}", isObjectContext, expandNotNull),
    const PostfixCompletionKind("null", "expr.null -> if (expr == null) {}",
        isObjectContext, expandNull),
    const PostfixCompletionKind(
        "par", "expr.par -> (expr)", isObjectContext, expandParen),
    const PostfixCompletionKind(
        "return", "expr.return -> return expr", isObjectContext, expandReturn),
    const PostfixCompletionKind("switch", "expr.switch -> switch (expr) {}",
        isSwitchContext, expandSwitch),
    const PostfixCompletionKind("try", "stmt.try -> try {stmt} catch (e,s) {}",
        isStatementContext, expandTry),
    const PostfixCompletionKind(
        "tryon",
        "stmt.try -> try {stmt} on Exception catch (e,s) {}",
        isStatementContext,
        expandTryon),
    const PostfixCompletionKind(
        "while", "expr.while -> while (expr) {}", isBoolContext, expandWhile),
  ];

  static Future<PostfixCompletion> expandAssert(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findAssertExpression, (expr) {
      return "assert(${processor.utils.getNodeText(expr)});";
    }, withBraces: false);
  }

  static Future<PostfixCompletion> expandElse(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findBoolExpression,
        (expr) => "if (${processor.makeNegatedBoolExpr(expr)})");
  }

  static Future<PostfixCompletion> expandFor(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findIterableExpression, (expr) {
      String value = processor.newVariable("value");
      return "for (var $value in ${processor.utils.getNodeText(expr)})";
    });
  }

  static Future<PostfixCompletion> expandFori(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findIntExpression, (expr) {
      String index = processor.newVariable("i");
      return "for (int $index = 0; $index < ${processor.utils.getNodeText(
          expr)}; $index++)";
    });
  }

  static Future<PostfixCompletion> expandIf(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findBoolExpression,
        (expr) => "if (${processor.utils.getNodeText(expr)})");
  }

  static Future<PostfixCompletion> expandNegate(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findBoolExpression,
        (expr) => processor.makeNegatedBoolExpr(expr),
        withBraces: false);
  }

  static Future<PostfixCompletion> expandNotNull(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression, (expr) {
      return expr is NullLiteral
          ? "if (false)"
          : "if (${processor.utils.getNodeText(expr)} != null)";
    });
  }

  static Future<PostfixCompletion> expandNull(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression, (expr) {
      return expr is NullLiteral
          ? "if (true)"
          : "if (${processor.utils.getNodeText(expr)} == null)";
    });
  }

  static Future<PostfixCompletion> expandParen(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression,
        (expr) => "(${processor.utils.getNodeText(expr)})",
        withBraces: false);
  }

  static Future<PostfixCompletion> expandReturn(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression,
        (expr) => "return ${processor.utils.getNodeText(expr)};",
        withBraces: false);
  }

  static Future<PostfixCompletion> expandSwitch(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression,
        (expr) => "switch (${processor.utils.getNodeText(expr)})");
  }

  static Future<PostfixCompletion> expandTry(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expandTry(kind, processor.findStatement, withOn: false);
  }

  static Future<PostfixCompletion> expandTryon(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expandTry(kind, processor.findStatement, withOn: true);
  }

  static Future<PostfixCompletion> expandWhile(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findBoolExpression,
        (expr) => "while (${processor.utils.getNodeText(expr)})");
  }

  static PostfixCompletionKind forKey(String key) =>
      ALL_TEMPLATES.firstWhere((kind) => kind.key == key, orElse: () => null);

  static bool isAssertContext(PostfixCompletionProcessor processor) {
    return processor.findAssertExpression() != null;
  }

  static bool isBoolContext(PostfixCompletionProcessor processor) {
    return processor.findBoolExpression() != null;
  }

  static bool isIntContext(PostfixCompletionProcessor processor) {
    return processor.findIntExpression() != null;
  }

  static bool isIterableContext(PostfixCompletionProcessor processor) {
    return processor.findIterableExpression() != null;
  }

  static bool isObjectContext(PostfixCompletionProcessor processor) {
    return processor.findObjectExpression() != null;
  }

  static bool isStatementContext(PostfixCompletionProcessor processor) {
    return processor.findStatement() != null;
  }

  static bool isSwitchContext(PostfixCompletionProcessor processor) {
    return processor.findObjectExpression() != null;
  }
}

/**
 * A description of a postfix completion.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PostfixCompletion {
  /**
   * A description of the assist being proposed.
   */
  final PostfixCompletionKind kind;

  /**
   * The change to be made in order to apply the assist.
   */
  final SourceChange change;

  /**
   * Initialize a newly created completion to have the given [kind] and [change].
   */
  PostfixCompletion(this.kind, this.change);
}

/**
 * The context for computing a postfix completion.
 */
class PostfixCompletionContext {
  final String file;
  final LineInfo lineInfo;
  final int selectionOffset;
  final String key;
  final AnalysisDriver driver;
  final CompilationUnit unit;
  final CompilationUnitElement unitElement;
  final List<engine.AnalysisError> errors;

  PostfixCompletionContext(this.file, this.lineInfo, this.selectionOffset,
      this.key, this.driver, this.unit, this.unitElement, this.errors) {
    if (unitElement.context == null) {
      throw new Error(); // not reached
    }
  }
}

/**
 * A description of a template for postfix completion. Instances are intended to
 * hold the functions required to determine applicability and expand the
 * template, in addition to its name and simple example. The example is shown
 * (in IntelliJ) in a code-completion menu, so must be quite short.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PostfixCompletionKind {
  final String name, example;
  final Function selector;
  final Function computer;

  const PostfixCompletionKind(
      this.name, this.example, this.selector, this.computer);

  String get key => name == '!' ? name : '.$name';

  String get message => 'Expand $key';

  @override
  String toString() => name;
}

/**
 * The computer for Dart postfix completions.
 */
class PostfixCompletionProcessor {
  static final NO_COMPLETION = new PostfixCompletion(
      DartPostfixCompletion.NO_TEMPLATE, new SourceChange("", edits: []));

  final PostfixCompletionContext completionContext;
  final CorrectionUtils utils;
  AstNode node;
  PostfixCompletion completion;
  SourceChange change = new SourceChange('postfix-completion');
  final Map<String, LinkedEditGroup> linkedPositionGroups =
      <String, LinkedEditGroup>{};
  Position exitPosition = null;
  TypeProvider _typeProvider;

  PostfixCompletionProcessor(this.completionContext)
      : utils = new CorrectionUtils(completionContext.unit);

  AnalysisDriver get driver => completionContext.driver;

  String get eol => utils.endOfLine;

  String get file => completionContext.file;

  String get key => completionContext.key;

  LineInfo get lineInfo => completionContext.lineInfo;

  int get requestLine => lineInfo.getLocation(selectionOffset).lineNumber;

  int get selectionOffset => completionContext.selectionOffset;

  /**
   * Return the analysis session to be used to create the change builder.
   */
  AnalysisSession get session => driver.currentSession;

  Source get source => completionContext.unitElement.source;

  TypeProvider get typeProvider {
    return _typeProvider ??= unitElement.context.typeProvider;
  }

  CompilationUnit get unit => completionContext.unit;

  CompilationUnitElement get unitElement => completionContext.unitElement;

  Future<PostfixCompletion> compute() async {
    node = _selectedNode();
    if (node == null) {
      return NO_COMPLETION;
    }
    PostfixCompletionKind completer = DartPostfixCompletion.forKey(key);
    return completer?.computer(this, completer) ?? NO_COMPLETION;
  }

  Future<PostfixCompletion> expand(
      PostfixCompletionKind kind, Function contexter, Function sourcer,
      {bool withBraces: true}) async {
    AstNode expr = contexter();
    if (expr == null) {
      return null;
    }

    DartChangeBuilder changeBuilder = new DartChangeBuilder(session);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      builder.addReplacement(range.node(expr), (DartEditBuilder builder) {
        String newSrc = sourcer(expr);
        if (newSrc == null) {
          return null;
        }
        builder.write(newSrc);
        if (withBraces) {
          builder.write(" {");
          builder.write(eol);
          String indent = utils.getNodePrefix(expr);
          builder.write(indent);
          builder.write(utils.getIndent(1));
          builder.selectHere();
          builder.write(eol);
          builder.write(indent);
          builder.write("}");
        } else {
          builder.selectHere();
        }
      });
    });
    _setCompletionFromBuilder(changeBuilder, kind);
    return completion;
  }

  Future<PostfixCompletion> expandTry(
      PostfixCompletionKind kind, Function contexter,
      {bool withOn: false}) async {
    AstNode stmt = contexter();
    if (stmt == null) {
      return null;
    }
    DartChangeBuilder changeBuilder = new DartChangeBuilder(session);
    await changeBuilder.addFileEdit(file, (DartFileEditBuilder builder) {
      // Embed the full line(s) of the statement in the try block.
      var startLine = lineInfo.getLocation(stmt.offset).lineNumber - 1;
      var endLine = lineInfo.getLocation(stmt.end).lineNumber - 1;
      if (stmt is ExpressionStatement && !stmt.semicolon.isSynthetic) {
        endLine += 1;
      }
      var startOffset = lineInfo.getOffsetOfLine(startLine);
      var endOffset = lineInfo.getOffsetOfLine(endLine);
      var src = utils.getText(startOffset, endOffset - startOffset);
      String indent = utils.getLinePrefix(stmt.offset);
      builder.addReplacement(range.startOffsetEndOffset(startOffset, endOffset),
          (DartEditBuilder builder) {
        builder.write(indent);
        builder.write('try {');
        builder.write(eol);
        builder.write(src.replaceAll(new RegExp("^$indent", multiLine: true),
            "$indent${utils.getIndent(1)}"));
        builder.selectHere();
        builder.write(indent);
        builder.write('}');
        if (withOn) {
          builder.write(' on ');
          builder.addSimpleLinkedEdit('NAME', nameOfExceptionThrownBy(stmt));
        }
        builder.write(' catch (e, s) {');
        builder.write(eol);
        builder.write(indent);
        builder.write(utils.getIndent(1));
        builder.write('print(s);');
        builder.write(eol);
        builder.write(indent);
        builder.write("}");
        builder.write(eol);
      });
    });
    _setCompletionFromBuilder(changeBuilder, kind);
    return completion;
  }

  Expression findAssertExpression() {
    if (node is Expression) {
      Expression boolExpr = _findOuterExpression(node, typeProvider.boolType);
      if (boolExpr == null) {
        return null;
      }
      if (boolExpr.parent is ExpressionFunctionBody &&
          boolExpr.parent.parent is FunctionExpression) {
        FunctionExpression fnExpr = boolExpr.parent.parent;
        var type = fnExpr.bestType;
        if (type is! FunctionType) {
          return boolExpr;
        }
        FunctionType fnType = type;
        if (fnType.returnType == typeProvider.boolType) {
          return fnExpr;
        }
      }
      if (boolExpr.bestType == typeProvider.boolType) {
        return boolExpr;
      }
    }
    return null;
  }

  Expression findBoolExpression() =>
      _findOuterExpression(node, typeProvider.boolType);

  Expression findIntExpression() =>
      _findOuterExpression(node, typeProvider.intType);

  Expression findIterableExpression() =>
      _findOuterExpression(node, typeProvider.iterableType);

  Expression findObjectExpression() =>
      _findOuterExpression(node, typeProvider.objectType);

  AstNode findStatement() {
    var astNode = node;
    while (astNode != null) {
      if (astNode is Statement && astNode is! Block) {
        // Disallow control-flow statements.
        if (astNode is DoStatement ||
            astNode is IfStatement ||
            astNode is ForEachStatement ||
            astNode is ForStatement ||
            astNode is SwitchStatement ||
            astNode is TryStatement ||
            astNode is WhileStatement) {
          return null;
        }
        return astNode;
      }
      astNode = astNode.parent;
    }
    return null;
  }

  Future<bool> isApplicable() async {
    node = _selectedNode();
    if (node == null) {
      return false;
    }
    PostfixCompletionKind completer = DartPostfixCompletion.forKey(key);
    return completer?.selector(this);
  }

  String makeNegatedBoolExpr(Expression expr) {
    String originalSrc = utils.getNodeText(expr);
    String newSrc = utils.invertCondition(expr);
    if (newSrc != originalSrc) {
      return newSrc;
    } else {
      return "!${utils.getNodeText(expr)}";
    }
  }

  String nameOfExceptionThrownBy(AstNode astNode) {
    if (astNode is ExpressionStatement) {
      astNode = (astNode as ExpressionStatement).expression;
    }
    if (astNode is ThrowExpression) {
      ThrowExpression expr = astNode;
      var type = expr.expression.bestType;
      return type.displayName;
    }
    return 'Exception';
  }

  String newVariable(String base) {
    String name = base;
    int i = 1;
    Set<String> vars =
        utils.findPossibleLocalVariableConflicts(selectionOffset);
    while (vars.contains(name)) {
      name = "$base${i++}";
    }
    return name;
  }

  Expression _findOuterExpression(AstNode start, InterfaceType builtInType) {
    AstNode parent;
    if (start is Expression) {
      parent = start;
    } else if (start is ArgumentList) {
      parent = start.parent;
    }
    if (parent == null) {
      return null;
    }
    var list = <Expression>[];
    while (parent is Expression) {
      list.add(parent);
      parent = parent.parent;
    }
    Expression expr = list.firstWhere((expr) {
      DartType type = expr.bestType;
      if (type.isSubtypeOf(builtInType)) return true;
      Element element = type.element;
      if (element is TypeDefiningElement) {
        TypeDefiningElement typeDefElem = element;
        type = typeDefElem.type;
        if (type is ParameterizedType) {
          ParameterizedType pType = type;
          type = pType.instantiate(new List.filled(
              pType.typeParameters.length, typeProvider.dynamicType));
        }
      }
      return type.isSubtypeOf(builtInType);
    }, orElse: () => null);
    if (expr is SimpleIdentifier && expr.parent is PropertyAccess) {
      expr = expr.parent;
    }
    if (expr?.parent is CascadeExpression) {
      expr = expr.parent;
    }
    return expr;
  }

  AstNode _selectedNode({int at: null}) =>
      new NodeLocator(at == null ? selectionOffset : at).searchWithin(unit);

  void _setCompletionFromBuilder(
      DartChangeBuilder builder, PostfixCompletionKind kind,
      [List args]) {
    SourceChange change = builder.sourceChange;
    if (change.edits.isEmpty) {
      completion = null;
      return;
    }
    change.message = formatList(kind.message, args);
    completion = new PostfixCompletion(kind, change);
  }
}
