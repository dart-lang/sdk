// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';

typedef _CatchClausesVerifierReporter = void Function(
  CatchClause first,
  CatchClause last,
  ErrorCode,
  List<Object> arguments,
);

/// A visitor that finds dead code, other than unreachable code that is
/// handled in [NullSafetyDeadCodeVerifier].
class DeadCodeVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter by which errors will be reported.
  final ErrorReporter _errorReporter;

  /// The object used to track the usage of labels within a given label scope.
  _LabelTracker? _labelTracker;

  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  DeadCodeVerifier(this._errorReporter, LibraryElement library)
      : _wildCardVariablesEnabled =
            library.featureSet.isEnabled(Feature.wildcard_variables);

  @override
  void visitBreakStatement(BreakStatement node) {
    _labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid.
      LibraryElement? library = exportElement.exportedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitExportDirective(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var element = node.declaredElement;
    // TODO(pq): ask the FunctionElement once implemented
    if (_wildCardVariablesEnabled &&
        element is FunctionElement &&
        element.isLocal &&
        element.name == '_') {
      _errorReporter.atNode(node, WarningCode.DEAD_CODE);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var importElement = node.element;
    if (importElement != null) {
      // The element is null when the URI is invalid, but not when the URI is
      // valid but refers to a nonexistent file.
      LibraryElement? library = importElement.importedLibrary;
      if (library != null && !library.isSynthetic) {
        for (Combinator combinator in node.combinators) {
          _checkCombinator(library, combinator);
        }
      }
    }
    super.visitImportDirective(node);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    _withLabelTracker(node.labels, () {
      super.visitLabeledStatement(node);
    });
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    List<Label> labels = <Label>[];
    for (SwitchMember member in node.members) {
      labels.addAll(member.labels);
    }
    _withLabelTracker(labels, () {
      super.visitSwitchStatement(node);
    });
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var initializer = node.initializer;
    if (initializer != null && node.isLate) {
      var element = node.declaredElement;
      // TODO(pq): ask the LocalVariableElement once implemented
      if (_wildCardVariablesEnabled &&
          element is LocalVariableElement &&
          element.name == '_') {
        _errorReporter.atNode(initializer,
            WarningCode.DEAD_CODE_LATE_WILDCARD_VARIABLE_INITIALIZER);
      }
    }

    super.visitVariableDeclaration(node);
  }

  /// Resolve the names in the given [combinator] in the scope of the given
  /// [library].
  void _checkCombinator(LibraryElement library, Combinator combinator) {
    Namespace namespace =
        NamespaceBuilder().createExportNamespaceForLibrary(library);
    NodeList<SimpleIdentifier> names;
    ErrorCode warningCode;
    if (combinator is HideCombinator) {
      names = combinator.hiddenNames;
      warningCode = WarningCode.UNDEFINED_HIDDEN_NAME;
    } else {
      names = (combinator as ShowCombinator).shownNames;
      warningCode = WarningCode.UNDEFINED_SHOWN_NAME;
    }
    for (SimpleIdentifier name in names) {
      String nameStr = name.name;
      Element? element = namespace.get(nameStr);
      element ??= namespace.get("$nameStr=");
      if (element == null) {
        _errorReporter.atNode(
          name,
          warningCode,
          arguments: [library.identifier, nameStr],
        );
      }
    }
  }

  void _withLabelTracker(List<Label> labels, void Function() f) {
    var labelTracker = _LabelTracker(_labelTracker, labels);
    try {
      _labelTracker = labelTracker;
      f();
    } finally {
      for (Label label in labelTracker.unusedLabels()) {
        _errorReporter.atNode(
          label,
          WarningCode.UNUSED_LABEL,
          arguments: [label.label.name],
        );
      }
      _labelTracker = labelTracker.outerTracker;
    }
  }
}

/// Helper for tracking dead code - [CatchClause]s and unreachable code.
///
/// [CatchClause]s are checked separately, as we visit AST we may make some
/// of them as dead, and record [_deadCatchClauseRanges].
///
/// When an unreachable node is found, and [_firstDeadNode] is `null`, we
/// set [_firstDeadNode], so start a new dead nodes interval. The dead code
/// interval ends when [flowEnd] is invoked with a node that is the start
/// node, or contains it. So, we end the end of the covering control flow.
class NullSafetyDeadCodeVerifier {
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;
  final FlowAnalysisHelper? _flowAnalysis;

  /// The stack of verifiers of (potentially nested) try statements.
  final List<_CatchClausesVerifier> _catchClausesVerifiers = [];

  /// When a sequence [CatchClause]s is found to be dead, we don't want to
  /// report additional dead code inside of already dead code.
  final List<SourceRange> _deadCatchClauseRanges = [];

  /// When this field is `null`, we are in reachable code.
  /// Once we find the first unreachable node, we store it here.
  ///
  /// When this field is not `null`, and we see an unreachable node, this new
  /// node is ignored, because it continues the same dead code range.
  AstNode? _firstDeadNode;

  NullSafetyDeadCodeVerifier(
    this._typeSystem,
    this._errorReporter,
    this._flowAnalysis,
  );

  /// The [node] ends a basic block in the control flow. If [_firstDeadNode] is
  /// not `null`, and is covered by the [node], then we reached the end of
  /// the current dead code interval.
  void flowEnd(AstNode node) {
    // Note that `firstDeadNode` could be a node that will later be replaced
    // in the syntax tree. It's not safe to query whether it is _equal_ to, for
    // example, another node's child.
    // TODO(srawlins): Change this code to avoid this issue.
    var firstDeadNode = _firstDeadNode;
    if (firstDeadNode == null) {
      return;
    }

    if (!_containsFirstDeadNode(node)) {
      return;
    }

    if (node is SwitchMember && node == firstDeadNode) {
      _errorReporter.atToken(
        node.keyword,
        WarningCode.DEAD_CODE,
      );
      _firstDeadNode = null;
      return;
    }

    var parent = firstDeadNode.parent;
    if (parent is Assertion && identical(firstDeadNode, parent.message)) {
      // Don't report "dead code" for the message part of an assert statement,
      // because this causes nuisance warnings for redundant `!= null`
      // asserts.
    } else if (parent is ConstructorDeclaration &&
        firstDeadNode is EmptyFunctionBody) {
      // Don't report "dead code" for an unreachable, but syntacically required,
      // semicolon that follows one or more constructor initializers.
    } else if (parent is ConstructorDeclaration &&
        firstDeadNode is BlockFunctionBody &&
        firstDeadNode.block.statements.isEmpty) {
      // Don't report "dead code" for an unreachable, but empty block body that
      // follows one or more constructor initializers.
    } else {
      var offset = firstDeadNode.offset;
      // We know that [node] is the first dead node, or contains it.
      // So, technically the code interval ends at the end of [node].
      // But we trim it to the last statement for presentation purposes.
      if (node != firstDeadNode) {
        if (node is FunctionDeclaration) {
          node = node.functionExpression.body;
        }
        if (node is FunctionExpression) {
          node = node.body;
        }
        if (node is MethodDeclaration) {
          node = node.body;
        }
        if (node is BlockFunctionBody) {
          node = node.block;
        }
        if (node is Block && node.statements.isNotEmpty) {
          node = node.statements.last;
        }
        if (node is SwitchMember && node.statements.isNotEmpty) {
          node = node.statements.last;
        }
      } else if (parent is BinaryExpression) {
        offset = parent.operator.offset;
      }
      if (parent is ConstructorInitializer) {
        _errorReporter.atOffset(
          offset: parent.offset,
          length: parent.end - parent.offset,
          errorCode: WarningCode.DEAD_CODE,
        );
        offset = node.end;
      } else if (parent is DoStatement) {
        var doOffset = parent.doKeyword.offset;
        var doEnd = parent.doKeyword.end;
        var whileOffset = parent.whileKeyword.offset;
        var whileEnd = parent.semicolon.end;
        var body = parent.body;
        if (body is Block) {
          doEnd = body.leftBracket.end;
          whileOffset = body.rightBracket.offset;
        }
        _errorReporter.atOffset(
          offset: doOffset,
          length: doEnd - doOffset,
          errorCode: WarningCode.DEAD_CODE,
        );
        _errorReporter.atOffset(
          offset: whileOffset,
          length: whileEnd - whileOffset,
          errorCode: WarningCode.DEAD_CODE,
        );
        offset = parent.semicolon.next!.offset;
        if (parent.hasBreakStatement) {
          offset = node.end;
        }
      } else if (parent is ForParts) {
        node = parent.updaters.last;
      } else if (parent is ForStatement) {
        _reportForUpdaters(parent);
      } else if (parent is Block) {
        var grandParent = parent.parent;
        if (grandParent is ForStatement) {
          _reportForUpdaters(grandParent);
        }
      } else if (parent is BinaryExpression) {
        offset = parent.operator.offset;
        node = parent.rightOperand;
      } else if (parent is LogicalOrPattern &&
          firstDeadNode == parent.rightOperand) {
        offset = parent.operator.offset;
      }

      var length = node.end - offset;
      if (length > 0) {
        _errorReporter.atOffset(
          offset: offset,
          length: length,
          errorCode: WarningCode.DEAD_CODE,
        );
      }
    }

    _firstDeadNode = null;
  }

  void tryStatementEnter(TryStatement node) {
    var verifier = _CatchClausesVerifier(
      _typeSystem,
      (first, last, errorCode, arguments) {
        var offset = first.offset;
        var length = last.end - offset;
        _errorReporter.atOffset(
          offset: offset,
          length: length,
          errorCode: errorCode,
          arguments: arguments,
        );
        _deadCatchClauseRanges.add(SourceRange(offset, length));
      },
      node.catchClauses,
    );
    _catchClausesVerifiers.add(verifier);
  }

  void tryStatementExit(TryStatement node) {
    _catchClausesVerifiers.removeLast();
  }

  void verifyCascadeExpression(CascadeExpression node) {
    var first = node.cascadeSections.firstOrNull;
    if (first is PropertyAccess) {
      _verifyUnassignedSimpleIdentifier(node, node.target, first.operator);
    } else if (first is MethodInvocation) {
      _verifyUnassignedSimpleIdentifier(node, node.target, first.operator);
    } else if (first is IndexExpression) {
      _verifyUnassignedSimpleIdentifier(node, node.target, first.period);
    }
  }

  void verifyCatchClause(CatchClause node) {
    var verifier = _catchClausesVerifiers.last;
    if (verifier._done) return;

    verifier.nextCatchClause(node);
  }

  void verifyIndexExpression(IndexExpression node) {
    _verifyUnassignedSimpleIdentifier(node, node.target, node.question);
  }

  void verifyMethodInvocation(MethodInvocation node) {
    _verifyUnassignedSimpleIdentifier(node, node.target, node.operator);
  }

  void verifyPropertyAccess(PropertyAccess node) {
    _verifyUnassignedSimpleIdentifier(node, node.target, node.operator);
  }

  void visitNode(AstNode node) {
    // Comments are visited after bodies of functions.
    // So, they look unreachable, but this does not make sense.
    if (node is Comment) return;

    var flowAnalysis = _flowAnalysis;
    if (flowAnalysis == null) return;
    flowAnalysis.checkUnreachableNode(node);

    // If the first dead node is not `null`, even if this new node is
    // unreachable, we can ignore it as it is part of the same dead code
    // range anyway.
    if (_firstDeadNode != null) return;

    var flow = flowAnalysis.flow;
    if (flow == null) return;

    if (flow.isReachable) return;

    // If in a dead `CatchClause`, no need to report dead code.
    for (var range in _deadCatchClauseRanges) {
      if (range.contains(node.offset)) {
        return;
      }
    }

    _firstDeadNode = node;
  }

  bool _containsFirstDeadNode(AstNode parent) {
    for (var node = _firstDeadNode; node != null; node = node.parent) {
      if (node == parent) return true;
    }
    return false;
  }

  void _reportForUpdaters(ForStatement node) {
    var forParts = node.forLoopParts;
    if (forParts is ForParts) {
      var updaters = forParts.updaters;
      var beginToken = updaters.beginToken;
      var endToken = updaters.endToken;
      if (beginToken != null && endToken != null) {
        _errorReporter.atOffset(
          offset: beginToken.offset,
          length: endToken.end - beginToken.offset,
          errorCode: WarningCode.DEAD_CODE,
        );
      }
    }
  }

  void _verifyUnassignedSimpleIdentifier(
      AstNode node, Expression? target, Token? operator) {
    var flowAnalysis = _flowAnalysis;
    if (flowAnalysis == null) return;

    var operatorType = operator?.type;
    if (operatorType != TokenType.QUESTION &&
        operatorType != TokenType.QUESTION_PERIOD &&
        operatorType != TokenType.QUESTION_PERIOD_PERIOD) {
      return;
    }
    if (target?.staticType?.nullabilitySuffix != NullabilitySuffix.question) {
      return;
    }

    target = target?.unParenthesized;
    if (target is SimpleIdentifier) {
      var element = target.staticElement;
      if (element is PromotableElement &&
          flowAnalysis.isDefinitelyUnassigned(target, element)) {
        var parent = node.parent;
        while (parent is MethodInvocation ||
            parent is PropertyAccess ||
            parent is IndexExpression) {
          node = parent!;
          parent = node.parent;
        }
        _errorReporter.atNode(
          node,
          WarningCode.DEAD_CODE,
        );
      }
    }
  }
}

/// A visitor that finds a [BreakStatement] for a specified [DoStatement].
class _BreakDoStatementVisitor extends RecursiveAstVisitor<void> {
  bool hasBreakStatement = false;
  final DoStatement doStatement;

  _BreakDoStatementVisitor(this.doStatement);

  @override
  void visitBreakStatement(BreakStatement node) {
    if (node.target == doStatement) {
      hasBreakStatement = true;
    }
  }
}

class _CatchClausesVerifier {
  final TypeSystemImpl _typeSystem;
  final _CatchClausesVerifierReporter _errorReporter;
  final List<CatchClause> catchClauses;

  bool _done = false;
  final List<DartType> _visitedTypes = <DartType>[];

  _CatchClausesVerifier(
    this._typeSystem,
    this._errorReporter,
    this.catchClauses,
  );

  void nextCatchClause(CatchClause catchClause) {
    var currentType = catchClause.exceptionType?.type;

    // Found catch clause that doesn't have an exception type.
    // Generate an error on any following catch clauses.
    if (currentType == null || currentType.isDartCoreObject) {
      if (catchClause != catchClauses.last) {
        var index = catchClauses.indexOf(catchClause);
        _errorReporter(
          catchClauses[index + 1],
          catchClauses.last,
          WarningCode.DEAD_CODE_CATCH_FOLLOWING_CATCH,
          const [],
        );
        _done = true;
      }
      return;
    }

    // An on-catch clause was found; verify that the exception type is not a
    // subtype of a previous on-catch exception type.
    for (var type in _visitedTypes) {
      if (_typeSystem.isSubtypeOf(currentType, type)) {
        _errorReporter(
          catchClause,
          catchClauses.last,
          WarningCode.DEAD_CODE_ON_CATCH_SUBTYPE,
          [currentType, type],
        );
        _done = true;
        return;
      }
    }

    _visitedTypes.add(currentType);
  }
}

/// An object used to track the usage of labels within a single label scope.
class _LabelTracker {
  /// The tracker for the outer label scope.
  final _LabelTracker? outerTracker;

  /// The labels whose usage is being tracked.
  final List<Label> labels;

  /// A list of flags corresponding to the list of [labels] indicating whether
  /// the corresponding label has been used.
  late final List<bool> used;

  /// A map from the names of labels to the index of the label in [labels].
  final Map<String, int> labelMap = <String, int>{};

  /// Initialize a newly created label tracker.
  _LabelTracker(this.outerTracker, this.labels) {
    used = List.filled(labels.length, false);
    for (int i = 0; i < labels.length; i++) {
      labelMap[labels[i].label.name] = i;
    }
  }

  /// Record that the label with the given [labelName] has been used.
  void recordUsage(String? labelName) {
    if (labelName != null) {
      var index = labelMap[labelName];
      if (index != null) {
        used[index] = true;
      } else {
        outerTracker?.recordUsage(labelName);
      }
    }
  }

  /// Return the unused labels.
  Iterable<Label> unusedLabels() sync* {
    for (int i = 0; i < labels.length; i++) {
      if (!used[i]) {
        yield labels[i];
      }
    }
  }
}

extension on FunctionElement {
  bool get isLocal =>
      enclosingElement3 is FunctionElement ||
      enclosingElement3 is MethodElement;
}

extension DoStatementExtension on DoStatement {
  bool get hasBreakStatement {
    var visitor = _BreakDoStatementVisitor(this);
    body.visitChildren(visitor);
    return visitor.hasBreakStatement;
  }
}
