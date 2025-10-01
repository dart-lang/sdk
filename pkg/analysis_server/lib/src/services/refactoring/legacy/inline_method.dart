// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/legacy/visible_ranges_computer.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/src/utilities/extensions/resolved_unit_result.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
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
Future<String> _getMethodSourceForInvocation(
  RefactoringStatus status,
  ChangeBuilder builder,
  String file,
  Map<TypeParameterElement, DartType> argumentTypes,
  Map<TypeParameterElement, DartType> instanceArgumentTypes,
  _SourcePart part,
  CorrectionUtils utils,
  AstNode contextNode,
  Expression? targetExpression,
  List<Expression> arguments,
) async {
  // prepare edits to replace parameters with arguments
  var edits = <SourceEdit>[];
  await builder.addDartFileEdit(file, (builder) {
    part._typeParameters.forEach((
      TypeParameterElement element,
      List<SourceRange> typeRange,
    ) {
      for (var range in typeRange) {
        builder.addReplacement(range, (builder) {
          builder.writeType(argumentTypes[element], shouldWriteDynamic: true);
        });
      }
    });
    part._instanceTypeParameters.forEach((
      TypeParameterElement element,
      List<SourceRange> typeRange,
    ) {
      for (var range in typeRange) {
        builder.addReplacement(range, (builder) {
          builder.writeType(
            instanceArgumentTypes[element],
            shouldWriteDynamic: true,
            typeParametersInScope:
                contextNode.enclosingExecutableElement?.typeParameters,
          );
        });
      }
    });
  });
  edits.addAll(builder.sourceChange.edits.expand((edit) => edit.edits));
  part._parameters.forEach((
    FormalParameterElement parameter,
    List<_ParameterOccurrence> occurrences,
  ) {
    // prepare argument
    Expression? argument;
    for (var arg in arguments) {
      // Compare using names because parameter elements may not be the same
      // instance for methods with generic type arguments.
      if (arg.correspondingParameter?.name == parameter.name) {
        argument = arg;
        break;
      }
    }
    if (argument is NamedExpression) {
      argument = argument.expression;
    }
    // prepare argument properties
    Precedence argumentPrecedence;
    String? argumentSource;
    if (argument != null) {
      argumentPrecedence = getExpressionPrecedence(argument);
      argumentSource = utils.getNodeText(argument);
    } else {
      // report about a missing required parameter
      if (parameter.isRequiredPositional) {
        status.addError(
          'No argument for the parameter "${parameter.name}".',
          newLocation_fromNode(contextNode),
        );
        return;
      }
      // an optional parameter
      argumentPrecedence = Precedence.none;
      argumentSource = parameter.defaultValueCode;
      argumentSource ??= 'null';
    }
    // replace all occurrences of this parameter
    for (var occurrence in occurrences) {
      AstNode nodeToReplace = occurrence.identifier;
      // prepare argument source to apply at this occurrence
      String occurrenceArgumentSource;
      if (occurrence.identifier.parent
          case InterpolationExpression interpolation) {
        switch (argument) {
          case SimpleIdentifier():
            occurrenceArgumentSource = argumentSource;
          case SingleStringLiteral(canDiscardSingleQuotes: true):
            nodeToReplace = interpolation;
            occurrenceArgumentSource = argumentSource.substring(
              1,
              argumentSource.length - 1,
            );
          default:
            occurrenceArgumentSource = '{$argumentSource}';
        }
      } else if (argumentPrecedence < occurrence.parentPrecedence) {
        occurrenceArgumentSource = '($argumentSource)';
      } else {
        occurrenceArgumentSource = argumentSource;
      }
      // do replace
      var nodeToReplaceRange = range.offsetBy(
        range.node(nodeToReplace),
        -occurrence.baseOffset,
      );
      edits.add(
        newSourceEdit_range(nodeToReplaceRange, occurrenceArgumentSource),
      );
    }
  });
  // replace static field "qualifier" with invocation target
  part._implicitClassNameOffsets.forEach((String className, List<int> offsets) {
    for (var offset in offsets) {
      //      edits.add(newSourceEdit_range(range, className + '.'));
      edits.add(SourceEdit(offset, 0, '$className.'));
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
    if (enclosingExecutable != null) {
      var visibleRangeMap = VisibleRangesComputer.forNode(enclosingExecutable);
      visibleRangeMap.forEach((element, elementRange) {
        if (elementRange.intersects(localsRange)) {
          result.add(element.displayName);
        }
      });
    }
  }
  // fields
  {
    var enclosingInterfaceElement = node.enclosingInterfaceElement;
    if (enclosingInterfaceElement != null) {
      var elements = [
        ...enclosingInterfaceElement.allSupertypes.map((type) => type.element),
        enclosingInterfaceElement,
      ];
      for (var interfaceElement in elements) {
        var classMembers = getChildren(interfaceElement);
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
  final ResolvedUnitResult unitResult;
  final int offset;
  final AnalysisSessionHelper sessionHelper;
  final CorrectionUtils utils;
  late SourceChange change;

  @override
  bool isDeclaration = false;
  bool deleteSource = false;
  bool inlineAll = true;

  ExecutableElement? _methodElement;
  late CompilationUnit _methodUnit;
  late CorrectionUtils _methodUtils;
  late AstNode _methodNode;
  FormalParameterList? _methodParameters;
  FunctionBody? _methodBody;
  Expression? _methodExpression;
  _SourcePart? _methodExpressionPart;
  _SourcePart? _methodStatementsPart;
  final List<_ReferenceProcessor> _referenceProcessors = [];
  final Set<Element> _alreadyMadeAsync = <Element>{};

  InlineMethodRefactoringImpl(this.searchEngine, this.unitResult, this.offset)
    : sessionHelper = AnalysisSessionHelper(unitResult.session),
      utils = CorrectionUtils(unitResult);

  @override
  String? get className {
    var interfaceElement = _methodElement?.enclosingElement;
    if (interfaceElement is InterfaceElement) {
      return interfaceElement.displayName;
    }
    return null;
  }

  @override
  String? get methodName {
    return _methodElement?.displayName;
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
  Future<RefactoringStatus> checkFinalConditions() async {
    change = SourceChange(refactoringName);
    var result = RefactoringStatus();
    // check for compatibility of "deleteSource" and "inlineAll"
    if (deleteSource && !inlineAll) {
      result.addError('All references must be inlined to remove the source.');
    }
    // prepare changes
    for (var processor in _referenceProcessors) {
      await processor._process(result);
    }
    // delete method
    if (deleteSource && inlineAll) {
      var methodRange = range.node(_methodNode);
      var linesRange = _methodUtils.getLinesRange(
        methodRange,
        skipLeadingEmptyLines: true,
      );
      doSourceChange_addFragmentEdit(
        change,
        _methodElement!.firstFragment,
        newSourceEdit_range(linesRange, ''),
      );
    }
    // done
    return result;
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    var result = RefactoringStatus();
    // prepare method information
    result.addStatus(await _prepareMethod());
    if (result.hasFatalError) {
      return result;
    }
    var methodElement = _methodElement!;

    // Disallow inlining SDK code.
    if (methodElement.library.isInSdk) {
      result = RefactoringStatus.fatal("Can't inline SDK code.");
      return result;
    }

    // Disallow inlining an augmented method.
    var methodFragment = methodElement.firstFragment;
    if (methodFragment.nextFragment != null) {
      result = RefactoringStatus.fatal("Can't inline an augmented method.");
      return result;
    }

    // Disallow inlining an operator.
    if (methodElement is MethodElement && methodElement.isOperator) {
      result = RefactoringStatus.fatal("Can't inline an operator.");
      return result;
    }

    // Disallow inlining a generator (`sync*` or `async*`).
    if (methodFragment.isGenerator) {
      result = RefactoringStatus.fatal("Can't inline a generator.");
      return result;
    }

    // analyze method body
    result.addStatus(await _prepareMethodParts());
    // process references
    var references = await searchEngine.searchReferences(methodElement);
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

  @override
  bool isAvailable() {
    return !_checkOffset().hasFatalError;
  }

  /// Checks if [offset] is a method that can be inlined.
  RefactoringStatus _checkOffset() {
    var fatalStatus = RefactoringStatus.fatal(
      'Method declaration or reference must be selected to activate this refactoring.',
    );

    var selectedNode = unitResult.unit.nodeCovering(offset: offset);
    Element? element;

    if (selectedNode is FunctionDeclaration) {
      element = selectedNode.declaredFragment?.element;
      isDeclaration = true;
    } else if (selectedNode is MethodDeclaration) {
      element = selectedNode.declaredFragment?.element;
      isDeclaration = true;
    } else if (selectedNode is SimpleIdentifier) {
      element = selectedNode.writeOrReadElement;
    } else {
      return fatalStatus;
    }
    if (element is! ExecutableElement) {
      return fatalStatus;
    }
    if (element.isSynthetic) {
      return fatalStatus;
    }
    // maybe operator
    if (element is MethodElement && element.isOperator) {
      return RefactoringStatus.fatal("Can't inline an operator.");
    }
    // maybe [a]sync*
    if (element.firstFragment.isGenerator) {
      return RefactoringStatus.fatal("Can't inline a generator.");
    }

    return RefactoringStatus();
  }

  Future<_SourcePart> _createSourcePart(SourceRange range) async {
    var source = _methodUtils.getRangeText(range);

    var prefix = unitResult.linePrefix(range.offset);
    var result = _SourcePart(range.offset, source, prefix);
    var unit = await sessionHelper.getResolvedUnitByElement(_methodElement!);
    var inliningMethod = unit?.unit.nodeCovering(
      offset: _methodElement!.firstFragment.offset,
    );
    if (inliningMethod == null) {
      return result;
    }
    Scope? scope;
    if (inliningMethod
        case MethodDeclaration(:var body) ||
            FunctionDeclaration(
              functionExpression: FunctionExpression(:var body),
            ) ||
            FunctionDeclarationStatement(
              functionDeclaration: FunctionDeclaration(
                functionExpression: FunctionExpression(:var body),
              ),
            ) when body is BlockFunctionBody) {
      scope = ScopeResolverVisitor.getNodeNameScope(body.block);
    }
    // Remember parameters and variables occurrences.
    _methodUnit.accept(
      _VariablesVisitor(_methodElement!, range, result, scope),
    );

    // Done.
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
      'Method declaration or reference must be selected to activate this refactoring.',
    );

    // prepare selected SimpleIdentifier
    var selectedNode = unitResult.unit.nodeCovering(offset: offset);
    Element? element;
    if (selectedNode is FunctionDeclaration) {
      element = selectedNode.declaredFragment?.element;
      isDeclaration = true;
    } else if (selectedNode is MethodDeclaration) {
      element = selectedNode.declaredFragment?.element;
      isDeclaration = true;
    } else if (selectedNode is SimpleIdentifier &&
        selectedNode.parent is! Combinator) {
      element = selectedNode.writeOrReadElement;
    } else {
      return fatalStatus;
    }

    // prepare selected ExecutableElement
    if (element is! ExecutableElement) {
      return fatalStatus;
    }
    if (element.isSynthetic) {
      return fatalStatus;
    }
    _methodElement = element;

    var declaration = await sessionHelper.getFragmentDeclaration(
      element.firstFragment,
    );
    var methodNode = declaration!.node;
    _methodNode = methodNode;

    var resolvedUnit = declaration.resolvedUnit!;
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

    deleteSource = isDeclaration;
    inlineAll = deleteSource;
    return RefactoringStatus();
  }

  /// Analyze [_methodBody] to fill [_methodExpressionPart] and
  /// [_methodStatementsPart].
  Future<RefactoringStatus> _prepareMethodParts() async {
    var result = RefactoringStatus();
    if (_methodBody is ExpressionFunctionBody) {
      var body = _methodBody as ExpressionFunctionBody;
      _methodExpression = body.expression;
      var methodExpressionRange = range.node(_methodExpression!);
      _methodExpressionPart = await _createSourcePart(methodExpressionRange);
    } else if (_methodBody is BlockFunctionBody) {
      var body = (_methodBody as BlockFunctionBody).block;
      List<Statement> statements = body.statements;
      if (statements.isNotEmpty) {
        var lastStatement = statements[statements.length - 1];
        // "return" statement requires special handling
        if (lastStatement is ReturnStatement) {
          _methodExpression = lastStatement.expression;
          if (_methodExpression != null) {
            var methodExpressionRange = range.node(_methodExpression!);
            _methodExpressionPart = await _createSourcePart(
              methodExpressionRange,
            );
          }
          // exclude "return" statement from statements
          statements = statements.sublist(0, statements.length - 1);
        }
        // if there are statements, process them
        if (statements.isNotEmpty) {
          var statementsRange = _methodUtils.getLinesRangeStatements(
            statements,
          );
          _methodStatementsPart = await _createSourcePart(statementsRange);
        }
      }
      // check if more than one return
      body.accept(_ReturnsValidatorVisitor(result));
    } else {
      return RefactoringStatus.fatal("Can't inline a method without a body.");
    }
    return result;
  }
}

class _ParameterOccurrence {
  final int baseOffset;
  final SimpleIdentifier identifier;
  final Precedence parentPrecedence;
  final bool inStringInterpolation;

  _ParameterOccurrence({
    required this.baseOffset,
    required this.identifier,
    required this.parentPrecedence,
    required this.inStringInterpolation,
  });
}

/// Processor for single [SearchMatch] reference to an [Element].
class _ReferenceProcessor {
  final InlineMethodRefactoringImpl ref;
  final SearchMatch reference;
  final Map<TypeParameterElement, DartType> _argumentTypes = {};
  final Map<TypeParameterElement, DartType> _instanceArgumentTypes = {};

  late Element refElement;
  late CorrectionUtils _refUtils;
  late SimpleIdentifier _node;
  SourceRange? _refLineRange;
  late String _refPrefix;

  _ReferenceProcessor(this.ref, this.reference);

  Future<void> init() async {
    refElement = reference.element;

    // prepare CorrectionUtils
    var result = await ref.sessionHelper.getResolvedUnitByElement(refElement);
    _refUtils = CorrectionUtils(result!);

    // prepare node and environment
    _node =
        _refUtils.findNode(reference.sourceRange.offset) as SimpleIdentifier;
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
    doSourceChange_addSourceEdit(ref.change, reference.unitSource, edit);
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
    var parent2 = parent?.parent;
    // OK, if statement in block
    if (parent is Statement) {
      return parent2 is Block;
    }
    // OK, if statement in block in an await expression
    if (parent is AwaitExpression) {
      if (parent2 is ExpressionStatement) {
        return parent2.parent is Block;
      }
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

  Future<void> _inlineMethodInvocation(
    RefactoringStatus status,
    Expression usage,
    bool cascaded,
    Expression? target,
    List<Expression> arguments,
  ) async {
    // we don't support cascade
    if (cascaded) {
      status.addError(
        "Can't inline a cascade invocation.",
        newLocation_fromNode(usage),
      );
    }
    // can we inline method body into "methodUsage" block?
    if (_canInlineBody(usage)) {
      // insert non-return statements
      if (ref._methodStatementsPart != null) {
        // prepare statements source for invocation
        var source = await _getMethodSourceForInvocation(
          status,
          ChangeBuilder(
            session: ref.sessionHelper.session,
            defaultEol: _refUtils.endOfLine,
          ),
          ref.unitResult.path,
          _argumentTypes,
          _instanceArgumentTypes,
          ref._methodStatementsPart!,
          _refUtils,
          usage,
          target,
          arguments,
        );
        source = _refUtils.replaceSourceIndent(
          source,
          ref._methodStatementsPart!._prefix,
          _refPrefix,
          includeLeading: true,
          ensureTrailingNewline: true,
        );
        // do insert
        var edit = newSourceEdit_range(
          SourceRange(_refLineRange!.offset, 0),
          source,
        );
        _addRefEdit(edit);
      }
      // replace invocation with return expression
      if (ref._methodExpressionPart != null) {
        // prepare expression source for invocation
        var source = await _getMethodSourceForInvocation(
          status,
          ChangeBuilder(
            session: ref.sessionHelper.session,
            defaultEol: _refUtils.endOfLine,
          ),
          ref.unitResult.path,
          _argumentTypes,
          _instanceArgumentTypes,
          ref._methodExpressionPart!,
          _refUtils,
          usage,
          target,
          arguments,
        );

        // If we inline the method expression into a string interpolation,
        // and the expression is not a single identifier, wrap it into `{}`.
        AstNode nodeToReplace = usage;
        if (usage.parent case InterpolationExpression interpolation) {
          if (interpolation.leftBracket.lexeme == r'$') {
            switch (ref._methodExpression) {
              case SimpleIdentifier():
                break;
              case SingleStringLiteral(canDiscardSingleQuotes: true):
                nodeToReplace = interpolation;
                source = source.substring(1, source.length - 1);
              default:
                source = '{$source}';
            }
          }
        }

        if (getExpressionPrecedence(ref._methodExpression!) <
            getExpressionParentPrecedence(usage)) {
          source = '($source)';
        }

        // do replace
        var nodeToReplaceRange = range.node(nodeToReplace);
        var awaitKeyword = Keyword.AWAIT.lexeme;
        if (usage.parent is AwaitExpression &&
            source.startsWith(awaitKeyword)) {
          // remove the duplicate await keyword and the following whitespace.
          source = source.substring(awaitKeyword.length + 1);
        }
        source = _refUtils.replaceSourceIndent(
          source,
          ref._methodExpressionPart!._prefix,
          _refPrefix,
        );
        var edit = newSourceEdit_range(nodeToReplaceRange, source);
        _addRefEdit(edit);
      } else {
        var edit = newSourceEdit_range(_refLineRange!, '');
        _addRefEdit(edit);
      }
      return;
    }
    // inline as closure invocation
    String source;
    {
      source = ref._methodUtils.getRangeText(
        range.startEnd(ref._methodParameters!.leftParenthesis, ref._methodNode),
      );
      var methodPrefix = ref._methodUtils.getLinePrefix(ref._methodNode.offset);
      source = _refUtils.replaceSourceIndent(source, methodPrefix, _refPrefix);
      source = source.trim();
    }
    // do insert
    var edit = newSourceEdit_range(range.node(_node), source);
    _addRefEdit(edit);
  }

  Future<void> _process(RefactoringStatus status) async {
    var nodeParent = _node.parent;
    // may be only single place should be inlined
    if (!_shouldProcess()) {
      return;
    }
    // References in a combinator list can't be inlined, but not doing so isn't
    // an error.
    if (nodeParent is Combinator) {
      return;
    }
    _processTypeArguments(_node);
    // If the element being inlined is async, ensure that the function
    // body that encloses the method is also async.
    if (ref._methodElement!.firstFragment.isAsynchronous) {
      var body = _node.thisOrAncestorOfType<FunctionBody>();
      if (body != null) {
        if (body.isSynchronous) {
          if (body.isGenerator) {
            status.addFatalError(
              "Can't inline an 'async' method into a 'sync*' method.",
              newLocation_fromNode(_node),
            );
            return;
          }
          if (refElement is ExecutableElement) {
            var executable = refElement as ExecutableElement;
            if (!executable.returnType.isDartAsyncFuture) {
              status.addFatalError(
                "Can't inline an 'async' method into a function that doesn't return a 'Future'.",
                newLocation_fromNode(_node),
              );
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
      await _inlineMethodInvocation(
        status,
        invocation,
        invocation.isCascaded,
        target,
        arguments,
      );
    } else {
      // cannot inline reference to method: var v = new A().method;
      if (ref._methodElement is MethodElement) {
        status.addFatalError(
          "Can't inline a class method reference.",
          newLocation_fromNode(_node),
        );
        return;
      }
      // PropertyAccessorElement
      if (ref._methodElement is PropertyAccessorElement) {
        Expression usage = _node;
        Expression? target;
        var cascade = false;
        if (nodeParent case PrefixedIdentifier prefixedIdentifier) {
          if (prefixedIdentifier.prefix == _node) {
            usage = prefixedIdentifier.prefix;
          } else {
            usage = prefixedIdentifier;
            target = prefixedIdentifier.prefix;
          }
          cascade = false;
        }
        if (nodeParent case PropertyAccess propertyAccess) {
          usage = propertyAccess;
          target = propertyAccess.realTarget;
          cascade = propertyAccess.isCascaded;
        }
        // prepare arguments
        var arguments = <Expression>[];
        if (_node.inSetterContext()) {
          var assignment = _node.thisOrAncestorOfType<AssignmentExpression>()!;
          arguments.add(assignment.rightHandSide);
        }
        // inline body
        await _inlineMethodInvocation(
          status,
          usage,
          cascade,
          target,
          arguments,
        );
        return;
      }
      // not invocation, just reference to function
      String source;
      {
        source = ref._methodUtils.getRangeText(
          range.startEnd(
            ref._methodParameters!.leftParenthesis,
            ref._methodNode,
          ),
        );
        var methodPrefix = ref._methodUtils.getLinePrefix(
          ref._methodNode.offset,
        );
        source = _refUtils.replaceSourceIndent(
          source,
          methodPrefix,
          _refPrefix,
        );
        source = source.trim();
        source = removeEnd(source, ';')!;
      }
      // do insert
      var edit = newSourceEdit_range(range.node(_node), source);
      _addRefEdit(edit);
    }
  }

  void _processTypeArguments(SimpleIdentifier node) {
    if (node.parent case MethodInvocation(:var typeArgumentTypes?)) {
      _argumentTypes.addAll({
        for (var (index, element) in ref._methodElement!.typeParameters.indexed)
          element: typeArgumentTypes[index],
      });
    }
    if (node.parent case MethodInvocation(
      realTarget: Expression(
        staticType: ParameterizedType(
          :var typeArguments,
          :TypeParameterizedElement element,
        ),
      ),
    )) {
      _instanceArgumentTypes.addAll({
        for (var (index, element) in element.typeParameters.indexed)
          element: typeArguments[index],
      });
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
  void visitFunctionExpression(FunctionExpression node) {
    // Return statements within closures aren't counted.
  }

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
  final Map<FormalParameterElement, List<_ParameterOccurrence>> _parameters =
      {};

  final Map<TypeParameterElement, List<SourceRange>> _typeParameters = {};

  final Map<TypeParameterElement, List<SourceRange>> _instanceTypeParameters =
      {};

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
    _implicitClassNameOffsets
        .putIfAbsent(className, () => [])
        .add(offset - _base);
  }

  void addImplicitThisOffset(int offset) {
    _implicitThisOffsets.add(offset - _base);
  }

  void addInstanceTypeParameter(
    TypeParameterElement element,
    SourceRange identifierRange,
  ) {
    identifierRange = range.offsetBy(identifierRange, -_base);
    _instanceTypeParameters.putIfAbsent(element, () => []).add(identifierRange);
  }

  void addParameterOccurrence({
    required FormalParameterElement parameter,
    required SimpleIdentifier identifier,
    required Precedence parentPrecedence,
    required bool inStringInterpolation,
  }) {
    _parameters
        .putIfAbsent(parameter, () => [])
        .add(
          _ParameterOccurrence(
            baseOffset: _base,
            parentPrecedence: parentPrecedence,
            identifier: identifier,
            inStringInterpolation: inStringInterpolation,
          ),
        );
  }

  void addTypeParameter(
    TypeParameterElement element,
    SourceRange identifierRange,
  ) {
    identifierRange = range.offsetBy(identifierRange, -_base);
    _typeParameters.putIfAbsent(element, () => []).add(identifierRange);
  }

  void addVariable(VariableElement element, SourceRange identifierRange) {
    identifierRange = range.offsetBy(identifierRange, -_base);
    _variables.putIfAbsent(element, () => []).add(identifierRange);
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

  /// The body [Scope] of the method being inlined.
  final Scope? scope;

  _VariablesVisitor(
    this.methodElement,
    this.bodyRange,
    this.result,
    this.scope,
  );

  @override
  void visitNode(AstNode node) {
    var nodeRange = range.node(node);
    if (!bodyRange.intersects(nodeRange)) {
      return;
    }
    super.visitNode(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var nodeRange = range.node(node);
    if (bodyRange.covers(nodeRange)) {
      _addMemberQualifier(node);
      _addParameter(node);
      _addVariable(getLocalVariableElement(node), node);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    var offset = node.offset;
    if (bodyRange.contains(offset)) {
      result.addExplicitThisOffset(offset);
    }
  }

  @override
  void visitTypeAnnotation(TypeAnnotation node) {
    var nodeRange = range.node(node);
    InstanceElement? instanceElement;
    if (methodElement case MethodElement(:InstanceElement enclosingElement)) {
      instanceElement = enclosingElement;
    }
    if (node.typeOrThrow case TypeParameterType(
      :var element,
    ) when bodyRange.covers(nodeRange)) {
      if (methodElement.typeParameters.contains(element)) {
        result.addTypeParameter(element, nodeRange);
      } else if (instanceElement?.typeParameters.contains(element) ?? false) {
        result.addInstanceTypeParameter(element, nodeRange);
      }
    }
    super.visitTypeAnnotation(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var nameRange = range.token(node.name);
    if (bodyRange.covers(nameRange)) {
      _addVariable(node.declaredFragment?.element, node);
    }

    super.visitVariableDeclaration(node);
  }

  void _addMemberQualifier(SimpleIdentifier node) {
    // should be unqualified
    var qualifier = getNodeQualifier(node);
    if (qualifier != null) {
      return;
    }
    // should be a method or field reference
    var element = node.writeOrReadElement;
    if (element is ExecutableElement) {
      if (element is MethodElement || element is PropertyAccessorElement) {
        // OK
      } else {
        return;
      }
    } else {
      return;
    }
    if (element.enclosingElement is! InterfaceElement) {
      return;
    }
    // record the implicit static or instance reference
    var offset = node.offset;
    if (element.isStatic) {
      var className = element.enclosingElement!.name!;
      result.addImplicitClassNameOffset(className, offset);
    } else {
      result.addImplicitThisOffset(offset);
    }
  }

  void _addParameter(SimpleIdentifier node) {
    var parameterElement = getFormalParameterElement(node);
    // not a parameter
    if (parameterElement == null) {
      return;
    }
    // not a parameter of the function being inlined
    if (!methodElement.formalParameters.contains(parameterElement)) {
      return;
    }
    // OK, add occurrence
    var parentPrecedence = getExpressionParentPrecedence(node);
    result.addParameterOccurrence(
      parameter: parameterElement,
      identifier: node,
      parentPrecedence: parentPrecedence,
      inStringInterpolation: node.parent is InterpolationExpression,
    );
  }

  void _addVariable(VariableElement? element, AstNode node) {
    if (element is LocalVariableElement) {
      if (scope == null) {
        // No block scope so all variables will be self-contained
        return;
      }
      if (scope!.lookup(element.displayName) case ScopeLookupResult(
        :var getter,
        :var setter,
      ) when getter == null && setter == null) {
        // No variable with the same name at the block scope
        return;
      }

      // Here we found a variable with that name in the block scope
      var nodeRange = node is VariableDeclaration
          ? range.token(node.name)
          : range.node(node);
      result.addVariable(element, nodeRange);
    }
  }
}

extension on SingleStringLiteral {
  /// Whether this literal can be inlined as its content.
  /// The literal can have interpolations itself.
  bool get canDiscardSingleQuotes {
    if (isMultiline || isRaw) {
      return false;
    }
    return true;
  }
}
