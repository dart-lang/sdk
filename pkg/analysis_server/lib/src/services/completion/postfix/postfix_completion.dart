// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// An enumeration of possible postfix completion kinds.
class DartPostfixCompletion {
  static const NO_TEMPLATE = PostfixCompletionKind('', 'no change', null, null);

  static const List<PostfixCompletionKind> ALL_TEMPLATES = [
    PostfixCompletionKind('assert', 'expr.assert -> assert(expr);',
        isAssertContext, expandAssert),
    PostfixCompletionKind(
        'fori',
        'limit.fori -> for(var i = 0; i < limit; i++) {}',
        isIntContext,
        expandFori),
    PostfixCompletionKind('for', 'values.for -> for(var value in values) {}',
        isIterableContext, expandFor),
    PostfixCompletionKind('iter', 'values.iter -> for(var value in values) {}',
        isIterableContext, expandFor),
    PostfixCompletionKind(
        'not', 'bool.not -> !bool', isBoolContext, expandNegate),
    PostfixCompletionKind('!', 'bool! -> !bool', isBoolContext, expandNegate),
    PostfixCompletionKind(
        'else', 'bool.else -> if (!bool) {}', isBoolContext, expandElse),
    PostfixCompletionKind(
        'if', 'bool.if -> if (bool) {}', isBoolContext, expandIf),
    PostfixCompletionKind('nn', 'expr.nn -> if (expr != null) {}',
        isObjectContext, expandNotNull),
    PostfixCompletionKind('notnull', 'expr.notnull -> if (expr != null) {}',
        isObjectContext, expandNotNull),
    PostfixCompletionKind('null', 'expr.null -> if (expr == null) {}',
        isObjectContext, expandNull),
    PostfixCompletionKind(
        'par', 'expr.par -> (expr)', isObjectContext, expandParen),
    PostfixCompletionKind(
        'return', 'expr.return -> return expr', isObjectContext, expandReturn),
    PostfixCompletionKind('switch', 'expr.switch -> switch (expr) {}',
        isSwitchContext, expandSwitch),
    PostfixCompletionKind('try', 'stmt.try -> try {stmt} catch (e,s) {}',
        isStatementContext, expandTry),
    PostfixCompletionKind(
        'tryon',
        'stmt.try -> try {stmt} on Exception catch (e,s) {}',
        isStatementContext,
        expandTryon),
    PostfixCompletionKind(
        'while', 'expr.while -> while (expr) {}', isBoolContext, expandWhile),
  ];

  static Future<PostfixCompletion> expandAssert(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findAssertExpression, (expr) {
      return 'assert(${processor.utils.getNodeText(expr)});';
    }, withBraces: false);
  }

  static Future<PostfixCompletion> expandElse(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findBoolExpression,
        (expr) => 'if (${processor.makeNegatedBoolExpr(expr)})');
  }

  static Future<PostfixCompletion> expandFor(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findIterableExpression, (expr) {
      var value = processor.newVariable('value');
      return 'for (var $value in ${processor.utils.getNodeText(expr)})';
    });
  }

  static Future<PostfixCompletion> expandFori(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findIntExpression, (expr) {
      var index = processor.newVariable('i');
      return 'for (int $index = 0; $index < ${processor.utils.getNodeText(expr)}; $index++)';
    });
  }

  static Future<PostfixCompletion> expandIf(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findBoolExpression,
        (expr) => 'if (${processor.utils.getNodeText(expr)})');
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
          ? 'if (false)'
          : 'if (${processor.utils.getNodeText(expr)} != null)';
    });
  }

  static Future<PostfixCompletion> expandNull(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression, (expr) {
      return expr is NullLiteral
          ? 'if (true)'
          : 'if (${processor.utils.getNodeText(expr)} == null)';
    });
  }

  static Future<PostfixCompletion> expandParen(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression,
        (expr) => '(${processor.utils.getNodeText(expr)})',
        withBraces: false);
  }

  static Future<PostfixCompletion> expandReturn(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression,
        (expr) => 'return ${processor.utils.getNodeText(expr)};',
        withBraces: false);
  }

  static Future<PostfixCompletion> expandSwitch(
      PostfixCompletionProcessor processor, PostfixCompletionKind kind) async {
    return processor.expand(kind, processor.findObjectExpression,
        (expr) => 'switch (${processor.utils.getNodeText(expr)})');
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
        (expr) => 'while (${processor.utils.getNodeText(expr)})');
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

/// A description of a postfix completion.
///
/// Clients may not extend, implement or mix-in this class.
class PostfixCompletion {
  /// A description of the assist being proposed.
  final PostfixCompletionKind kind;

  /// The change to be made in order to apply the assist.
  final SourceChange change;

  /// Initialize a newly created completion to have the given [kind] and
  /// [change].
  PostfixCompletion(this.kind, this.change);
}

/// The context for computing a postfix completion.
class PostfixCompletionContext {
  final ResolvedUnitResult resolveResult;
  final int selectionOffset;
  final String key;

  PostfixCompletionContext(this.resolveResult, this.selectionOffset, this.key);
}

/// A description of a template for postfix completion. Instances are intended
/// to hold the functions required to determine applicability and expand the
/// template, in addition to its name and simple example. The example is shown
/// (in IntelliJ) in a code-completion menu, so must be quite short.
///
/// Clients may not extend, implement or mix-in this class.
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

/// The computer for Dart postfix completions.
class PostfixCompletionProcessor {
  static final NO_COMPLETION = PostfixCompletion(
      DartPostfixCompletion.NO_TEMPLATE, SourceChange('', edits: []));

  final PostfixCompletionContext completionContext;
  final CorrectionUtils utils;
  AstNode node;
  PostfixCompletion completion;
  SourceChange change = SourceChange('postfix-completion');
  final Map<String, LinkedEditGroup> linkedPositionGroups = {};
  Position exitPosition;

  PostfixCompletionProcessor(this.completionContext)
      : utils = CorrectionUtils(completionContext.resolveResult);

  String get eol => utils.endOfLine;

  String get file => completionContext.resolveResult.path;

  String get key => completionContext.key;

  LineInfo get lineInfo => completionContext.resolveResult.lineInfo;

  int get selectionOffset => completionContext.selectionOffset;

  AnalysisSession get session => completionContext.resolveResult.session;

  TypeProvider get typeProvider => completionContext.resolveResult.typeProvider;

  TypeSystem get typeSystem => completionContext.resolveResult.typeSystem;

  Future<PostfixCompletion> compute() async {
    node = _selectedNode();
    if (node == null) {
      return NO_COMPLETION;
    }
    var completer = DartPostfixCompletion.forKey(key);
    return completer?.computer(this, completer) ?? NO_COMPLETION;
  }

  Future<PostfixCompletion> expand(
      PostfixCompletionKind kind, Function contexter, Function sourcer,
      {bool withBraces = true}) async {
    AstNode expr = contexter();
    if (expr == null) {
      return null;
    }

    var changeBuilder = ChangeBuilder(session: session);
    await changeBuilder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(expr), (builder) {
        String newSrc = sourcer(expr);
        if (newSrc == null) {
          return null;
        }
        builder.write(newSrc);
        if (withBraces) {
          builder.write(' {');
          builder.write(eol);
          var indent = utils.getNodePrefix(expr);
          builder.write(indent);
          builder.write(utils.getIndent(1));
          builder.selectHere();
          builder.write(eol);
          builder.write(indent);
          builder.write('}');
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
      {bool withOn = false}) async {
    AstNode stmt = contexter();
    if (stmt == null) {
      return null;
    }
    var changeBuilder = ChangeBuilder(session: session);
    await changeBuilder.addDartFileEdit(file, (builder) {
      // Embed the full line(s) of the statement in the try block.
      var startLine = lineInfo.getLocation(stmt.offset).lineNumber - 1;
      var endLine = lineInfo.getLocation(stmt.end).lineNumber - 1;
      if (stmt is ExpressionStatement && !stmt.semicolon.isSynthetic) {
        endLine += 1;
      }
      var startOffset = lineInfo.getOffsetOfLine(startLine);
      var endOffset = lineInfo.getOffsetOfLine(endLine);
      var src = utils.getText(startOffset, endOffset - startOffset);
      var indent = utils.getLinePrefix(stmt.offset);
      builder.addReplacement(range.startOffsetEndOffset(startOffset, endOffset),
          (builder) {
        builder.write(indent);
        builder.write('try {');
        builder.write(eol);
        builder.write(src.replaceAll(RegExp('^$indent', multiLine: true),
            '$indent${utils.getIndent(1)}'));
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
        builder.write('}');
        builder.write(eol);
      });
    });
    _setCompletionFromBuilder(changeBuilder, kind);
    return completion;
  }

  Expression findAssertExpression() {
    if (node is Expression) {
      var boolExpr = _findOuterExpression(node, typeProvider.boolType);
      if (boolExpr == null) {
        return null;
      }
      if (boolExpr.parent is ExpressionFunctionBody &&
          boolExpr.parent.parent is FunctionExpression) {
        FunctionExpression fnExpr = boolExpr.parent.parent;
        var type = fnExpr.staticType;
        if (type is! FunctionType) {
          return boolExpr;
        }
        FunctionType fnType = type;
        if (fnType.returnType == typeProvider.boolType) {
          return fnExpr;
        }
      }
      if (boolExpr.staticType == typeProvider.boolType) {
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
      _findOuterExpression(node, typeProvider.iterableDynamicType);

  Expression findObjectExpression() =>
      _findOuterExpression(node, typeProvider.objectType);

  AstNode findStatement() {
    var astNode = node;
    while (astNode != null) {
      if (astNode is Statement && astNode is! Block) {
        // Disallow control-flow statements.
        if (astNode is DoStatement ||
            astNode is IfStatement ||
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
    var completer = DartPostfixCompletion.forKey(key);
    return completer?.selector(this);
  }

  String makeNegatedBoolExpr(Expression expr) {
    var originalSrc = utils.getNodeText(expr);
    var newSrc = utils.invertCondition(expr);
    if (newSrc != originalSrc) {
      return newSrc;
    } else {
      return '!${utils.getNodeText(expr)}';
    }
  }

  String nameOfExceptionThrownBy(AstNode astNode) {
    if (astNode is ExpressionStatement) {
      astNode = (astNode as ExpressionStatement).expression;
    }
    if (astNode is ThrowExpression) {
      var expr = astNode;
      var type = expr.expression.staticType;

      // Only print nullability for non-legacy types in non-legacy libraries.
      var showNullability = type.nullabilitySuffix != NullabilitySuffix.star &&
          (astNode.root as CompilationUnit)
              .declaredElement
              .library
              .isNonNullableByDefault;

      // Can't catch nullable types, strip `?`s now that we've checked for `*`s.
      return (type as TypeImpl)
          .withNullability(NullabilitySuffix.none)
          .getDisplayString(withNullability: showNullability);
    }
    return 'Exception';
  }

  String newVariable(String base) {
    var name = base;
    var i = 1;
    var vars = utils.findPossibleLocalVariableConflicts(selectionOffset);
    while (vars.contains(name)) {
      name = '$base${i++}';
    }
    return name;
  }

  Expression _findOuterExpression(AstNode start, InterfaceType builtInType) {
    if (start is SimpleIdentifier && start.staticElement is PrefixElement) {
      return null;
    }

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

    var expr = list.firstWhere((expr) {
      var type = expr.staticType;
      if (type == null) return false;
      return typeSystem.isSubtypeOf(type, builtInType);
    }, orElse: () => null);
    if (expr is SimpleIdentifier && expr.parent is PropertyAccess) {
      expr = expr.parent;
    }
    if (expr?.parent is CascadeExpression) {
      expr = expr.parent;
    }
    return expr;
  }

  AstNode _selectedNode({int at}) => NodeLocator(at ?? selectionOffset)
      .searchWithin(completionContext.resolveResult.unit);

  void _setCompletionFromBuilder(
      ChangeBuilder builder, PostfixCompletionKind kind,
      [List args]) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      completion = null;
      return;
    }
    change.message = formatList(kind.message, args);
    completion = PostfixCompletion(kind, change);
  }
}
