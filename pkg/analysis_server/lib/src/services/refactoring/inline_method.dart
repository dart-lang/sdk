// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/visible_ranges_computer.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Returns the [SourceRange] to find conflicting locals in.
SourceRange _getLocalsConflictingRange(AstNode node) {
  // maybe Block
  var block = node.thisOrAncestorOfType<Block>();
  if (block != null) {
    return range.startEnd(node, block);
  }
  // maybe whole executable
  var executableNode = getEnclosingExecutableNode(node);
  if (executableNode != null) {
    return range.node(executableNode);
  }
  // not a part of a declaration with locals
  return SourceRange.EMPTY;
}

/// Returns the source which should replace given invocation with given
/// arguments.
String _getMethodSourceForInvocation(
    RefactoringStatus status,
    _SourcePart part,
    CorrectionUtils utils,
    AstNode contextNode,
    Expression targetExpression,
    List<Expression> arguments) {
  // prepare edits to replace parameters with arguments
  var edits = <SourceEdit>[];
  part._parameters.forEach(
      (ParameterElement parameter, List<_ParameterOccurrence> occurrences) {
    // prepare argument
    Expression argument;
    for (var arg in arguments) {
      if (arg.staticParameterElement == parameter) {
        argument = arg;
        break;
      }
    }
    if (argument is NamedExpression) {
      argument = (argument as NamedExpression).expression;
    }
    // prepare argument properties
    Precedence argumentPrecedence;
    String argumentSource;
    if (argument != null) {
      argumentPrecedence = getExpressionPrecedence(argument);
      argumentSource = utils.getNodeText(argument);
    } else {
      // report about a missing required parameter
      if (parameter.isRequiredPositional) {
        status.addError('No argument for the parameter "${parameter.name}".',
            newLocation_fromNode(contextNode));
        return;
      }
      // an optional parameter
      argumentPrecedence = Precedence.none;
      argumentSource = parameter.defaultValueCode;
      argumentSource ??= 'null';
    }
    // replace all occurrences of this parameter
    for (var occurrence in occurrences) {
      var range = occurrence.range;
      // prepare argument source to apply at this occurrence
      String occurrenceArgumentSource;
      if (argumentPrecedence < occurrence.parentPrecedence) {
        occurrenceArgumentSource = '($argumentSource)';
      } else {
        occurrenceArgumentSource = argumentSource;
      }
      // do replace
      edits.add(newSourceEdit_range(range, occurrenceArgumentSource));
    }
  });
  // replace static field "qualifier" with invocation target
  part._implicitClassNameOffsets.forEach((String className, List<int> offsets) {
    for (var offset in offsets) {
//      edits.add(newSourceEdit_range(range, className + '.'));
      edits.add(SourceEdit(offset, 0, className + '.'));
    }
  });
  // replace "this" references with invocation target
  if (targetExpression != null) {
    var targetSource = utils.getNodeText(targetExpression);
    // explicit "this" references
    for (var offset in part._explicitThisOffsets) {
      edits.add(SourceEdit(offset, 4, targetSource));
    }
    // implicit "this" references
    targetSource += '.';
    for (var offset in part._implicitThisOffsets) {
      edits.add(SourceEdit(offset, 0, targetSource));
    }
  }
  // prepare edits to replace conflicting variables
  var conflictingNames = _getNamesConflictingAt(contextNode);
  part._variables.forEach((VariableElement variable, List<SourceRange> ranges) {
    var originalName = variable.displayName;
    // prepare unique name
    String uniqueName;
    {
      uniqueName = originalName;
      var uniqueIndex = 2;
      while (conflictingNames.contains(uniqueName)) {
        uniqueName = originalName + uniqueIndex.toString();
        uniqueIndex++;
      }
    }
    // update references, if name was change
    if (uniqueName != originalName) {
      for (var range in ranges) {
        edits.add(newSourceEdit_range(range, uniqueName));
      }
    }
  });
  // prepare source with applied arguments
  edits.sort((SourceEdit a, SourceEdit b) => b.offset - a.offset);
  return SourceEdit.applySequence(part._source, edits);
}

/// Returns the names which will shadow or will be shadowed by any declaration
/// at [node].
Set<String> _getNamesConflictingAt(AstNode node) {
  var result = <String>{};
  // local variables and functions
  {
    var localsRange = _getLocalsConflictingRange(node);
    var enclosingExecutable = getEnclosingExecutableNode(node);
    var visibleRangeMap = VisibleRangesComputer.forNode(enclosingExecutable);
    visibleRangeMap.forEach((element, elementRange) {
      if (elementRange.intersects(localsRange)) {
        result.add(element.displayName);
      }
    });
  }
  // fields
  {
    var enclosingClassElement = getEnclosingClassElement(node);
    if (enclosingClassElement != null) {
      var elements = <ClassElement>{};
      elements.add(enclosingClassElement);
      elements.addAll(getSuperClasses(enclosingClassElement));
      for (var classElement in elements) {
        var classMembers = getChildren(classElement);
        for (var classMemberElement in classMembers) {
          result.add(classMemberElement.displayName);
        }
      }
    }
  }
  // done
  return result;
}

/// [InlineMethodRefactoring] implementation.
class InlineMethodRefactoringImpl extends RefactoringImpl
    implements InlineMethodRefactoring {
  final SearchEngine searchEngine;
  final ResolvedUnitResult resolveResult;
  final int offset;
  final AnalysisSessionHelper sessionHelper;
  CorrectionUtils utils;
  SourceChange change;

  @override
  bool isDeclaration = false;
  bool deleteSource = false;
  bool inlineAll = true;

  ExecutableElement _methodElement;
  CompilationUnit _methodUnit;
  CorrectionUtils _methodUtils;
  AstNode _methodNode;
  FormalParameterList _methodParameters;
  FunctionBody _methodBody;
  Expression _methodExpression;
  _SourcePart _methodExpressionPart;
  _SourcePart _methodStatementsPart;
  final List<_ReferenceProcessor> _referenceProcessors = [];
  final Set<Element> _alreadyMadeAsync = <Element>{};

  InlineMethodRefactoringImpl(
      this.searchEngine, this.resolveResult, this.offset)
      : sessionHelper = AnalysisSessionHelper(resolveResult.session) {
    utils = CorrectionUtils(resolveResult);
  }

  @override
  String get className {
    if (_methodElement == null) {
      return null;
    }
    var classElement = _methodElement.enclosingElement;
    if (classElement is ClassElement) {
      return classElement.displayName;
    }
    return null;
  }

  @override
  String get methodName {
    if (_methodElement == null) {
      return null;
    }
    return _methodElement.displayName;
  }

  @override
  String get refactoringName {
    if (_methodElement is MethodElement) {
      return 'Inline Method';
    } else {
      return 'Inline Function';
    }
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    change = SourceChange(refactoringName);
    var result = RefactoringStatus();
    // check for compatibility of "deleteSource" and "inlineAll"
    if (deleteSource && !inlineAll) {
      result.addError('All references must be inlined to remove the source.');
    }
    // prepare changes
    for (var processor in _referenceProcessors) {
      processor._process(result);
    }
    // delete method
    if (deleteSource && inlineAll) {
      var methodRange = range.node(_methodNode);
      var linesRange =
          _methodUtils.getLinesRange(methodRange, skipLeadingEmptyLines: true);
      doSourceChange_addElementEdit(
          change, _methodElement, newSourceEdit_range(linesRange, ''));
    }
    // done
    return Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    var result = RefactoringStatus();
    // prepare method information
    result.addStatus(await _prepareMethod());
    if (result.hasFatalError) {
      return Future<RefactoringStatus>.value(result);
    }
    // maybe operator
    if (_methodElement.isOperator) {
      result = RefactoringStatus.fatal('Cannot inline operator.');
      return Future<RefactoringStatus>.value(result);
    }
    // maybe [a]sync*
    if (_methodElement.isGenerator) {
      result = RefactoringStatus.fatal('Cannot inline a generator.');
      return Future<RefactoringStatus>.value(result);
    }
    // analyze method body
    result.addStatus(_prepareMethodParts());
    // process references
    var references = await searchEngine.searchReferences(_methodElement);
    _referenceProcessors.clear();
    for (var reference in references) {
      var processor = _ReferenceProcessor(this, reference);
      await processor.init();
      _referenceProcessors.add(processor);
    }
    return result;
  }

  @override
  Future<SourceChange> createChange() {
    return Future.value(change);
  }

  _SourcePart _createSourcePart(SourceRange range) {
    var source = _methodUtils.getRangeText(range);
    var prefix = getLinePrefix(source);
    var result = _SourcePart(range.offset, source, prefix);
    // remember parameters and variables occurrences
    _methodUnit.accept(_VariablesVisitor(_methodElement, range, result));
    // done
    return result;
  }

  /// Initializes [_methodElement] and related fields.
  Future<RefactoringStatus> _prepareMethod() async {
    _methodElement = null;
    _methodParameters = null;
    _methodBody = null;
    deleteSource = false;
    inlineAll = false;
    // prepare for failure
    var fatalStatus = RefactoringStatus.fatal(
        'Method declaration or reference must be selected to activate this refactoring.');
    // prepare selected SimpleIdentifier
    var node = NodeLocator(offset).searchWithin(resolveResult.unit);
    if (node is! SimpleIdentifier) {
      return fatalStatus;
    }
    var identifier = node as SimpleIdentifier;
    // prepare selected ExecutableElement
    var element = identifier.writeOrReadElement;
    if (element is! ExecutableElement) {
      return fatalStatus;
    }
    if (element.isSynthetic) {
      return fatalStatus;
    }
    _methodElement = element as ExecutableElement;

    var declaration = await sessionHelper.getElementDeclaration(_methodElement);
    var methodNode = declaration.node;
    _methodNode = methodNode;

    var resolvedUnit = declaration.resolvedUnit;
    _methodUnit = resolvedUnit.unit;
    _methodUtils = CorrectionUtils(resolvedUnit);

    if (methodNode is MethodDeclaration) {
      _methodParameters = methodNode.parameters;
      _methodBody = methodNode.body;
    } else if (methodNode is FunctionDeclaration) {
      _methodParameters = methodNode.functionExpression.parameters;
      _methodBody = methodNode.functionExpression.body;
    } else {
      return fatalStatus;
    }

    isDeclaration = resolveResult.uri == element.source.uri &&
        node.offset == element.nameOffset;
    deleteSource = isDeclaration;
    inlineAll = deleteSource;
    return RefactoringStatus();
  }

  /// Analyze [_methodBody] to fill [_methodExpressionPart] and
  /// [_methodStatementsPart].
  RefactoringStatus _prepareMethodParts() {
    var result = RefactoringStatus();
    if (_methodBody is ExpressionFunctionBody) {
      var body = _methodBody as ExpressionFunctionBody;
      _methodExpression = body.expression;
      var methodExpressionRange = range.node(_methodExpression);
      _methodExpressionPart = _createSourcePart(methodExpressionRange);
    } else if (_methodBody is BlockFunctionBody) {
      var body = (_methodBody as BlockFunctionBody).block;
      List<Statement> statements = body.statements;
      if (statements.isNotEmpty) {
        var lastStatement = statements[statements.length - 1];
        // "return" statement requires special handling
        if (lastStatement is ReturnStatement) {
          _methodExpression = lastStatement.expression;
          if (_methodExpression != null) {
            var methodExpressionRange = range.node(_methodExpression);
            _methodExpressionPart = _createSourcePart(methodExpressionRange);
          }
          // exclude "return" statement from statements
          statements = statements.sublist(0, statements.length - 1);
        }
        // if there are statements, process them
        if (statements.isNotEmpty) {
          var statementsRange =
              _methodUtils.getLinesRangeStatements(statements);
          _methodStatementsPart = _createSourcePart(statementsRange);
        }
      }
      // check if more than one return
      body.accept(_ReturnsValidatorVisitor(result));
    } else {
      return RefactoringStatus.fatal('Cannot inline method without body.');
    }
    return result;
  }
}

class _ParameterOccurrence {
  final Precedence parentPrecedence;
  final SourceRange range;

  _ParameterOccurrence(this.parentPrecedence, this.range);
}

/// Processor for single [SearchMatch] reference to [methodElement].
class _ReferenceProcessor {
  final InlineMethodRefactoringImpl ref;
  final SearchMatch reference;

  Element refElement;
  CorrectionUtils _refUtils;
  SimpleIdentifier _node;
  SourceRange _refLineRange;
  String _refPrefix;

  _ReferenceProcessor(this.ref, this.reference);

  Future<void> init() async {
    refElement = reference.element;

    // prepare CorrectionUtils
    var result = await ref.sessionHelper.getResolvedUnitByElement(refElement);
    _refUtils = CorrectionUtils(result);

    // prepare node and environment
    _node = _refUtils.findNode(reference.sourceRange.offset);
    var refStatement = _node.thisOrAncestorOfType<Statement>();
    if (refStatement != null) {
      _refLineRange = _refUtils.getLinesRangeStatements([refStatement]);
      _refPrefix = _refUtils.getNodePrefix(refStatement);
    } else {
      _refLineRange = null;
      _refPrefix = _refUtils.getLinePrefix(_node.offset);
    }
  }

  void _addRefEdit(SourceEdit edit) {
    doSourceChange_addElementEdit(ref.change, refElement, edit);
  }

  bool _canInlineBody(AstNode usage) {
    // no statements, usually just expression
    if (ref._methodStatementsPart == null) {
      // empty method, inline as closure
      if (ref._methodExpressionPart == null) {
        return false;
      }
      // OK, just expression
      return true;
    }
    // analyze point of invocation
    var parent = usage.parent;
    var parent2 = parent.parent;
    // OK, if statement in block
    if (parent is Statement) {
      return parent2 is Block;
    }
    // maybe assignment, in block
    if (parent is AssignmentExpression) {
      var assignment = parent;
      // inlining setter
      if (assignment.leftHandSide == usage) {
        return parent2 is Statement && parent2.parent is Block;
      }
      // inlining initializer
      return ref._methodExpressionPart != null;
    }
    // maybe value for variable initializer, in block
    if (ref._methodExpressionPart != null) {
      if (parent is VariableDeclaration) {
        if (parent2 is VariableDeclarationList) {
          var parent3 = parent2.parent;
          return parent3 is VariableDeclarationStatement &&
              parent3.parent is Block;
        }
      }
    }
    // not in block, cannot inline body
    return false;
  }

  void _inlineMethodInvocation(RefactoringStatus status, Expression usage,
      bool cascaded, Expression target, List<Expression> arguments) {
    // we don't support cascade
    if (cascaded) {
      status.addError(
          'Cannot inline cascade invocation.', newLocation_fromNode(usage));
    }
    // can we inline method body into "methodUsage" block?
    if (_canInlineBody(usage)) {
      // insert non-return statements
      if (ref._methodStatementsPart != null) {
        // prepare statements source for invocation
        var source = _getMethodSourceForInvocation(status,
            ref._methodStatementsPart, _refUtils, usage, target, arguments);
        source = _refUtils.replaceSourceIndent(
            source, ref._methodStatementsPart._prefix, _refPrefix);
        // do insert
        var edit =
            newSourceEdit_range(SourceRange(_refLineRange.offset, 0), source);
        _addRefEdit(edit);
      }
      // replace invocation with return expression
      if (ref._methodExpressionPart != null) {
        // prepare expression source for invocation
        var source = _getMethodSourceForInvocation(status,
            ref._methodExpressionPart, _refUtils, usage, target, arguments);
        if (getExpressionPrecedence(ref._methodExpression) <
            getExpressionParentPrecedence(usage)) {
          source = '($source)';
        }
        // do replace
        var methodUsageRange = range.node(usage);
        var edit = newSourceEdit_range(methodUsageRange, source);
        _addRefEdit(edit);
      } else {
        var edit = newSourceEdit_range(_refLineRange, '');
        _addRefEdit(edit);
      }
      return;
    }
    // inline as closure invocation
    String source;
    {
      source = ref._methodUtils.getRangeText(range.startEnd(
          ref._methodParameters.leftParenthesis, ref._methodNode));
      var methodPrefix = ref._methodUtils.getLinePrefix(ref._methodNode.offset);
      source = _refUtils.replaceSourceIndent(source, methodPrefix, _refPrefix);
      source = source.trim();
    }
    // do insert
    var edit = newSourceEdit_range(range.node(_node), source);
    _addRefEdit(edit);
  }

  void _process(RefactoringStatus status) {
    var nodeParent = _node.parent;
    // may be only single place should be inlined
    if (!_shouldProcess()) {
      return;
    }
    // If the element being inlined is async, ensure that the function
    // body that encloses the method is also async.
    if (ref._methodElement.isAsynchronous) {
      var body = _node.thisOrAncestorOfType<FunctionBody>();
      if (body != null) {
        if (body.isSynchronous) {
          if (body.isGenerator) {
            status.addFatalError(
                'Cannot inline async into sync*.', newLocation_fromNode(_node));
            return;
          }
          if (refElement is ExecutableElement) {
            var executable = refElement as ExecutableElement;
            if (!executable.returnType.isDartAsyncFuture) {
              status.addFatalError(
                  'Cannot inline async into a function that does not return a Future.',
                  newLocation_fromNode(_node));
              return;
            }
          }
          if (ref._alreadyMadeAsync.add(refElement)) {
            var bodyStart = range.startLength(body, 0);
            _addRefEdit(newSourceEdit_range(bodyStart, 'async '));
          }
        }
      }
    }
    // may be invocation of inline method
    if (nodeParent is MethodInvocation) {
      var invocation = nodeParent;
      var target = invocation.target;
      List<Expression> arguments = invocation.argumentList.arguments;
      _inlineMethodInvocation(
          status, invocation, invocation.isCascaded, target, arguments);
    } else {
      // cannot inline reference to method: var v = new A().method;
      if (ref._methodElement is MethodElement) {
        status.addFatalError('Cannot inline class method reference.',
            newLocation_fromNode(_node));
        return;
      }
      // PropertyAccessorElement
      if (ref._methodElement is PropertyAccessorElement) {
        Expression usage = _node;
        Expression target;
        var cascade = false;
        if (nodeParent is PrefixedIdentifier) {
          var propertyAccess = nodeParent;
          usage = propertyAccess;
          target = propertyAccess.prefix;
          cascade = false;
        }
        if (nodeParent is PropertyAccess) {
          var propertyAccess = nodeParent;
          usage = propertyAccess;
          target = propertyAccess.realTarget;
          cascade = propertyAccess.isCascaded;
        }
        // prepare arguments
        var arguments = <Expression>[];
        if (_node.inSetterContext()) {
          var assignment = _node.thisOrAncestorOfType<AssignmentExpression>();
          arguments.add(assignment.rightHandSide);
        }
        // inline body
        _inlineMethodInvocation(status, usage, cascade, target, arguments);
        return;
      }
      // not invocation, just reference to function
      String source;
      {
        source = ref._methodUtils.getRangeText(range.startEnd(
            ref._methodParameters.leftParenthesis, ref._methodNode));
        var methodPrefix =
            ref._methodUtils.getLinePrefix(ref._methodNode.offset);
        source =
            _refUtils.replaceSourceIndent(source, methodPrefix, _refPrefix);
        source = source.trim();
        source = removeEnd(source, ';');
      }
      // do insert
      var edit = newSourceEdit_range(range.node(_node), source);
      _addRefEdit(edit);
    }
  }

  bool _shouldProcess() {
    if (!ref.inlineAll) {
      var parentRange = range.node(_node);
      return parentRange.contains(ref.offset);
    }
    return true;
  }
}

class _ReturnsValidatorVisitor extends RecursiveAstVisitor<void> {
  final RefactoringStatus result;
  int _numReturns = 0;

  _ReturnsValidatorVisitor(this.result);

  @override
  void visitReturnStatement(ReturnStatement node) {
    _numReturns++;
    if (_numReturns == 2) {
      result.addError('Ambiguous return value.', newLocation_fromNode(node));
    }
  }
}

/// Information about the source of a method being inlined.
class _SourcePart {
  /// The base for all [SourceRange]s.
  final int _base;

  /// The source of the method.
  final String _source;

  /// The original prefix of the method.
  final String _prefix;

  /// The occurrences of the method parameters.
  final Map<ParameterElement, List<_ParameterOccurrence>> _parameters = {};

  /// The occurrences of the method local variables.
  final Map<VariableElement, List<SourceRange>> _variables = {};

  /// The offsets of explicit `this` expression references.
  final List<int> _explicitThisOffsets = [];

  /// The offsets of implicit `this` expression references.
  final List<int> _implicitThisOffsets = [];

  /// The offsets of the implicit class references in static member references.
  final Map<String, List<int>> _implicitClassNameOffsets = {};

  _SourcePart(this._base, this._source, this._prefix);

  void addExplicitThisOffset(int offset) {
    _explicitThisOffsets.add(offset - _base);
  }

  void addImplicitClassNameOffset(String className, int offset) {
    var offsets = _implicitClassNameOffsets[className];
    if (offsets == null) {
      offsets = [];
      _implicitClassNameOffsets[className] = offsets;
    }
    offsets.add(offset - _base);
  }

  void addImplicitThisOffset(int offset) {
    _implicitThisOffsets.add(offset - _base);
  }

  void addParameterOccurrence(ParameterElement parameter,
      SourceRange identifierRange, Precedence precedence) {
    if (parameter != null) {
      var occurrences = _parameters[parameter];
      if (occurrences == null) {
        occurrences = [];
        _parameters[parameter] = occurrences;
      }
      identifierRange = range.offsetBy(identifierRange, -_base);
      occurrences.add(_ParameterOccurrence(precedence, identifierRange));
    }
  }

  void addVariable(VariableElement element, SourceRange identifierRange) {
    var ranges = _variables[element];
    if (ranges == null) {
      ranges = [];
      _variables[element] = ranges;
    }
    identifierRange = range.offsetBy(identifierRange, -_base);
    ranges.add(identifierRange);
  }
}

/// A visitor that fills [_SourcePart] with fields, parameters and variables.
class _VariablesVisitor extends GeneralizingAstVisitor<void> {
  /// The [ExecutableElement] being inlined.
  final ExecutableElement methodElement;

  /// The [SourceRange] of the element body.
  final SourceRange bodyRange;

  /// The [_SourcePart] to record reference into.
  final _SourcePart result;

  int offset;

  _VariablesVisitor(this.methodElement, this.bodyRange, this.result);

  @override
  void visitNode(AstNode node) {
    var nodeRange = range.node(node);
    if (!bodyRange.intersects(nodeRange)) {
      return null;
    }
    super.visitNode(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var nodeRange = range.node(node);
    if (bodyRange.covers(nodeRange)) {
      _addMemberQualifier(node);
      _addParameter(node);
      _addVariable(node);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    var offset = node.offset;
    if (bodyRange.contains(offset)) {
      result.addExplicitThisOffset(offset);
    }
  }

  void _addMemberQualifier(SimpleIdentifier node) {
    // should be unqualified
    AstNode qualifier = getNodeQualifier(node);
    if (qualifier != null) {
      return;
    }
    // should be a method or field reference
    var element = node.writeOrReadElement;
    if (!(element is MethodElement || element is PropertyAccessorElement)) {
      return;
    }
    if (element.enclosingElement is! ClassElement) {
      return;
    }
    // record the implicit static or instance reference
    ExecutableElement member = element;
    var offset = node.offset;
    if (member.isStatic) {
      var className = member.enclosingElement.displayName;
      result.addImplicitClassNameOffset(className, offset);
    } else {
      result.addImplicitThisOffset(offset);
    }
  }

  void _addParameter(SimpleIdentifier node) {
    var parameterElement = getParameterElement(node);
    // not a parameter
    if (parameterElement == null) {
      return;
    }
    // not a parameter of the function being inlined
    if (!methodElement.parameters.contains(parameterElement)) {
      return;
    }
    // OK, add occurrence
    var nodeRange = range.node(node);
    var parentPrecedence = getExpressionParentPrecedence(node);
    result.addParameterOccurrence(
        parameterElement, nodeRange, parentPrecedence);
  }

  void _addVariable(SimpleIdentifier node) {
    VariableElement variableElement = getLocalVariableElement(node);
    if (variableElement != null) {
      var nodeRange = range.node(node);
      result.addVariable(variableElement, nodeRange);
    }
  }
}
