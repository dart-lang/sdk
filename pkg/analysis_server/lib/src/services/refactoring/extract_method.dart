// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.extract_method;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/rename_class_member.dart';
import 'package:analysis_server/src/services/refactoring/rename_unit_member.dart';
import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


const String _TOKEN_SEPARATOR = '\uFFFF';


/**
 * Returns the "normalized" version of the given source, which is reconstructed
 * from tokens, so ignores all the comments and spaces.
 */
String _getNormalizedSource(String src) {
  List<Token> selectionTokens = TokenUtils.getTokens(src);
  return StringUtils.join(selectionTokens, _TOKEN_SEPARATOR);
}


/**
 * Returns the [Map] which maps [map] values to their keys.
 */
Map<String, String> _inverseMap(Map map) {
  Map result = {};
  map.forEach((key, value) {
    result[value] = key;
  });
  return result;
}


/**
 * [ExtractMethodRefactoring] implementation.
 */
class ExtractMethodRefactoringImpl extends RefactoringImpl implements
    ExtractMethodRefactoring {
  final SearchEngine searchEngine;
  final CompilationUnit unit;
  final int selectionOffset;
  final int selectionLength;
  CompilationUnitElement unitElement;
  SourceRange selectionRange;
  CorrectionUtils utils;

  String returnType;
  String name;
  bool extractAll = true;
  bool createGetter = false;
  final List<String> names = <String>[];
  final List<int> offsets = <int>[];
  final List<int> lengths = <int>[];

  Set<String> _usedNames = new Set<String>();
  Set<String> _excludedNames = new Set<String>();
  List<RefactoringMethodParameter> _parameters = <RefactoringMethodParameter>[];
  Map<String, RefactoringMethodParameter> _parametersMap = <String,
      RefactoringMethodParameter>{};
  Map<String, List<SourceRange>> _parameterReferencesMap = <String,
      List<SourceRange>>{};
  DartType _returnType;
  String _returnVariableName;
  AstNode _parentMember;
  Expression _selectionExpression;
  FunctionExpression _selectionFunctionExpression;
  List<Statement> _selectionStatements;
  List<_Occurrence> _occurrences = [];
  bool _staticContext = false;

  ExtractMethodRefactoringImpl(this.searchEngine, this.unit,
      this.selectionOffset, this.selectionLength) {
    unitElement = unit.element;
    selectionRange = new SourceRange(selectionOffset, selectionLength);
    utils = new CorrectionUtils(unit);
  }

  bool get canCreateGetter {
    if (!parameters.isEmpty) {
      return false;
    }
    if (_selectionExpression != null) {
      if (_selectionExpression is AssignmentExpression) {
        return false;
      }
    }
    if (_selectionStatements != null) {
      return returnType != 'void';
    }
    return true;
  }

  @override
  List<RefactoringMethodParameter> get parameters => _parameters;

  @override
  void set parameters(List<RefactoringMethodParameter> parameters) {
    _parameters = parameters.toList();
  }

  @override
  String get refactoringName {
    AstNode node = new NodeLocator.con1(selectionOffset).searchWithin(unit);
    if (node != null &&
        node.getAncestor((node) => node is ClassDeclaration) != null) {
      return 'Extract Method';
    }
    return 'Extract Function';
  }

  String get signature {
    StringBuffer sb = new StringBuffer();
    if (createGetter) {
      sb.write('get ');
      sb.write(name);
    } else {
      sb.write(name);
      sb.write('(');
      // add all parameters
      bool firstParameter = true;
      for (RefactoringMethodParameter parameter in _parameters) {
        // may be comma
        if (firstParameter) {
          firstParameter = false;
        } else {
          sb.write(', ');
        }
        // type
        {
          String typeSource = parameter.type;
          if ('dynamic' != typeSource && '' != typeSource) {
            sb.write(typeSource);
            sb.write(' ');
          }
        }
        // name
        sb.write(parameter.name);
      }
      sb.write(')');
    }
    // done
    return sb.toString();
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    result.addStatus(validateMethodName(name));
    result.addStatus(_checkParameterNames());
    return _checkPossibleConflicts().then((status) {
      result.addStatus(status);
      return result;
    });
  }


  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = new RefactoringStatus();
    // selection
    result.addStatus(_checkSelection());
    if (result.hasFatalError) {
      return new Future.value(result);
    }
    // prepare parts
    result.addStatus(_initializeParameters());
    _initializeReturnType();
    _initializeGetter();
    // occurrences
    _initializeOccurrences();
    _prepareOffsetsLengths();
    // names
    _prepareExcludedNames();
    _prepareNames();
    // closure cannot have parameters
    if (_selectionFunctionExpression != null && !_parameters.isEmpty) {
      String message = format(
          'Cannot extract closure as method, it references {0} external variable(s).',
          _parameters.length);
      RefactoringStatus result = new RefactoringStatus.fatal(message);
      return new Future.value(result);
    }
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkName() {
    return validateMethodName(name);
  }

  @override
  Future<SourceChange> createChange() {
    SourceChange change = new SourceChange(refactoringName);
    // replace occurrences with method invocation
    for (_Occurrence occurence in _occurrences) {
      SourceRange range = occurence.range;
      // may be replacement of duplicates disabled
      if (!extractAll && !occurence.isSelection) {
        continue;
      }
      // prepare invocation source
      String invocationSource;
      if (_selectionFunctionExpression != null) {
        invocationSource = name;
      } else {
        StringBuffer sb = new StringBuffer();
        // may be returns value
        if (_selectionStatements != null && returnType != 'void') {
          // single variable assignment / return statement
          if (_returnVariableName != null) {
            String occurrenceName =
                occurence._parameterOldToOccurrenceName[_returnVariableName];
            // may be declare variable
            if (!_parametersMap.containsKey(_returnVariableName)) {
              if (returnType.isEmpty) {
                sb.write('var ');
              } else {
                sb.write(returnType);
                sb.write(' ');
              }
            }
            // assign the return value
            sb.write(occurrenceName);
            sb.write(' = ');
          } else {
            sb.write('return ');
          }
        }
        // invocation itself
        sb.write(name);
        if (!createGetter) {
          sb.write('(');
          bool firstParameter = true;
          for (RefactoringMethodParameter parameter in _parameters) {
            // may be comma
            if (firstParameter) {
              firstParameter = false;
            } else {
              sb.write(', ');
            }
            // argument name
            {
              String argumentName =
                  occurence._parameterOldToOccurrenceName[parameter.id];
              sb.write(argumentName);
            }
          }
          sb.write(')');
        }
        invocationSource = sb.toString();
        // statements as extracted with their ";", so add new after invocation
        if (_selectionStatements != null) {
          invocationSource += ';';
        }
      }
      // add replace edit
      SourceEdit edit = newSourceEdit_range(range, invocationSource);
      doSourceChange_addElementEdit(change, unitElement, edit);
    }
    // add method declaration
    {
      // prepare environment
      String prefix = utils.getNodePrefix(_parentMember);
      String eol = utils.endOfLine;
      // prepare annotations
      String annotations = '';
      {
        // may be "static"
        if (_staticContext) {
          annotations = 'static ';
        }
      }
      // prepare declaration source
      String declarationSource = null;
      {
        String returnExpressionSource = _getMethodBodySource();
        // closure
        if (_selectionFunctionExpression != null) {
          declarationSource = '${name}${returnExpressionSource}';
          if (_selectionFunctionExpression.body is ExpressionFunctionBody) {
            declarationSource += ';';
          }
        }
        // expression
        if (_selectionExpression != null) {
          // add return type
          Set<LibraryElement> librariesToImport = new Set<LibraryElement>();
          // TODO(scheglov) use librariesToImport
          String returnTypeName =
              utils.getExpressionTypeSource(_selectionExpression, librariesToImport);
          if (returnTypeName != null && returnTypeName != 'dynamic') {
            annotations += '${returnTypeName} ';
          }
          // just return expression
          declarationSource =
              '${annotations}${signature} => ${returnExpressionSource};';
        }
        // statements
        if (_selectionStatements != null) {
          if (returnType.isNotEmpty) {
            annotations += returnType + ' ';
          }
          declarationSource = '${annotations}${signature} {${eol}';
          declarationSource += returnExpressionSource;
          if (_returnVariableName != null) {
            declarationSource +=
                '${prefix}  return ${_returnVariableName};$eol';
          }
          declarationSource += '${prefix}}';
        }
      }
      // insert declaration
      if (declarationSource != null) {
        int offset = _parentMember.end;
        SourceEdit edit =
            new SourceEdit(offset, 0, '${eol}${eol}${prefix}${declarationSource}');
        doSourceChange_addElementEdit(change, unitElement, edit);
      }
    }
    // done
    return new Future.value(change);
  }

  @override
  bool requiresPreview() => false;

  /**
   * Adds a new reference to the parameter with the given name.
   */
  void _addParameterReference(String name, SourceRange range) {
    List<SourceRange> references = _parameterReferencesMap[name];
    if (references == null) {
      references = [];
      _parameterReferencesMap[name] = references;
    }
    references.add(range);
  }

  RefactoringStatus _checkParameterNames() {
    RefactoringStatus result = new RefactoringStatus();
    for (RefactoringMethodParameter parameter in _parameters) {
      result.addStatus(validateParameterName(parameter.name));
      for (RefactoringMethodParameter other in _parameters) {
        if (!identical(parameter, other) && other.name == parameter.name) {
          result.addError(
              format("Parameter '{0}' already exists", parameter.name));
          return result;
        }
      }
      if (_usedNames.contains(parameter.name)) {
        result.addError(
            format("'{0}' is already used as a name in the selected code", parameter.name));
        return result;
      }
    }
    return result;
  }

  /**
   * Checks if created method will shadow or will be shadowed by other elements.
   */
  Future<RefactoringStatus> _checkPossibleConflicts() {
    RefactoringStatus result = new RefactoringStatus();
    AstNode parent = _parentMember.parent;
    // top-level function
    if (parent is CompilationUnit) {
      LibraryElement libraryElement = parent.element.library;
      return validateCreateFunction(searchEngine, libraryElement, name);
    }
    // method of class
    if (parent is ClassDeclaration) {
      ClassElement classElement = parent.element;
      return validateCreateMethod(searchEngine, classElement, name);
    }
    // OK
    return new Future.value(result);
  }

  /**
   * Checks if [selectionRange] selects [Expression] which can be extracted, and
   * location of this [DartExpression] in AST allows extracting.
   */
  RefactoringStatus _checkSelection() {
    _ExtractMethodAnalyzer selectionAnalyzer =
        new _ExtractMethodAnalyzer(unit, selectionRange);
    unit.accept(selectionAnalyzer);
    // may be fatal error
    {
      RefactoringStatus status = selectionAnalyzer.status;
      if (status.hasFatalError) {
        return status;
      }
    }
    // check selected nodes
    List<AstNode> selectedNodes = selectionAnalyzer.selectedNodes;
    if (!selectedNodes.isEmpty) {
      AstNode coveringNode = selectionAnalyzer.coveringNode;
      _parentMember = getEnclosingClassOrUnitMember(coveringNode);
      // single expression selected
      if (selectedNodes.length == 1 &&
          !utils.selectionIncludesNonWhitespaceOutsideNode(
              selectionRange,
              selectionAnalyzer.firstSelectedNode)) {
        AstNode selectedNode = selectionAnalyzer.firstSelectedNode;
        if (selectedNode is Expression) {
          _selectionExpression = selectedNode;
          // additional check for closure
          if (_selectionExpression is FunctionExpression) {
            _selectionFunctionExpression =
                _selectionExpression as FunctionExpression;
            _selectionExpression = null;
          }
          // OK
          return new RefactoringStatus();
        }
      }
      // statements selected
      {
        List<Statement> selectedStatements = [];
        for (AstNode selectedNode in selectedNodes) {
          if (selectedNode is Statement) {
            selectedStatements.add(selectedNode);
          }
        }
        if (selectedStatements.length == selectedNodes.length) {
          _selectionStatements = selectedStatements;
          return new RefactoringStatus();
        }
      }
    }
    // invalid selection
    return new RefactoringStatus.fatal(
        'Can only extract a single expression or a set of statements.');
  }

  /**
   * Returns the selected [Expression] source, with applying new parameter
   * names.
   */
  String _getMethodBodySource() {
    String source = utils.getRangeText(selectionRange);
    // prepare operations to replace variables with parameters
    List<SourceEdit> replaceEdits = [];
    for (RefactoringMethodParameter parameter in _parameters) {
      List<SourceRange> ranges = _parameterReferencesMap[parameter.id];
      if (ranges != null) {
        for (SourceRange range in ranges) {
          replaceEdits.add(
              new SourceEdit(
                  range.offset - selectionRange.offset,
                  range.length,
                  parameter.name));
        }
      }
    }
    replaceEdits.sort((a, b) => b.offset - a.offset);
    // apply replacements
    source = SourceEdit.applySequence(source, replaceEdits);
    // change indentation
    if (_selectionFunctionExpression != null) {
      AstNode baseNode =
          _selectionFunctionExpression.getAncestor((node) => node is Statement);
      if (baseNode != null) {
        String baseIndent = utils.getNodePrefix(baseNode);
        String targetIndent = utils.getNodePrefix(_parentMember);
        source = utils.replaceSourceIndent(source, baseIndent, targetIndent);
        source = source.trim();
      }
    }
    if (_selectionStatements != null) {
      String selectionIndent = utils.getNodePrefix(_selectionStatements[0]);
      String targetIndent = utils.getNodePrefix(_parentMember) + '  ';
      source = utils.replaceSourceIndent(source, selectionIndent, targetIndent);
    }
    // done
    return source;
  }

  _SourcePattern _getSourcePattern(SourceRange range) {
    String originalSource = utils.getText(range.offset, range.length);
    _SourcePattern pattern = new _SourcePattern();
    List<SourceEdit> replaceEdits = <SourceEdit>[];
    unit.accept(new _GetSourcePatternVisitor(range, pattern, replaceEdits));
    replaceEdits = replaceEdits.reversed.toList();
    pattern.patternSource =
        SourceEdit.applySequence(originalSource, replaceEdits);
    return pattern;
  }

  /**
   * Initializes [createGetter] flag.
   */
  void _initializeGetter() {
    createGetter = false;
    // maybe we cannot at all
    if (!canCreateGetter) {
      return;
    }
    // OK, just expression
    if (_selectionExpression != null) {
      createGetter = !_hasMethodInvocation(_selectionExpression);
      return;
    }
    // allow code blocks without cycles
    if (_selectionStatements != null) {
      createGetter = true;
      for (Statement statement in _selectionStatements) {
        // method invocation is something heavy,
        // so we don't want to extract it as a part of a getter
        if (_hasMethodInvocation(statement)) {
          createGetter = false;
          return;
        }
        // don't allow cycles
        statement.accept(new _ResetCanCreateGetterVisitor(this));
      }
    }
  }

  /**
   * Fills [_occurrences] field.
   */
  void _initializeOccurrences() {
    _occurrences.clear();
    // prepare selection
    _SourcePattern selectionPattern = _getSourcePattern(selectionRange);
    String selectionSource =
        _getNormalizedSource(selectionPattern.patternSource);
    Map<String, String> patternToSelectionName =
        _inverseMap(selectionPattern.originalToPatternNames);
    // prepare an enclosing parent - class or unit
    AstNode enclosingMemberParent = _parentMember.parent;
    // visit nodes which will able to access extracted method
    enclosingMemberParent.accept(
        new _InitializeOccurrencesVisitor(
            this,
            selectionSource,
            patternToSelectionName));
  }

  /**
   * Prepares information about used variables, which should be turned into
   * parameters.
   */
  RefactoringStatus _initializeParameters() {
    _parameters.clear();
    _parametersMap.clear();
    _parameterReferencesMap.clear();
    RefactoringStatus result = new RefactoringStatus();
    List<VariableElement> assignedUsedVariables = [];
    unit.accept(new _InitializeParametersVisitor(this, assignedUsedVariables));
    // single expression
    if (_selectionExpression != null) {
      _returnType = _selectionExpression.bestType;
    }
    // may be ends with "return" statement
    if (_selectionStatements != null) {
      _ReturnTypeComputer returnTypeComputer = new _ReturnTypeComputer();
      _selectionStatements.forEach((statement) {
        statement.accept(returnTypeComputer);
      });
      _returnType = returnTypeComputer.returnType;
    }
    // may be single variable to return
    if (assignedUsedVariables.length == 1) {
      // we cannot both return variable and have explicit return statement
      if (_returnType != null) {
        result.addFatalError(
            'Ambiguous return value: Selected block contains assignment(s) to '
                'local variables and return statement.');
        return result;
      }
      // prepare to return an assigned variable
      VariableElement returnVariable = assignedUsedVariables[0];
      _returnType = returnVariable.type;
      _returnVariableName = returnVariable.displayName;
    }
    // fatal, if multiple variables assigned and used after selection
    if (assignedUsedVariables.length > 1) {
      StringBuffer sb = new StringBuffer();
      for (VariableElement variable in assignedUsedVariables) {
        sb.write(variable.displayName);
        sb.write('\n');
      }
      result.addFatalError(
          format(
              'Ambiguous return value: Selected block contains more than one '
                  'assignment to local variables. Affected variables are:\n\n{0}',
              sb.toString().trim()));
    }
    // done
    return result;
  }

  void _initializeReturnType() {
    if (_returnType == null) {
      returnType = 'void';
    } else {
      Set<LibraryElement> librariesToImport = new Set<LibraryElement>();
      // TODO(scheglov) use librariesToImport
      returnType = utils.getTypeSource(_returnType, librariesToImport);
    }
    if (returnType == 'dynamic') {
      returnType = '';
    }
  }

  /**
   * Checks if the given [VariableElement] is declared in [selectionRange].
   */
  bool _isDeclaredInSelection(VariableElement element) {
    return selectionRange.contains(element.nameOffset);
  }

  /**
   * Checks if it is OK to extract the node with the given [SourceRange].
   */
  bool _isExtractable(SourceRange range) {
    _ExtractMethodAnalyzer analyzer = new _ExtractMethodAnalyzer(unit, range);
    utils.unit.accept(analyzer);
    return analyzer.status.isOK;
  }

  /**
   * Checks if [element] is referenced after [selectionRange].
   */
  bool _isUsedAfterSelection(VariableElement element) {
    var visitor = new _IsUsedAfterSelectionVisitor(this, element);
    _parentMember.accept(visitor);
    return visitor.result;
  }

  /**
   * Prepare names that are used in the enclosing function, so should not be
   * proposed as names of the extracted method.
   */
  void _prepareExcludedNames() {
    _excludedNames.clear();
    ExecutableElement enclosingExecutable =
        getEnclosingExecutableElement(_parentMember);
    if (enclosingExecutable != null) {
      visitChildren(enclosingExecutable, (Element element) {
        if (element is LocalElement) {
          SourceRange elementRange = element.visibleRange;
          if (elementRange != null) {
            _excludedNames.add(element.displayName);
          }
        }
        return true;
      });
    }
  }

  void _prepareNames() {
    names.clear();
    if (_selectionExpression != null) {
      names.addAll(
          getVariableNameSuggestionsForExpression(
              _selectionExpression.staticType,
              _selectionExpression,
              _excludedNames));
    }
  }

  void _prepareOffsetsLengths() {
    offsets.clear();
    lengths.clear();
    for (_Occurrence occurrence in _occurrences) {
      offsets.add(occurrence.range.offset);
      lengths.add(occurrence.range.length);
    }
  }

  /**
   * Checks if [node] has a [MethodInvocation].
   */
  static bool _hasMethodInvocation(AstNode node) {
    var visitor = new _HasMethodInvocationVisitor();
    node.accept(visitor);
    return visitor.result;
  }
}


/**
 * [SelectionAnalyzer] for [ExtractMethodRefactoringImpl].
 */
class _ExtractMethodAnalyzer extends StatementAnalyzer {
  _ExtractMethodAnalyzer(CompilationUnit unit, SourceRange selection)
      : super(unit, selection);

  @override
  void handleNextSelectedNode(AstNode node) {
    super.handleNextSelectedNode(node);
    _checkParent(node);
  }

  @override
  void handleSelectionEndsIn(AstNode node) {
    super.handleSelectionEndsIn(node);
    invalidSelection(
        'The selection does not cover a set of statements or an expression. '
            'Extend selection to a valid range.');
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    super.visitAssignmentExpression(node);
    Expression lhs = node.leftHandSide;
    if (_isFirstSelectedNode(lhs)) {
      invalidSelection(
          'Cannot extract the left-hand side of an assignment.',
          newLocation_fromNode(lhs));
    }
    return null;
  }

  @override
  Object visitConstructorInitializer(ConstructorInitializer node) {
    super.visitConstructorInitializer(node);
    if (_isFirstSelectedNode(node)) {
      invalidSelection(
          'Cannot extract a constructor initializer. '
              'Select expression part of initializer.',
          newLocation_fromNode(node));
    }
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
    super.visitForStatement(node);
    if (identical(node.variables, firstSelectedNode)) {
      invalidSelection(
          "Cannot extract initialization part of a 'for' statement.");
    } else if (node.updaters.contains(lastSelectedNode)) {
      invalidSelection("Cannot extract increment part of a 'for' statement.");
    }
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    if (_isFirstSelectedNode(node)) {
      // name of declaration
      if (node.inDeclarationContext()) {
        invalidSelection('Cannot extract the name part of a declaration.');
      }
      // method name
      Element element = node.bestElement;
      if (element is FunctionElement || element is MethodElement) {
        invalidSelection('Cannot extract a single method name.');
      }
      // name in property access
      if (node.parent is PrefixedIdentifier &&
          (node.parent as PrefixedIdentifier).identifier == node) {
        invalidSelection('Can not extract name part of a property access.');
      }
    }
    return null;
  }

  @override
  Object visitTypeName(TypeName node) {
    super.visitTypeName(node);
    if (_isFirstSelectedNode(node)) {
      invalidSelection('Cannot extract a single type reference.');
    }
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    if (_isFirstSelectedNode(node)) {
      invalidSelection(
          'Cannot extract a variable declaration fragment. '
              'Select whole declaration statement.',
          newLocation_fromNode(node));
    }
    return null;
  }

  void _checkParent(AstNode node) {
    AstNode firstParent = firstSelectedNode.parent;
    do {
      node = node.parent;
      if (identical(node, firstParent)) {
        return;
      }
    } while (node != null);
    invalidSelection(
        'Not all selected statements are enclosed by the same parent statement.');
  }

  bool _isFirstSelectedNode(AstNode node) => identical(firstSelectedNode, node);
}


class _GetSourcePatternVisitor extends GeneralizingAstVisitor {
  final SourceRange partRange;
  final _SourcePattern pattern;
  final List<SourceEdit> replaceEdits;

  _GetSourcePatternVisitor(this.partRange, this.pattern, this.replaceEdits);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    SourceRange nodeRange = rangeNode(node);
    if (partRange.covers(nodeRange)) {
      VariableElement variableElement =
          getLocalOrParameterVariableElement(node);
      if (variableElement != null) {
        // name of a named expression
        if (isNamedExpressionName(node)) {
          return;
        }
        // continue
        String originalName = variableElement.displayName;
        String patternName = pattern.originalToPatternNames[originalName];
        if (patternName == null) {
          patternName = '__refVar${pattern.originalToPatternNames.length}';
          pattern.originalToPatternNames[originalName] = patternName;
        }
        replaceEdits.add(
            new SourceEdit(
                nodeRange.offset - partRange.offset,
                nodeRange.length,
                patternName));
      }
    }
  }
}



class _HasMethodInvocationVisitor extends RecursiveAstVisitor {
  bool result = false;

  @override
  visitMethodInvocation(MethodInvocation node) {
    result = true;
  }
}


class _InitializeOccurrencesVisitor extends GeneralizingAstVisitor<Object> {
  final ExtractMethodRefactoringImpl ref;
  final String selectionSource;
  final Map<String, String> patternToSelectionName;

  bool forceStatic = false;

  _InitializeOccurrencesVisitor(this.ref, this.selectionSource,
      this.patternToSelectionName);

  @override
  Object visitBlock(Block node) {
    if (ref._selectionStatements != null) {
      _visitStatements(node.statements);
    }
    return super.visitBlock(node);
  }

  @override
  Object visitConstructorInitializer(ConstructorInitializer node) {
    forceStatic = true;
    try {
      return super.visitConstructorInitializer(node);
    } finally {
      forceStatic = false;
    }
  }

  @override
  Object visitExpression(Expression node) {
    if (ref._selectionFunctionExpression != null ||
        ref._selectionExpression != null &&
            node.runtimeType == ref._selectionExpression.runtimeType) {
      SourceRange nodeRange = rangeNode(node);
      _tryToFindOccurrence(nodeRange);
    }
    return super.visitExpression(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    forceStatic = node.isStatic;
    try {
      return super.visitMethodDeclaration(node);
    } finally {
      forceStatic = false;
    }
  }

  @override
  Object visitSwitchMember(SwitchMember node) {
    if (ref._selectionStatements != null) {
      _visitStatements(node.statements);
    }
    return super.visitSwitchMember(node);
  }

  /**
   * Checks if given [SourceRange] matched selection source and adds [_Occurrence].
   */
  bool _tryToFindOccurrence(SourceRange nodeRange) {
    // check if can be extracted
    if (!ref._isExtractable(nodeRange)) {
      return false;
    }
    // prepare normalized node source
    _SourcePattern nodePattern = ref._getSourcePattern(nodeRange);
    String nodeSource = _getNormalizedSource(nodePattern.patternSource);
    // if matches normalized node source, then add as occurrence
    if (nodeSource == selectionSource) {
      _Occurrence occurrence =
          new _Occurrence(nodeRange, ref.selectionRange.intersects(nodeRange));
      ref._occurrences.add(occurrence);
      // prepare mapping of parameter names to the occurrence variables
      nodePattern.originalToPatternNames.forEach(
          (String originalName, String patternName) {
        String selectionName = patternToSelectionName[patternName];
        occurrence._parameterOldToOccurrenceName[selectionName] = originalName;
      });
      // update static
      if (forceStatic) {
        ref._staticContext = true;
      }
      // we have match
      return true;
    }
    // no match
    return false;
  }

  void _visitStatements(List<Statement> statements) {
    int beginStatementIndex = 0;
    int selectionCount = ref._selectionStatements.length;
    while (beginStatementIndex + selectionCount <= statements.length) {
      SourceRange nodeRange = rangeStartEnd(
          statements[beginStatementIndex],
          statements[beginStatementIndex + selectionCount - 1]);
      bool found = _tryToFindOccurrence(nodeRange);
      // next statement
      if (found) {
        beginStatementIndex += selectionCount;
      } else {
        beginStatementIndex++;
      }
    }
  }
}


class _InitializeParametersVisitor extends GeneralizingAstVisitor<Object> {
  final ExtractMethodRefactoringImpl ref;
  final List<VariableElement> assignedUsedVariables;

  _InitializeParametersVisitor(this.ref, this.assignedUsedVariables);

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    SourceRange nodeRange = rangeNode(node);
    if (ref.selectionRange.covers(nodeRange)) {
      // analyze local variable
      VariableElement variableElement =
          getLocalOrParameterVariableElement(node);
      if (variableElement != null) {
        // name of the named expression
        if (isNamedExpressionName(node)) {
          return null;
        }
        // if declared outside, add parameter
        if (!ref._isDeclaredInSelection(variableElement)) {
          String variableName = variableElement.displayName;
          // add parameter
          RefactoringMethodParameter parameter =
              ref._parametersMap[variableName];
          if (parameter == null) {
            DartType parameterType = node.bestType;
            Set<LibraryElement> librariesToImport = new Set<LibraryElement>();
            // TODO(scheglov) use librariesToImport
            String parameterTypeName =
                ref.utils.getTypeSource(parameterType, librariesToImport);
            parameter = new RefactoringMethodParameter(
                RefactoringMethodParameterKind.REQUIRED,
                parameterTypeName,
                variableName,
                id: variableName);
            ref._parameters.add(parameter);
            ref._parametersMap[variableName] = parameter;
          }
          // add reference to parameter
          ref._addParameterReference(variableName, nodeRange);
        }
        // remember, if assigned and used after selection
        if (isLeftHandOfAssignment(node) &&
            ref._isUsedAfterSelection(variableElement)) {
          if (!assignedUsedVariables.contains(variableElement)) {
            assignedUsedVariables.add(variableElement);
          }
        }
      }
      // remember declaration names
      if (node.inDeclarationContext()) {
        ref._usedNames.add(node.name);
      }
    }
    return null;
  }
}

class _IsUsedAfterSelectionVisitor extends GeneralizingAstVisitor {
  final ExtractMethodRefactoringImpl ref;
  final VariableElement element;
  bool result = false;

  _IsUsedAfterSelectionVisitor(this.ref, this.element);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    VariableElement nodeElement = getLocalVariableElement(node);
    if (identical(nodeElement, element)) {
      int nodeOffset = node.offset;
      if (nodeOffset > ref.selectionRange.end) {
        result = true;
      }
    }
  }
}


/**
 * Description of a single occurrence of the selected expression or set of
 * statements.
 */
class _Occurrence {
  final SourceRange range;
  final bool isSelection;

  Map<String, String> _parameterOldToOccurrenceName = <String, String>{};

  _Occurrence(this.range, this.isSelection);
}


class _ResetCanCreateGetterVisitor extends RecursiveAstVisitor {
  final ExtractMethodRefactoringImpl ref;

  _ResetCanCreateGetterVisitor(this.ref);

  @override
  visitDoStatement(DoStatement node) {
    ref.createGetter = false;
    super.visitDoStatement(node);
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    ref.createGetter = false;
    super.visitForEachStatement(node);
  }

  @override
  visitForStatement(ForStatement node) {
    ref.createGetter = false;
    super.visitForStatement(node);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    ref.createGetter = false;
    super.visitWhileStatement(node);
  }
}


class _ReturnTypeComputer extends RecursiveAstVisitor {
  DartType returnType;

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    // prepare expression
    Expression expression = node.expression;
    if (expression == null) {
      return;
    }
    // prepare type
    DartType type = expression.bestType;
    if (type.isBottom) {
      return;
    }
    // combine types
    if (returnType == null) {
      returnType = type;
    } else {
      if (returnType is InterfaceType && type is InterfaceType) {
        returnType = InterfaceType.getSmartLeastUpperBound(returnType, type);
      } else {
        returnType = returnType.getLeastUpperBound(type);
      }
    }
  }
}


/**
 * Generalized version of some source, in which references to the specific
 * variables are replaced with pattern variables, with back mapping from the
 * pattern to the original variable names.
 */
class _SourcePattern {
  String patternSource;
  Map<String, String> originalToPatternNames = {};
}
