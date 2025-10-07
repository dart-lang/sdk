// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';

/// State information captured by [NullSafetyDeadCodeVerifier.for_conditionEnd]
/// for later use by [NullSafetyDeadCodeVerifier.for_updaterBegin].
class DeadCodeForPartsState {
  /// The value of [NullSafetyDeadCodeVerifier._firstDeadNode] at the time of
  /// the call to [NullSafetyDeadCodeVerifier.for_conditionEnd]
  final AstNode? _firstDeadNodeAsOfConditionEnd;

  DeadCodeForPartsState._({required AstNode? firstDeadNodeAsOfConditionEnd})
    : _firstDeadNodeAsOfConditionEnd = firstDeadNodeAsOfConditionEnd;
}

/// A visitor that finds dead code, other than unreachable code that is
/// handled in [NullSafetyDeadCodeVerifier].
class DeadCodeVerifier extends RecursiveAstVisitor<void> {
  /// The diagnostic reporter by which diagnostics will be reported.
  final DiagnosticReporter _diagnosticReporter;

  /// The object used to track the usage of labels within a given label scope.
  _LabelTracker? _labelTracker;

  /// Whether the `wildcard_variables` feature is enabled.
  final bool _wildCardVariablesEnabled;

  DeadCodeVerifier(this._diagnosticReporter, LibraryElement library)
    : _wildCardVariablesEnabled = library.featureSet.isEnabled(
        Feature.wildcard_variables,
      );

  @override
  void visitBreakStatement(BreakStatement node) {
    _labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    _labelTracker?.recordUsage(node.label?.name);
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var libraryExport = node.libraryExport;
    if (libraryExport != null) {
      // The element is null when the URI is invalid.
      var library = libraryExport.exportedLibrary;
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
    var element = node.declaredFragment!.element;
    // TODO(pq): ask the FunctionElement once implemented
    if (_wildCardVariablesEnabled &&
        element is LocalFunctionElement &&
        element.name == '_') {
      _diagnosticReporter.atNode(node, WarningCode.deadCode);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var libraryImport = node.libraryImport;
    if (libraryImport != null) {
      // The element is null when the URI is invalid, but not when the URI is
      // valid but refers to a nonexistent file.
      var library = libraryImport.importedLibrary;
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
      var element = node.declaredFragment!.element;
      // TODO(pq): ask the LocalVariableElement once implemented
      if (_wildCardVariablesEnabled &&
          element is LocalVariableElement &&
          element.name == '_') {
        _diagnosticReporter.atNode(
          initializer,
          WarningCode.deadCodeLateWildcardVariableInitializer,
        );
      }
    }

    super.visitVariableDeclaration(node);
  }

  /// Resolve the names in the given [combinator] in the scope of the given
  /// [library].
  void _checkCombinator(LibraryElementImpl library, Combinator combinator) {
    Namespace namespace = library.exportNamespace;
    NodeList<SimpleIdentifier> names;
    DiagnosticCode warningCode;
    if (combinator is HideCombinator) {
      names = combinator.hiddenNames;
      warningCode = WarningCode.undefinedHiddenName;
    } else {
      names = (combinator as ShowCombinator).shownNames;
      warningCode = WarningCode.undefinedShownName;
    }
    for (SimpleIdentifier name in names) {
      String nameStr = name.name;
      Element? element = namespace.get2(nameStr);
      element ??= namespace.get2("$nameStr=");
      if (element == null) {
        _diagnosticReporter.atNode(
          name,
          warningCode,
          arguments: ['${library.uri}', nameStr],
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
        _diagnosticReporter.atNode(
          label,
          WarningCode.unusedLabel,
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
  final DiagnosticReporter _diagnosticReporter;
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
    this._diagnosticReporter,
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
      _diagnosticReporter.atToken(node.keyword, WarningCode.deadCode);
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
        _diagnosticReporter.atOffset(
          offset: parent.offset,
          length: parent.end - parent.offset,
          diagnosticCode: WarningCode.deadCode,
        );
        offset = node.end;
      } else if (parent is DoStatement) {
        var whileOffset = parent.whileKeyword.offset;
        var whileEnd = parent.semicolon.end;
        var body = parent.body;
        if (body is Block) {
          whileOffset = body.rightBracket.offset;
        }
        _diagnosticReporter.atOffset(
          offset: whileOffset,
          length: whileEnd - whileOffset,
          diagnosticCode: WarningCode.deadCode,
        );
        offset = parent.semicolon.next!.offset;
        if (parent.hasBreakStatement) {
          offset = node.end;
        }
      } else if (parent is ForParts) {
        if (parent.updaters.lastOrNull case var last?) node = last;
      } else if (parent is BinaryExpression) {
        offset = parent.operator.offset;
        node = parent.rightOperand;
      } else if (parent is LogicalOrPattern &&
          firstDeadNode == parent.rightOperand) {
        offset = parent.operator.offset;
      }

      var length = node.end - offset;
      if (length > 0) {
        _diagnosticReporter.atOffset(
          offset: offset,
          length: length,
          diagnosticCode: WarningCode.deadCode,
        );
      }
    }

    _firstDeadNode = null;
  }

  /// Performs the necessary dead code analysis when reaching the end of the
  /// `condition` part of [ForParts].
  ///
  /// Some state is returned, which should be passed to [for_updaterBegin] after
  /// visiting the body of the loop.
  DeadCodeForPartsState for_conditionEnd() {
    // Capture the state of this class so that `for_updaterBegin` can use it to
    // decide whether it's necessary to create an extra dead code report for the
    // updaters.
    return DeadCodeForPartsState._(
      firstDeadNodeAsOfConditionEnd: _firstDeadNode,
    );
  }

  /// Performs the necessary dead code analysis when reaching the beginning of
  /// the `updaters` part of [ForParts].
  ///
  /// [state] should be the state returned by [for_conditionEnd].
  void for_updaterBegin(
    NodeListImpl<ExpressionImpl> updaters,
    DeadCodeForPartsState state,
  ) {
    var isReachable = _flowAnalysis?.flow?.isReachable ?? true;
    if (!isReachable && state._firstDeadNodeAsOfConditionEnd == null) {
      // A dead code range started either at the beginning of the loop body or
      // somewhere inside it, and so the updaters are dead. Since the updaters
      // appear textually before the loop body, they need their own dead code
      // warning.
      var beginToken = updaters.beginToken;
      var endToken = updaters.endToken;
      if (beginToken != null && endToken != null) {
        _diagnosticReporter.atOffset(
          offset: beginToken.offset,
          length: endToken.end - beginToken.offset,
          diagnosticCode: WarningCode.deadCode,
        );
      }
    }
  }

  /// Rewites [_firstDeadNode] if it is equal to [oldNode], as [oldNode] is
  /// being rewritten into [newNode] in the syntax tree.
  void maybeRewriteFirstDeadNode(AstNode oldNode, AstNode newNode) {
    if (_firstDeadNode == oldNode) {
      _firstDeadNode = newNode;
    }
  }

  void tryStatementEnter(TryStatement node) {
    var verifier = _CatchClausesVerifier(_typeSystem, (
      first,
      last,
      errorCode,
      arguments,
    ) {
      var offset = first.offset;
      var length = last.end - offset;
      _diagnosticReporter.atOffset(
        offset: offset,
        length: length,
        diagnosticCode: errorCode,
        arguments: arguments,
      );
      _deadCatchClauseRanges.add(SourceRange(offset, length));
    }, node.catchClauses);
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

  void verifyCatchClause(CatchClauseImpl node) {
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

  void _verifyUnassignedSimpleIdentifier(
    AstNode node,
    Expression? target,
    Token? operator,
  ) {
    var flowAnalysis = _flowAnalysis;
    if (flowAnalysis == null) return;

    if (operator == null) return;
    var operatorType = operator.type;
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
      var element = target.element;
      if (element is PromotableElementImpl &&
          flowAnalysis.isDefinitelyUnassigned(target, element)) {
        var parent = node.parent;
        while (parent is MethodInvocation ||
            parent is PropertyAccess ||
            parent is IndexExpression) {
          node = parent!;
          parent = node.parent;
        }
        _diagnosticReporter.atOffset(
          offset: operator.offset,
          length: node.end - operator.offset,
          diagnosticCode: WarningCode.deadCode,
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
  final void Function(
    CatchClause first,
    CatchClause last,
    DiagnosticCode,
    List<Object> arguments,
  )
  _reportDiagnostic;
  final List<CatchClause> catchClauses;

  bool _done = false;
  final List<TypeImpl> _visitedTypes = [];

  _CatchClausesVerifier(
    this._typeSystem,
    this._reportDiagnostic,
    this.catchClauses,
  );

  void nextCatchClause(CatchClauseImpl catchClause) {
    var currentType = catchClause.exceptionType?.type;

    // Found catch clause that doesn't have an exception type.
    // Generate an error on any following catch clauses.
    if (currentType == null || currentType.isDartCoreObject) {
      if (catchClause != catchClauses.last) {
        var index = catchClauses.indexOf(catchClause);
        _reportDiagnostic(
          catchClauses[index + 1],
          catchClauses.last,
          WarningCode.deadCodeCatchFollowingCatch,
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
        _reportDiagnostic(
          catchClause,
          catchClauses.last,
          WarningCode.deadCodeOnCatchSubtype,
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

extension DoStatementExtension on DoStatement {
  bool get hasBreakStatement {
    var visitor = _BreakDoStatementVisitor(this);
    body.visitChildren(visitor);
    return visitor.hasBreakStatement;
  }
}
