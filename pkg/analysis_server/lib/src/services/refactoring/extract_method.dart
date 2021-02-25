// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analysis_server/src/services/correction/selection_analyzer.dart';
import 'package:analysis_server/src/services/correction/statement_analyzer.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/rename_class_member.dart';
import 'package:analysis_server/src/services/refactoring/rename_unit_member.dart';
import 'package:analysis_server/src/services/refactoring/visible_ranges_computer.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/resolver/exit_detector.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

const String _TOKEN_SEPARATOR = '\uFFFF';

Element _getLocalElement(SimpleIdentifier node) {
  var element = node.writeOrReadElement;
  if (element is LocalVariableElement ||
      element is ParameterElement ||
      element is FunctionElement &&
          element.enclosingElement is! CompilationUnitElement) {
    return element;
  }
  return null;
}

/// Returns the "normalized" version of the given source, which is reconstructed
/// from tokens, so ignores all the comments and spaces.
String _getNormalizedSource(String src, FeatureSet featureSet) {
  var selectionTokens = TokenUtils.getTokens(src, featureSet);
  return selectionTokens.join(_TOKEN_SEPARATOR);
}

/// Returns the [Map] which maps [map] values to their keys.
Map<String, String> _inverseMap(Map<String, String> map) {
  var result = <String, String>{};
  map.forEach((String key, String value) {
    result[value] = key;
  });
  return result;
}

/// [ExtractMethodRefactoring] implementation.
class ExtractMethodRefactoringImpl extends RefactoringImpl
    implements ExtractMethodRefactoring {
  static const ERROR_EXITS =
      'Selected statements contain a return statement, but not all possible '
      'execution flows exit. Semantics may not be preserved.';

  final SearchEngine searchEngine;
  final ResolvedUnitResult resolveResult;
  final int selectionOffset;
  final int selectionLength;
  SourceRange selectionRange;
  CorrectionUtils utils;
  final Set<Source> librariesToImport = <Source>{};

  @override
  String returnType = '';
  String variableType;
  String name;
  bool extractAll = true;
  @override
  bool canCreateGetter = false;
  bool createGetter = false;
  @override
  final List<String> names = <String>[];
  @override
  final List<int> offsets = <int>[];
  @override
  final List<int> lengths = <int>[];

  /// The map of local elements to their visibility ranges.
  Map<LocalElement, SourceRange> _visibleRangeMap;

  /// The map of local names to their visibility ranges.
  final Map<String, List<SourceRange>> _localNames =
      <String, List<SourceRange>>{};

  /// The set of names that are referenced without any qualifier.
  final Set<String> _unqualifiedNames = <String>{};

  final Set<String> _excludedNames = <String>{};
  List<RefactoringMethodParameter> _parameters = <RefactoringMethodParameter>[];
  final Map<String, RefactoringMethodParameter> _parametersMap =
      <String, RefactoringMethodParameter>{};
  final Map<String, List<SourceRange>> _parameterReferencesMap =
      <String, List<SourceRange>>{};
  bool _hasAwait = false;
  DartType _returnType;
  String _returnVariableName;
  AstNode _parentMember;
  Expression _selectionExpression;
  FunctionExpression _selectionFunctionExpression;
  List<Statement> _selectionStatements;
  final List<_Occurrence> _occurrences = [];
  bool _staticContext = false;

  ExtractMethodRefactoringImpl(this.searchEngine, this.resolveResult,
      this.selectionOffset, this.selectionLength) {
    selectionRange = SourceRange(selectionOffset, selectionLength);
    utils = CorrectionUtils(resolveResult);
  }

  @override
  List<RefactoringMethodParameter> get parameters => _parameters;

  @override
  set parameters(List<RefactoringMethodParameter> parameters) {
    _parameters = parameters.toList();
  }

  @override
  String get refactoringName {
    var node = NodeLocator(selectionOffset).searchWithin(resolveResult.unit);
    if (node != null && node.thisOrAncestorOfType<ClassDeclaration>() != null) {
      return 'Extract Method';
    }
    return 'Extract Function';
  }

  String get signature {
    var sb = StringBuffer();
    if (createGetter) {
      sb.write('get ');
      sb.write(name);
    } else {
      sb.write(name);
      sb.write('(');
      // add all parameters
      var firstParameter = true;
      for (var parameter in _parameters) {
        // may be comma
        if (firstParameter) {
          firstParameter = false;
        } else {
          sb.write(', ');
        }
        // type
        {
          var typeSource = parameter.type;
          if ('dynamic' != typeSource && '' != typeSource) {
            sb.write(typeSource);
            sb.write(' ');
          }
        }
        // name
        sb.write(parameter.name);
        // optional function-typed parameter parameters
        if (parameter.parameters != null) {
          sb.write(parameter.parameters);
        }
      }
      sb.write(')');
    }
    // done
    return sb.toString();
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();
    result.addStatus(validateMethodName(name));
    result.addStatus(_checkParameterNames());
    var status = await _checkPossibleConflicts();
    result.addStatus(status);
    return result;
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    var result = RefactoringStatus();
    // selection
    result.addStatus(_checkSelection());
    if (result.hasFatalError) {
      return result;
    }
    // prepare parts
    var status = await _initializeParameters();
    result.addStatus(status);
    _initializeHasAwait();
    await _initializeReturnType();
    // occurrences
    _initializeOccurrences();
    _prepareOffsetsLengths();
    // getter
    canCreateGetter = _computeCanCreateGetter();
    createGetter =
        canCreateGetter && _isExpressionForGetter(_selectionExpression);
    // names
    _prepareExcludedNames();
    _prepareNames();
    // closure cannot have parameters
    if (_selectionFunctionExpression != null && _parameters.isNotEmpty) {
      var message = format(
          'Cannot extract closure as method, it references {0} external variable(s).',
          _parameters.length);
      return RefactoringStatus.fatal(message);
    }
    return result;
  }

  @override
  RefactoringStatus checkName() {
    return validateMethodName(name);
  }

  @override
  Future<SourceChange> createChange() async {
    var change = SourceChange(refactoringName);
    // replace occurrences with method invocation
    for (var occurrence in _occurrences) {
      var range = occurrence.range;
      // may be replacement of duplicates disabled
      if (!extractAll && !occurrence.isSelection) {
        continue;
      }
      // prepare invocation source
      String invocationSource;
      if (_selectionFunctionExpression != null) {
        invocationSource = name;
      } else {
        var sb = StringBuffer();
        // may be returns value
        if (_selectionStatements != null && variableType != null) {
          // single variable assignment / return statement
          if (_returnVariableName != null) {
            var occurrenceName =
                occurrence._parameterOldToOccurrenceName[_returnVariableName];
            // may be declare variable
            if (!_parametersMap.containsKey(_returnVariableName)) {
              if (variableType.isEmpty) {
                sb.write('var ');
              } else {
                sb.write(variableType);
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
        // await
        if (_hasAwait) {
          sb.write('await ');
        }
        // invocation itself
        sb.write(name);
        if (!createGetter) {
          sb.write('(');
          var firstParameter = true;
          for (var parameter in _parameters) {
            // may be comma
            if (firstParameter) {
              firstParameter = false;
            } else {
              sb.write(', ');
            }
            // argument name
            {
              var argumentName =
                  occurrence._parameterOldToOccurrenceName[parameter.id];
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
      var edit = newSourceEdit_range(range, invocationSource);
      doSourceChange_addElementEdit(
          change, resolveResult.unit.declaredElement, edit);
    }
    // add method declaration
    {
      // prepare environment
      var prefix = utils.getNodePrefix(_parentMember);
      var eol = utils.endOfLine;
      // prepare annotations
      var annotations = '';
      {
        // may be "static"
        if (_staticContext) {
          annotations = 'static ';
        }
      }
      // prepare declaration source
      String declarationSource;
      {
        var returnExpressionSource = _getMethodBodySource();
        // closure
        if (_selectionFunctionExpression != null) {
          var returnTypeCode = _getExpectedClosureReturnTypeCode();
          declarationSource = '$returnTypeCode$name$returnExpressionSource';
          if (_selectionFunctionExpression.body is ExpressionFunctionBody) {
            declarationSource += ';';
          }
        }
        // optional 'async' body modifier
        var asyncKeyword = _hasAwait ? ' async' : '';
        // expression
        if (_selectionExpression != null) {
          var isMultiLine = returnExpressionSource.contains(eol);

          // We generate the method body using the shorthand syntax if it fits
          // into a single line and use the regular method syntax otherwise.
          if (!isMultiLine) {
            // add return type
            if (returnType.isNotEmpty) {
              annotations += '$returnType ';
            }
            // just return expression
            declarationSource = '$annotations$signature$asyncKeyword => ';
            declarationSource += '$returnExpressionSource;';
          } else {
            // Left indent once; returnExpressionSource was indented for method
            // shorthands.
            returnExpressionSource = utils
                .indentSourceLeftRight('${returnExpressionSource.trim()};')
                .trim();

            // add return type
            if (returnType.isNotEmpty) {
              annotations += '$returnType ';
            }
            declarationSource = '$annotations$signature$asyncKeyword {$eol';
            declarationSource += '$prefix  ';
            if (returnType.isNotEmpty) {
              declarationSource += 'return ';
            }
            declarationSource += '$returnExpressionSource$eol$prefix}';
          }
        }
        // statements
        if (_selectionStatements != null) {
          if (returnType.isNotEmpty) {
            annotations += returnType + ' ';
          }
          declarationSource = '$annotations$signature$asyncKeyword {$eol';
          declarationSource += returnExpressionSource;
          if (_returnVariableName != null) {
            declarationSource += '$prefix  return $_returnVariableName;$eol';
          }
          declarationSource += '$prefix}';
        }
      }
      // insert declaration
      if (declarationSource != null) {
        var offset = _parentMember.end;
        var edit = SourceEdit(offset, 0, '$eol$eol$prefix$declarationSource');
        doSourceChange_addElementEdit(
            change, resolveResult.unit.declaredElement, edit);
      }
    }
    // done
    await addLibraryImports(resolveResult.session, change,
        resolveResult.libraryElement, librariesToImport);
    return change;
  }

  @override
  bool isAvailable() {
    return !_checkSelection().hasFatalError;
  }

  /// Adds a new reference to the parameter with the given name.
  void _addParameterReference(String name, SourceRange range) {
    var references = _parameterReferencesMap[name];
    if (references == null) {
      references = [];
      _parameterReferencesMap[name] = references;
    }
    references.add(range);
  }

  RefactoringStatus _checkParameterNames() {
    var result = RefactoringStatus();
    for (var parameter in _parameters) {
      result.addStatus(validateParameterName(parameter.name));
      for (var other in _parameters) {
        if (!identical(parameter, other) && other.name == parameter.name) {
          result.addError(
              format("Parameter '{0}' already exists", parameter.name));
          return result;
        }
      }
      if (_isParameterNameConflictWithBody(parameter)) {
        result.addError(format(
            "'{0}' is already used as a name in the selected code",
            parameter.name));
        return result;
      }
    }
    return result;
  }

  /// Checks if created method will shadow or will be shadowed by other
  /// elements.
  Future<RefactoringStatus> _checkPossibleConflicts() async {
    var result = RefactoringStatus();
    var parent = _parentMember.parent;
    // top-level function
    if (parent is CompilationUnit) {
      var libraryElement = parent.declaredElement.library;
      return validateCreateFunction(searchEngine, libraryElement, name);
    }
    // method of class
    if (parent is ClassDeclaration) {
      var classElement = parent.declaredElement;
      return validateCreateMethod(searchEngine,
          AnalysisSessionHelper(resolveResult.session), classElement, name);
    }
    // OK
    return Future<RefactoringStatus>.value(result);
  }

  /// Checks if [selectionRange] selects [Expression] which can be extracted,
  /// and location of this [DartExpression] in AST allows extracting.
  RefactoringStatus _checkSelection() {
    if (selectionOffset <= 0) {
      return RefactoringStatus.fatal(
          'The selection offset must be greater than zero.');
    }
    if (selectionOffset + selectionLength >= resolveResult.content.length) {
      return RefactoringStatus.fatal(
          'The selection end offset must be less then the length of the file.');
    }

    // Check for implicitly selected closure.
    {
      var function = _findFunctionExpression();
      if (function != null) {
        _selectionFunctionExpression = function;
        selectionRange = range.node(function);
        _parentMember = getEnclosingClassOrUnitMember(function);
        return RefactoringStatus();
      }
    }

    var analyzer = _ExtractMethodAnalyzer(resolveResult, selectionRange);
    analyzer.analyze();
    // May be a fatal error.
    {
      if (analyzer.status.hasFatalError) {
        return analyzer.status;
      }
    }

    var selectedNodes = analyzer.selectedNodes;

    // If no selected nodes, extract the smallest covering expression.
    if (selectedNodes.isEmpty) {
      for (var node = analyzer.coveringNode; node != null; node = node.parent) {
        if (node is Statement) {
          break;
        }
        if (node is Expression && _isExtractable(range.node(node))) {
          selectedNodes.add(node);
          selectionRange = range.node(node);
          break;
        }
      }
    }

    // Check selected nodes.
    if (selectedNodes.isNotEmpty) {
      var selectedNode = selectedNodes.first;
      _parentMember = getEnclosingClassOrUnitMember(selectedNode);
      // single expression selected
      if (selectedNodes.length == 1) {
        if (!utils.selectionIncludesNonWhitespaceOutsideNode(
            selectionRange, selectedNode)) {
          if (selectedNode is Expression) {
            _selectionExpression = selectedNode;
            // additional check for closure
            if (_selectionExpression is FunctionExpression) {
              _selectionFunctionExpression =
                  _selectionExpression as FunctionExpression;
              _selectionExpression = null;
            }
            // OK
            return RefactoringStatus();
          }
        }
      }
      // statements selected
      {
        var selectedStatements = <Statement>[];
        for (var selectedNode in selectedNodes) {
          if (selectedNode is Statement) {
            selectedStatements.add(selectedNode);
          }
        }
        if (selectedStatements.length == selectedNodes.length) {
          _selectionStatements = selectedStatements;
          return RefactoringStatus();
        }
      }
    }
    // invalid selection
    return RefactoringStatus.fatal(
        'Can only extract a single expression or a set of statements.');
  }

  /// Initializes [canCreateGetter] flag.
  bool _computeCanCreateGetter() {
    // is a function expression
    if (_selectionFunctionExpression != null) {
      return false;
    }
    // has parameters
    if (parameters.isNotEmpty) {
      return false;
    }
    // is assignment
    if (_selectionExpression != null) {
      if (_selectionExpression is AssignmentExpression) {
        return false;
      }
    }
    // doesn't return a value
    if (_selectionStatements != null) {
      return returnType != 'void';
    }
    // OK
    return true;
  }

  /// If the [selectionRange] is associated with a [FunctionExpression], return
  /// this [FunctionExpression].
  FunctionExpression _findFunctionExpression() {
    if (selectionRange.length != 0) {
      return null;
    }
    var offset = selectionRange.offset;
    var node = NodeLocator2(offset, offset).searchWithin(resolveResult.unit);

    // Check for the parameter list of a FunctionExpression.
    {
      var function = node?.thisOrAncestorOfType<FunctionExpression>();
      if (function != null &&
          function.parameters != null &&
          range.node(function.parameters).contains(offset)) {
        return function;
      }
    }

    // Check for the name of the named argument with the closure expression.
    if (node is SimpleIdentifier &&
        node.parent is Label &&
        node.parent.parent is NamedExpression) {
      NamedExpression namedExpression = node.parent.parent;
      var expression = namedExpression.expression;
      if (expression is FunctionExpression) {
        return expression;
      }
    }

    return null;
  }

  /// If the selected closure (i.e. [_selectionFunctionExpression]) is an
  /// argument for a function typed parameter (as it should be), and the
  /// function type has the return type specified, return this return type's
  /// code. Otherwise return the empty string.
  String _getExpectedClosureReturnTypeCode() {
    Expression argument = _selectionFunctionExpression;
    if (argument.parent is NamedExpression) {
      argument = argument.parent as NamedExpression;
    }
    var parameter = argument.staticParameterElement;
    if (parameter != null) {
      var parameterType = parameter.type;
      if (parameterType is FunctionType) {
        var typeCode = _getTypeCode(parameterType.returnType);
        if (typeCode != 'dynamic') {
          return typeCode + ' ';
        }
      }
    }
    return '';
  }

  /// Returns the selected [Expression] source, with applying new parameter
  /// names.
  String _getMethodBodySource() {
    var source = utils.getRangeText(selectionRange);
    // prepare operations to replace variables with parameters
    var replaceEdits = <SourceEdit>[];
    for (var parameter in _parameters) {
      var ranges = _parameterReferencesMap[parameter.id];
      if (ranges != null) {
        for (var range in ranges) {
          replaceEdits.add(SourceEdit(range.offset - selectionRange.offset,
              range.length, parameter.name));
        }
      }
    }
    replaceEdits.sort((a, b) => b.offset - a.offset);
    // apply replacements
    source = SourceEdit.applySequence(source, replaceEdits);
    // change indentation
    if (_selectionFunctionExpression != null) {
      AstNode baseNode =
          _selectionFunctionExpression.thisOrAncestorOfType<Statement>();
      if (baseNode != null) {
        var baseIndent = utils.getNodePrefix(baseNode);
        var targetIndent = utils.getNodePrefix(_parentMember);
        source = utils.replaceSourceIndent(source, baseIndent, targetIndent);
        source = source.trim();
      }
    }
    if (_selectionStatements != null) {
      var selectionIndent = utils.getNodePrefix(_selectionStatements[0]);
      var targetIndent = utils.getNodePrefix(_parentMember) + '  ';
      source = utils.replaceSourceIndent(source, selectionIndent, targetIndent);
    }
    // done
    return source;
  }

  _SourcePattern _getSourcePattern(SourceRange range) {
    var originalSource = utils.getText(range.offset, range.length);
    var pattern = _SourcePattern();
    var replaceEdits = <SourceEdit>[];
    resolveResult.unit
        .accept(_GetSourcePatternVisitor(range, pattern, replaceEdits));
    replaceEdits = replaceEdits.reversed.toList();
    var source = SourceEdit.applySequence(originalSource, replaceEdits);
    pattern.normalizedSource =
        _getNormalizedSource(source, resolveResult.unit.featureSet);
    return pattern;
  }

  String _getTypeCode(DartType type) {
    return utils.getTypeSource(type, librariesToImport);
  }

  void _initializeHasAwait() {
    var visitor = _HasAwaitVisitor();
    if (_selectionExpression != null) {
      _selectionExpression.accept(visitor);
    } else if (_selectionStatements != null) {
      _selectionStatements.forEach((statement) {
        statement.accept(visitor);
      });
    }
    _hasAwait = visitor.result;
  }

  /// Fills [_occurrences] field.
  void _initializeOccurrences() {
    _occurrences.clear();
    // prepare selection
    var selectionPattern = _getSourcePattern(selectionRange);
    var patternToSelectionName =
        _inverseMap(selectionPattern.originalToPatternNames);
    // prepare an enclosing parent - class or unit
    var enclosingMemberParent = _parentMember.parent;
    // visit nodes which will able to access extracted method
    enclosingMemberParent.accept(_InitializeOccurrencesVisitor(
        this, selectionPattern, patternToSelectionName));
  }

  /// Prepares information about used variables, which should be turned into
  /// parameters.
  Future<RefactoringStatus> _initializeParameters() async {
    _parameters.clear();
    _parametersMap.clear();
    _parameterReferencesMap.clear();
    var result = RefactoringStatus();
    var assignedUsedVariables = <VariableElement>[];

    var unit = resolveResult.unit;
    _visibleRangeMap = VisibleRangesComputer.forNode(unit);
    unit.accept(
      _InitializeParametersVisitor(this, assignedUsedVariables),
    );

    // single expression
    if (_selectionExpression != null) {
      _returnType = _selectionExpression.staticType;
    }
    // verify that none or all execution flows end with a "return"
    if (_selectionStatements != null) {
      var hasReturn = _selectionStatements.any(_mayEndWithReturnStatement);
      if (hasReturn && !ExitDetector.exits(_selectionStatements.last)) {
        result.addError(ERROR_EXITS);
      }
    }
    // maybe ends with "return" statement
    if (_selectionStatements != null) {
      var typeSystem = resolveResult.typeSystem;
      var returnTypeComputer = _ReturnTypeComputer(typeSystem);
      _selectionStatements.forEach((statement) {
        statement.accept(returnTypeComputer);
      });
      _returnType = returnTypeComputer.returnType;
    }
    // maybe single variable to return
    if (assignedUsedVariables.length == 1) {
      // we cannot both return variable and have explicit return statement
      if (_returnType != null) {
        result.addFatalError(
            'Ambiguous return value: Selected block contains assignment(s) to '
            'local variables and return statement.');
        return result;
      }
      // prepare to return an assigned variable
      var returnVariable = assignedUsedVariables[0];
      _returnType = returnVariable.type;
      _returnVariableName = returnVariable.displayName;
    }
    // fatal, if multiple variables assigned and used after selection
    if (assignedUsedVariables.length > 1) {
      var sb = StringBuffer();
      for (var variable in assignedUsedVariables) {
        sb.write(variable.displayName);
        sb.write('\n');
      }
      result.addFatalError(format(
          'Ambiguous return value: Selected block contains more than one '
          'assignment to local variables. Affected variables are:\n\n{0}',
          sb.toString().trim()));
    }
    // done
    return result;
  }

  Future<void> _initializeReturnType() async {
    var typeProvider = resolveResult.typeProvider;
    if (_selectionFunctionExpression != null) {
      variableType = '';
      returnType = '';
    } else if (_returnType == null) {
      variableType = null;
      if (_hasAwait) {
        returnType = _getTypeCode(typeProvider.futureDynamicType);
      } else {
        returnType = 'void';
      }
    } else if (_returnType.isDynamic) {
      variableType = '';
      if (_hasAwait) {
        returnType = _getTypeCode(typeProvider.futureDynamicType);
      } else {
        returnType = '';
      }
    } else {
      variableType = _getTypeCode(_returnType);
      if (_hasAwait) {
        if (_returnType.element != typeProvider.futureElement) {
          returnType = _getTypeCode(typeProvider.futureType2(_returnType));
        }
      } else {
        returnType = variableType;
      }
    }
  }

  /// Checks if the given [element] is declared in [selectionRange].
  bool _isDeclaredInSelection(Element element) {
    return selectionRange.contains(element.nameOffset);
  }

  /// Checks if it is OK to extract the node with the given [SourceRange].
  bool _isExtractable(SourceRange range) {
    var analyzer = _ExtractMethodAnalyzer(resolveResult, range);
    analyzer.analyze();
    return analyzer.status.isOK;
  }

  bool _isParameterNameConflictWithBody(RefactoringMethodParameter parameter) {
    var id = parameter.id;
    var name = parameter.name;
    var parameterRanges = _parameterReferencesMap[id];
    var otherRanges = _localNames[name];
    for (var parameterRange in parameterRanges) {
      if (otherRanges != null) {
        for (var otherRange in otherRanges) {
          if (parameterRange.intersects(otherRange)) {
            return true;
          }
        }
      }
    }
    if (_unqualifiedNames.contains(name)) {
      return true;
    }
    return false;
  }

  /// Checks if [element] is referenced after [selectionRange].
  bool _isUsedAfterSelection(Element element) {
    var visitor = _IsUsedAfterSelectionVisitor(this, element);
    _parentMember.accept(visitor);
    return visitor.result;
  }

  /// Prepare names that are used in the enclosing function, so should not be
  /// proposed as names of the extracted method.
  void _prepareExcludedNames() {
    _excludedNames.clear();
    var localElements = getDefinedLocalElements(_parentMember);
    _excludedNames.addAll(localElements.map((e) => e.name));
  }

  void _prepareNames() {
    names.clear();
    if (_selectionExpression != null) {
      names.addAll(getVariableNameSuggestionsForExpression(
          _selectionExpression.staticType, _selectionExpression, _excludedNames,
          isMethod: true));
    }
  }

  void _prepareOffsetsLengths() {
    offsets.clear();
    lengths.clear();
    for (var occurrence in _occurrences) {
      offsets.add(occurrence.range.offset);
      lengths.add(occurrence.range.length);
    }
  }

  /// Checks if the given [expression] is reasonable to extract as a getter.
  static bool _isExpressionForGetter(Expression expression) {
    if (expression is BinaryExpression) {
      return _isExpressionForGetter(expression.leftOperand) &&
          _isExpressionForGetter(expression.rightOperand);
    }
    if (expression is Literal) {
      return true;
    }
    if (expression is PrefixExpression) {
      return _isExpressionForGetter(expression.operand);
    }
    if (expression is PrefixedIdentifier) {
      return _isExpressionForGetter(expression.prefix);
    }
    if (expression is PropertyAccess) {
      return _isExpressionForGetter(expression.target);
    }
    if (expression is SimpleIdentifier) {
      return true;
    }
    return false;
  }

  /// Returns `true` if the given [statement] may end with a [ReturnStatement].
  static bool _mayEndWithReturnStatement(Statement statement) {
    var visitor = _HasReturnStatementVisitor();
    statement.accept(visitor);
    return visitor.hasReturn;
  }
}

/// [SelectionAnalyzer] for [ExtractMethodRefactoringImpl].
class _ExtractMethodAnalyzer extends StatementAnalyzer {
  _ExtractMethodAnalyzer(
      ResolvedUnitResult resolveResult, SourceRange selection)
      : super(resolveResult, selection);

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
    var lhs = node.leftHandSide;
    if (_isFirstSelectedNode(lhs)) {
      invalidSelection('Cannot extract the left-hand side of an assignment.',
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
  Object visitForParts(ForParts node) {
    node.visitChildren(this);
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
    super.visitForStatement(node);
    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithDeclarations &&
          identical(forLoopParts.variables, firstSelectedNode)) {
        invalidSelection(
            "Cannot extract initialization part of a 'for' statement.");
      } else if (forLoopParts.updaters.contains(lastSelectedNode)) {
        invalidSelection("Cannot extract increment part of a 'for' statement.");
      }
    }
    return null;
  }

  @override
  Object visitGenericFunctionType(GenericFunctionType node) {
    super.visitGenericFunctionType(node);
    if (_isFirstSelectedNode(node)) {
      invalidSelection('Cannot extract a single type reference.');
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
      var element = node.writeOrReadElement;
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
    var firstParent = firstSelectedNode.parent;
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

class _GetSourcePatternVisitor extends GeneralizingAstVisitor<void> {
  final SourceRange partRange;
  final _SourcePattern pattern;
  final List<SourceEdit> replaceEdits;

  _GetSourcePatternVisitor(this.partRange, this.pattern, this.replaceEdits);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var nodeRange = range.node(node);
    if (partRange.covers(nodeRange)) {
      var element = _getLocalElement(node);
      if (element != null) {
        // name of a named expression
        if (isNamedExpressionName(node)) {
          return;
        }
        // continue
        var originalName = element.displayName;
        var patternName = pattern.originalToPatternNames[originalName];
        if (patternName == null) {
          var parameterType = _getElementType(element);
          pattern.parameterTypes.add(parameterType);
          patternName = '__refVar${pattern.originalToPatternNames.length}';
          pattern.originalToPatternNames[originalName] = patternName;
        }
        replaceEdits.add(SourceEdit(nodeRange.offset - partRange.offset,
            nodeRange.length, patternName));
      }
    }
  }

  DartType _getElementType(Element element) {
    if (element is VariableElement) {
      return element.type;
    }
    if (element is FunctionElement) {
      return element.type;
    }
    throw StateError('Unknown element type: ${element?.runtimeType}');
  }
}

class _HasAwaitVisitor extends GeneralizingAstVisitor<void> {
  bool result = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    result = true;
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.awaitKeyword != null) {
      result = true;
    }
    super.visitForStatement(node);
  }
}

class _HasReturnStatementVisitor extends RecursiveAstVisitor<void> {
  bool hasReturn = false;

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    hasReturn = true;
  }
}

class _InitializeOccurrencesVisitor extends GeneralizingAstVisitor<void> {
  final ExtractMethodRefactoringImpl ref;
  final _SourcePattern selectionPattern;
  final Map<String, String> patternToSelectionName;

  bool forceStatic = false;

  _InitializeOccurrencesVisitor(
      this.ref, this.selectionPattern, this.patternToSelectionName);

  @override
  void visitBlock(Block node) {
    if (ref._selectionStatements != null) {
      _visitStatements(node.statements);
    }
    super.visitBlock(node);
  }

  @override
  void visitConstructorInitializer(ConstructorInitializer node) {
    forceStatic = true;
    try {
      super.visitConstructorInitializer(node);
    } finally {
      forceStatic = false;
    }
  }

  @override
  void visitExpression(Expression node) {
    if (ref._selectionFunctionExpression != null ||
        ref._selectionExpression != null &&
            node.runtimeType == ref._selectionExpression.runtimeType) {
      var nodeRange = range.node(node);
      _tryToFindOccurrence(nodeRange);
    }
    super.visitExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    forceStatic = node.isStatic;
    try {
      super.visitMethodDeclaration(node);
    } finally {
      forceStatic = false;
    }
  }

  @override
  void visitSwitchMember(SwitchMember node) {
    if (ref._selectionStatements != null) {
      _visitStatements(node.statements);
    }
    super.visitSwitchMember(node);
  }

  /// Checks if given [SourceRange] matched selection source and adds
  /// [_Occurrence].
  bool _tryToFindOccurrence(SourceRange nodeRange) {
    // check if can be extracted
    if (!ref._isExtractable(nodeRange)) {
      return false;
    }
    // prepare node source
    var nodePattern = ref._getSourcePattern(nodeRange);
    // if matches normalized node source, then add as occurrence
    if (selectionPattern.isCompatible(nodePattern)) {
      var occurrence =
          _Occurrence(nodeRange, ref.selectionRange.intersects(nodeRange));
      ref._occurrences.add(occurrence);
      // prepare mapping of parameter names to the occurrence variables
      nodePattern.originalToPatternNames
          .forEach((String originalName, String patternName) {
        var selectionName = patternToSelectionName[patternName];
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
    var beginStatementIndex = 0;
    var selectionCount = ref._selectionStatements.length;
    while (beginStatementIndex + selectionCount <= statements.length) {
      var nodeRange = range.startEnd(statements[beginStatementIndex],
          statements[beginStatementIndex + selectionCount - 1]);
      var found = _tryToFindOccurrence(nodeRange);
      // next statement
      if (found) {
        beginStatementIndex += selectionCount;
      } else {
        beginStatementIndex++;
      }
    }
  }
}

class _InitializeParametersVisitor extends GeneralizingAstVisitor {
  final ExtractMethodRefactoringImpl ref;
  final List<VariableElement> assignedUsedVariables;

  _InitializeParametersVisitor(this.ref, this.assignedUsedVariables);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var nodeRange = range.node(node);
    if (!ref.selectionRange.covers(nodeRange)) {
      return;
    }
    var name = node.name;
    // analyze local element
    var element = _getLocalElement(node);
    if (element != null) {
      // name of the named expression
      if (isNamedExpressionName(node)) {
        return;
      }
      // if declared outside, add parameter
      if (!ref._isDeclaredInSelection(element)) {
        // add parameter
        var parameter = ref._parametersMap[name];
        if (parameter == null) {
          var parameterType = node.writeOrReadType;
          var parametersBuffer = StringBuffer();
          var parameterTypeCode = ref.utils.getTypeSource(
              parameterType, ref.librariesToImport,
              parametersBuffer: parametersBuffer);
          var parametersCode =
              parametersBuffer.isNotEmpty ? parametersBuffer.toString() : null;
          parameter = RefactoringMethodParameter(
              RefactoringMethodParameterKind.REQUIRED, parameterTypeCode, name,
              parameters: parametersCode, id: name);
          ref._parameters.add(parameter);
          ref._parametersMap[name] = parameter;
        }
        // add reference to parameter
        ref._addParameterReference(name, nodeRange);
      }
      // remember, if assigned and used after selection
      if (isLeftHandOfAssignment(node) && ref._isUsedAfterSelection(element)) {
        if (!assignedUsedVariables.contains(element)) {
          assignedUsedVariables.add(element);
        }
      }
    }
    // remember information for conflicts checking
    if (element is LocalElement) {
      // declared local elements
      if (node.inDeclarationContext()) {
        ref._localNames.putIfAbsent(name, () => <SourceRange>[]);
        ref._localNames[name].add(ref._visibleRangeMap[element]);
      }
    } else {
      // unqualified non-local names
      if (!node.isQualified) {
        ref._unqualifiedNames.add(name);
      }
    }
  }
}

class _IsUsedAfterSelectionVisitor extends GeneralizingAstVisitor<void> {
  final ExtractMethodRefactoringImpl ref;
  final Element element;
  bool result = false;

  _IsUsedAfterSelectionVisitor(this.ref, this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var nodeElement = node.writeOrReadElement;
    if (identical(nodeElement, element)) {
      var nodeOffset = node.offset;
      if (nodeOffset > ref.selectionRange.end) {
        result = true;
      }
    }
  }
}

/// Description of a single occurrence of the selected expression or set of
/// statements.
class _Occurrence {
  final SourceRange range;
  final bool isSelection;

  final Map<String, String> _parameterOldToOccurrenceName = <String, String>{};

  _Occurrence(this.range, this.isSelection);
}

class _ReturnTypeComputer extends RecursiveAstVisitor<void> {
  final TypeSystem typeSystem;

  DartType returnType;

  _ReturnTypeComputer(this.typeSystem);

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    // prepare expression
    var expression = node.expression;
    if (expression == null) {
      return;
    }
    // prepare type
    var type = expression.staticType;
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
        returnType = typeSystem.leastUpperBound(returnType, type);
      }
    }
  }
}

/// Generalized version of some source, in which references to the specific
/// variables are replaced with pattern variables, with back mapping from the
/// pattern to the original variable names.
class _SourcePattern {
  final List<DartType> parameterTypes = <DartType>[];
  String normalizedSource;
  final Map<String, String> originalToPatternNames = {};

  bool isCompatible(_SourcePattern other) {
    if (other.normalizedSource != normalizedSource) {
      return false;
    }
    if (other.parameterTypes.length != parameterTypes.length) {
      return false;
    }
    for (var i = 0; i < parameterTypes.length; i++) {
      if (other.parameterTypes[i] != parameterTypes[i]) {
        return false;
      }
    }
    return true;
  }
}
