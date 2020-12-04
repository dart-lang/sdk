// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// An object that can compute a correction (fix or assist) in a Dart file.
abstract class CorrectionProducer extends SingleCorrectionProducer {
  /// Return the type for the class `bool` from `dart:core`.
  DartType get coreTypeBool => resolvedResult.typeProvider.boolType;

  /// Returns `true` if [node] is in a static context.
  bool get inStaticContext {
    // constructor initializer cannot reference "this"
    if (node.thisOrAncestorOfType<ConstructorInitializer>() != null) {
      return true;
    }
    // field initializer cannot reference "this"
    if (node.thisOrAncestorOfType<FieldDeclaration>() != null) {
      return true;
    }
    // static method
    var method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.isStatic;
  }

  Future<void> compute(ChangeBuilder builder);

  /// Return the class, enum or mixin declaration for the given [element].
  Future<ClassOrMixinDeclaration> getClassOrMixinDeclaration(
      ClassElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    if (result.node is ClassOrMixinDeclaration) {
      return result.node;
    }
    return null;
  }

  /// Return the extension declaration for the given [element].
  Future<ExtensionDeclaration> getExtensionDeclaration(
      ExtensionElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    if (result.node is ExtensionDeclaration) {
      return result.node;
    }
    return null;
  }

  /// Return the class element associated with the [target], or `null` if there
  /// is no such class element.
  ClassElement getTargetClassElement(Expression target) {
    var type = target.staticType;
    if (type is InterfaceType) {
      return type.element;
    } else if (target is Identifier) {
      var element = target.staticElement;
      if (element is ClassElement) {
        return element;
      }
    }
    return null;
  }

  /// Returns an expected [DartType] of [expression], may be `null` if cannot be
  /// inferred.
  DartType inferUndefinedExpressionType(Expression expression) {
    var parent = expression.parent;
    // myFunction();
    if (parent is ExpressionStatement) {
      if (expression is MethodInvocation) {
        return VoidTypeImpl.instance;
      }
    }
    // return myFunction();
    if (parent is ReturnStatement) {
      var executable = getEnclosingExecutableElement(expression);
      return executable?.returnType;
    }
    // int v = myFunction();
    if (parent is VariableDeclaration) {
      var variableDeclaration = parent;
      if (variableDeclaration.initializer == expression) {
        var variableElement = variableDeclaration.declaredElement;
        if (variableElement != null) {
          return variableElement.type;
        }
      }
    }
    // myField = 42;
    if (parent is AssignmentExpression) {
      var assignment = parent;
      if (assignment.leftHandSide == expression) {
        var rhs = assignment.rightHandSide;
        if (rhs != null) {
          return rhs.staticType;
        }
      }
    }
    // v = myFunction();
    if (parent is AssignmentExpression) {
      var assignment = parent;
      if (assignment.rightHandSide == expression) {
        if (assignment.operator.type == TokenType.EQ) {
          // v = myFunction();
          return assignment.writeType;
        } else {
          // v += myFunction();
          var method = assignment.staticElement;
          if (method != null) {
            var parameters = method.parameters;
            if (parameters.length == 1) {
              return parameters[0].type;
            }
          }
        }
      }
    }
    // v + myFunction();
    if (parent is BinaryExpression) {
      var binary = parent;
      var method = binary.staticElement;
      if (method != null) {
        if (binary.rightOperand == expression) {
          var parameters = method.parameters;
          return parameters.length == 1 ? parameters[0].type : null;
        }
      }
    }
    // foo( myFunction() );
    if (parent is ArgumentList) {
      var parameter = expression.staticParameterElement;
      return parameter?.type;
    }
    // bool
    {
      // assert( myFunction() );
      if (parent is AssertStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // if ( myFunction() ) {}
      if (parent is IfStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // while ( myFunction() ) {}
      if (parent is WhileStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // do {} while ( myFunction() );
      if (parent is DoStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // !myFunction()
      if (parent is PrefixExpression) {
        var prefixExpression = parent;
        if (prefixExpression.operator.type == TokenType.BANG) {
          return coreTypeBool;
        }
      }
      // binary expression '&&' or '||'
      if (parent is BinaryExpression) {
        var binaryExpression = parent;
        var operatorType = binaryExpression.operator.type;
        if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
            operatorType == TokenType.BAR_BAR) {
          return coreTypeBool;
        }
      }
    }
    // we don't know
    return null;
  }
}

class CorrectionProducerContext {
  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;

  final CompilationUnit unit;
  final CorrectionUtils utils;
  final String file;

  final TypeProvider typeProvider;

  final AnalysisSession session;
  final AnalysisSessionHelper sessionHelper;
  final ResolvedUnitResult resolvedResult;
  final ChangeWorkspace workspace;
  final DartFixContext dartFixContext;

  /// A flag indicating whether the correction producers will be run in the
  /// context of applying bulk fixes.
  final bool applyingBulkFixes;

  final Diagnostic diagnostic;

  AstNode _node;

  CorrectionProducerContext({
    @required this.resolvedResult,
    @required this.workspace,
    this.applyingBulkFixes = false,
    this.dartFixContext,
    this.diagnostic,
    this.selectionOffset = -1,
    this.selectionLength = 0,
  })  : file = resolvedResult.path,
        session = resolvedResult.session,
        sessionHelper = AnalysisSessionHelper(resolvedResult.session),
        typeProvider = resolvedResult.typeProvider,
        selectionEnd = (selectionOffset ?? 0) + (selectionLength ?? 0),
        unit = resolvedResult.unit,
        utils = CorrectionUtils(resolvedResult);

  AstNode get node => _node;

  /// Return `true` if the lint with the given [name] is enabled.
  bool isLintEnabled(String name) {
    var analysisOptions = session.analysisContext.analysisOptions;
    return analysisOptions.isLintEnabled(name);
  }

  bool setupCompute() {
    final locator = NodeLocator(selectionOffset, selectionEnd);
    _node = locator.searchWithin(resolvedResult.unit);
    return _node != null;
  }
}

/// An object that can dynamically compute multiple corrections (fixes or
/// assists).
abstract class MultiCorrectionProducer extends _AbstractCorrectionProducer {
  /// Return each of the individual producers generated by this producer.
  Iterable<CorrectionProducer> get producers;
}

/// An object that can compute a correction (fix or assist) in a Dart file.
abstract class SingleCorrectionProducer extends _AbstractCorrectionProducer {
  /// Return the arguments that should be used when composing the message for an
  /// assist, or `null` if the assist message has no parameters or if this
  /// producer doesn't support assists.
  List<Object> get assistArguments => null;

  /// Return the assist kind that should be used to build an assist, or `null`
  /// if this producer doesn't support assists.
  AssistKind get assistKind => null;

  /// Return the length of the error message being fixed, or `null` if there is
  /// no diagnostic.
  int get errorLength => diagnostic?.problemMessage?.length;

  /// Return the text of the error message being fixed, or `null` if there is
  /// no diagnostic.
  String get errorMessage => diagnostic?.problemMessage?.message;

  /// Return the offset of the error message being fixed, or `null` if there is
  /// no diagnostic.
  int get errorOffset => diagnostic?.problemMessage?.offset;

  /// Return the arguments that should be used when composing the message for a
  /// fix, or `null` if the fix message has no parameters or if this producer
  /// doesn't support fixes.
  List<Object> get fixArguments => null;

  /// Return the fix kind that should be used to build a fix, or `null` if this
  /// producer doesn't support fixes.
  FixKind get fixKind => null;
}

/// The behavior shared by [CorrectionProducer] and [MultiCorrectionProducer].
abstract class _AbstractCorrectionProducer {
  /// The context used to produce corrections.
  CorrectionProducerContext _context;

  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic, such a node does not
  /// exist, or if it hasn't been computed yet. Use [coveredNode] to access this
  /// field.
  AstNode _coveredNode;

  /// Initialize a newly created producer.
  _AbstractCorrectionProducer();

  bool get applyingBulkFixes => _context.applyingBulkFixes;

  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic or if such a node does
  /// not exist.
  AstNode get coveredNode {
    // TODO(brianwilkerson) Consider renaming this to `coveringNode`.
    if (_coveredNode == null) {
      var diagnostic = this.diagnostic;
      if (diagnostic == null) {
        return null;
      }
      var errorOffset = diagnostic.problemMessage.offset;
      var errorLength = diagnostic.problemMessage.length;
      _coveredNode =
          NodeLocator2(errorOffset, math.max(errorOffset + errorLength - 1, 0))
              .searchWithin(unit);
    }
    return _coveredNode;
  }

  /// Return the diagnostic being fixed, or `null` if this producer is being
  /// used to produce an assist.
  Diagnostic get diagnostic => _context.diagnostic;

  /// Returns the EOL to use for this [CompilationUnit].
  String get eol => utils.endOfLine;

  String get file => _context.file;

  Flutter get flutter => Flutter.instance;

  /// Return the library element for the library in which a correction is being
  /// produced.
  LibraryElement get libraryElement => resolvedResult.libraryElement;

  AstNode get node => _context.node;

  ResolvedUnitResult get resolvedResult => _context.resolvedResult;

  /// Return the resource provider used to access the file system.
  ResourceProvider get resourceProvider =>
      resolvedResult.session.resourceProvider;

  int get selectionEnd => _context.selectionEnd;

  int get selectionLength => _context.selectionLength;

  int get selectionOffset => _context.selectionOffset;

  AnalysisSessionHelper get sessionHelper => _context.sessionHelper;

  TypeProvider get typeProvider => _context.typeProvider;

  /// Return the type system appropriate to the library in which the correction
  /// was requested.
  TypeSystem get typeSystem => _context.resolvedResult.typeSystem;

  CompilationUnit get unit => _context.unit;

  CorrectionUtils get utils => _context.utils;

  /// Configure this producer based on the [context].
  void configure(CorrectionProducerContext context) {
    _context = context;
  }

  /// Return the text that should be displayed to users when referring to the
  /// given [type].
  String displayStringForType(DartType type) => type.getDisplayString(
      withNullability: libraryElement.isNonNullableByDefault);

  /// Return the function body of the most deeply nested method or function that
  /// encloses the [node], or `null` if the node is not in a method or function.
  FunctionBody getEnclosingFunctionBody() {
    var closure = node.thisOrAncestorOfType<FunctionExpression>();
    if (closure != null) {
      return closure.body;
    }
    var function = node.thisOrAncestorOfType<FunctionDeclaration>();
    if (function != null) {
      return function.functionExpression.body;
    }
    var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor != null) {
      return constructor.body;
    }
    var method = node.thisOrAncestorOfType<MethodDeclaration>();
    if (method != null) {
      return method.body;
    }
    return null;
  }

  /// Return the text of the given [range] in the unit.
  String getRangeText(SourceRange range) {
    return utils.getRangeText(range);
  }

  /// Return the top-level declarations with the [name] in libraries that are
  /// available to this context.
  List<TopLevelDeclaration> getTopLevelDeclarations(String name) =>
      _context.dartFixContext.getTopLevelDeclarations(name);

  /// Return `true` the lint with the given [name] is enabled.
  bool isLintEnabled(String name) {
    return _context.isLintEnabled(name);
  }

  /// Return `true` if the selection covers an operator of the given
  /// [binaryExpression].
  bool isOperatorSelected(BinaryExpression binaryExpression) {
    AstNode left = binaryExpression.leftOperand;
    AstNode right = binaryExpression.rightOperand;
    // between the nodes
    if (selectionOffset >= left.end &&
        selectionOffset + selectionLength <= right.offset) {
      return true;
    }
    // or exactly select the node (but not with infix expressions)
    if (selectionOffset == left.offset &&
        selectionOffset + selectionLength == right.end) {
      if (left is BinaryExpression || right is BinaryExpression) {
        return false;
      }
      return true;
    }
    // invalid selection (part of node, etc)
    return false;
  }

  /// Return `true` if the given [node] is in a location where an implicit
  /// constructor invocation would be allowed.
  bool mightBeImplicitConstructor(AstNode node) {
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is MethodInvocation) {
        return parent.realTarget == null;
      }
    }
    return false;
  }

  /// Return `true` if the [node] might be a type name.
  bool mightBeTypeIdentifier(AstNode node) {
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is TypeName) {
        return true;
      }
      return _isNameOfType(node.name);
    }
    return false;
  }

  /// Replace all occurrences of the [oldIndent] with the [newIndent] within the
  /// [source].
  String replaceSourceIndent(
      String source, String oldIndent, String newIndent) {
    return source.replaceAll(RegExp('^$oldIndent', multiLine: true), newIndent);
  }

  /// Return `true` if the given [expression] should be wrapped with parenthesis
  /// when we want to use it as operand of a logical `and` expression.
  bool shouldWrapParenthesisBeforeAnd(Expression expression) {
    if (expression is BinaryExpression) {
      var binary = expression;
      var precedence = binary.operator.type.precedence;
      return precedence < TokenClass.LOGICAL_AND_OPERATOR.precedence;
    }
    return false;
  }

  /// Return `true` if the [name] is capitalized.
  bool _isNameOfType(String name) {
    if (name.isEmpty) {
      return false;
    }
    var firstLetter = name.substring(0, 1);
    if (firstLetter.toUpperCase() != firstLetter) {
      return false;
    }
    return true;
  }
}

extension DartFileEditBuilderExtension on DartFileEditBuilder {
  /// Add edits to the [builder] to remove any parentheses enclosing the
  /// [expression].
  // TODO(brianwilkerson) Consider moving this to DartFileEditBuilder.
  void removeEnclosingParentheses(Expression expression) {
    var precedence = getExpressionPrecedence(expression);
    while (expression.parent is ParenthesizedExpression) {
      var parenthesized = expression.parent as ParenthesizedExpression;
      if (getExpressionParentPrecedence(parenthesized) > precedence) {
        break;
      }
      addDeletion(range.token(parenthesized.leftParenthesis));
      addDeletion(range.token(parenthesized.rightParenthesis));
      expression = parenthesized;
    }
  }
}
