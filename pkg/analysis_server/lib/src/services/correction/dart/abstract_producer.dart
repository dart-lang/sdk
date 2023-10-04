// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart' as path;

/// An object that can compute a correction (fix or assist) in a Dart file.
abstract class CorrectionProducer<T extends ParsedUnitResult>
    extends _AbstractCorrectionProducer<T> {
  /// Return the arguments that should be used when composing the message for an
  /// assist, or `null` if the assist message has no parameters or if this
  /// producer doesn't support assists.
  List<Object>? get assistArguments => null;

  /// Return the assist kind that should be used to build an assist, or `null`
  /// if this producer doesn't support assists.
  AssistKind? get assistKind => null;

  /// Return `true` if fixes from this producer are acceptable to run
  /// automatically (such as during a save operation) when code could be
  /// incomplete.
  ///
  /// By default this value matches [canBeAppliedInBulk] but may return `false`
  /// for fixes that perform actions like removing unused code, which could be
  /// unused only because the code is still being worked on.
  bool get canBeAppliedAutomatically => canBeAppliedInBulk;

  /// Return `true` if this producer can be used to fix diagnostics across
  /// multiple files and/or at the same time as applying fixes from other
  /// producers.
  ///
  /// This flag is used when the user has chosen to apply fixes but may not have
  /// chosen to apply a specific fix (such as running `dart fix`).
  ///
  /// Cases where this will return `false` include fixes for which
  /// - the modified regions can overlap, and
  /// - fixes that have not been tested to ensure that they can be used this
  ///   way.
  bool get canBeAppliedInBulk => false;

  /// Return `true` if this producer can be used to fix multiple diagnostics in
  /// the same file.
  ///
  /// Unlike [canBeAppliedInBulk], this flag is used to provide the option for
  /// a user to fix a specific diagnostic across a file (such as a quick-fix to
  /// "fix all x in this file").
  ///
  /// Cases where this will return `false` include fixes for which
  /// - the modified regions can overlap,
  /// - the fix for one diagnostic would fix all diagnostics with the same code,
  ///   and,
  /// - fixes that have not been tested to ensure that they can be used this
  ///   way.
  ///
  /// Producers that return `true` should return non-null values from both
  /// [multiFixKind] and [multiFixArguments].
  bool get canBeAppliedToFile => false;

  /// Return the length of the error message being fixed, or `null` if there is
  /// no diagnostic.
  int? get errorLength => diagnostic?.problemMessage.length;

  /// Return the text of the error message being fixed, or `null` if there is
  /// no diagnostic.
  String? get errorMessage =>
      diagnostic?.problemMessage.messageText(includeUrl: true);

  /// Return the offset of the error message being fixed, or `null` if there is
  /// no diagnostic.
  int? get errorOffset => diagnostic?.problemMessage.offset;

  /// Return the arguments that should be used when composing the message for a
  /// fix, or `null` if the fix message has no parameters or if this producer
  /// doesn't support fixes.
  List<Object>? get fixArguments => null;

  /// Return the fix kind that should be used to build a fix, or `null` if this
  /// producer doesn't support fixes.
  FixKind? get fixKind => null;

  /// Return the arguments that should be used when composing the message for a
  /// multi-fix, or `null` if the fix message has no parameters or if this
  /// producer doesn't support multi-fixes.
  List<Object>? get multiFixArguments => null;

  /// Return the fix kind that should be used to build a multi-fix, or `null` if
  /// this producer doesn't support multi-fixes.
  FixKind? get multiFixKind => null;

  Future<void> compute(ChangeBuilder builder);
}

class CorrectionProducerContext<UnitResult extends ParsedUnitResult> {
  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;

  final CompilationUnit unit;
  final CorrectionUtils utils;
  final String file;

  final AnalysisSession session;
  final AnalysisSessionHelper sessionHelper;
  final UnitResult unitResult;
  final ChangeWorkspace workspace;

  /// TODO(migration) Make it non-nullable, specialize "fix" context?
  final DartFixContext? dartFixContext;

  /// A flag indicating whether the correction producers will be run in the
  /// context of applying bulk fixes.
  final bool applyingBulkFixes;

  final Diagnostic? diagnostic;

  final TransformOverrideSet? overrideSet;

  final AstNode node;

  final Token token;
  final TypeProvider? typeProvider;

  CorrectionProducerContext._({
    required this.unitResult,
    required this.workspace,
    this.applyingBulkFixes = false,
    this.dartFixContext,
    this.diagnostic,
    required this.node,
    required this.token,
    this.overrideSet,
    this.selectionOffset = -1,
    this.selectionLength = 0,
  })  : file = unitResult.path,
        session = unitResult.session,
        sessionHelper = AnalysisSessionHelper(unitResult.session),
        selectionEnd = selectionOffset + selectionLength,
        unit = unitResult.unit,
        utils = CorrectionUtils(unitResult),
        typeProvider =
            unitResult is ResolvedUnitResult ? unitResult.typeProvider : null;

  bool get isNonNullableByDefault =>
      unit.featureSet.isEnabled(Feature.non_nullable);

  static CorrectionProducerContext<ParsedUnitResult> createParsed({
    required ParsedUnitResult resolvedResult,
    required ChangeWorkspace workspace,
    bool applyingBulkFixes = false,
    DartFixContext? dartFixContext,
    Diagnostic? diagnostic,
    TransformOverrideSet? overrideSet,
    int selectionOffset = -1,
    int selectionLength = 0,
  }) {
    final selection = resolvedResult.unit.select(
      offset: selectionOffset,
      length: selectionLength,
    );
    var node = selection?.coveringNode;
    node ??= resolvedResult.unit;

    final token = _tokenAt(node, selectionOffset) ?? node.beginToken;

    return CorrectionProducerContext._(
      unitResult: resolvedResult,
      workspace: workspace,
      node: node,
      token: token,
      applyingBulkFixes: applyingBulkFixes,
      dartFixContext: dartFixContext,
      diagnostic: diagnostic,
      overrideSet: overrideSet,
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
    );
  }

  static CorrectionProducerContext<ResolvedUnitResult>? createResolved({
    required ResolvedUnitResult resolvedResult,
    required ChangeWorkspace workspace,
    bool applyingBulkFixes = false,
    DartFixContext? dartFixContext,
    Diagnostic? diagnostic,
    TransformOverrideSet? overrideSet,
    int selectionOffset = -1,
    int selectionLength = 0,
  }) {
    var selectionEnd = selectionOffset + selectionLength;
    var locator = NodeLocator(selectionOffset, selectionEnd);
    var node = locator.searchWithin(resolvedResult.unit);
    node ??= resolvedResult.unit;

    final token = _tokenAt(node, selectionOffset) ?? node.beginToken;

    return CorrectionProducerContext._(
      unitResult: resolvedResult,
      workspace: workspace,
      node: node,
      token: token,
      applyingBulkFixes: applyingBulkFixes,
      dartFixContext: dartFixContext,
      diagnostic: diagnostic,
      overrideSet: overrideSet,
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
    );
  }

  static Token? _tokenAt(AstNode node, int offset) {
    for (final entity in node.childEntities) {
      if (entity is AstNode) {
        if (entity.offset <= offset && offset <= entity.end) {
          return _tokenAt(entity, offset);
        }
      } else if (entity is Token) {
        if (entity.offset <= offset && offset <= entity.end) {
          return entity;
        }
      }
    }
    return null;
  }
}

abstract class CorrectionProducerWithDiagnostic
    extends ResolvedCorrectionProducer {
  /// TODO(migration) Consider providing it via constructor.
  @override
  Diagnostic get diagnostic => super.diagnostic!;
}

/// An object that can dynamically compute multiple corrections (fixes or
/// assists).
abstract class MultiCorrectionProducer
    extends _AbstractCorrectionProducer<ResolvedUnitResult> {
  /// Return the library element for the library in which a correction is being
  /// produced.
  LibraryElement get libraryElement => unitResult.libraryElement;

  /// Return the individual producers generated by this producer.
  Future<List<ResolvedCorrectionProducer>> get producers;

  TypeProvider get typeProvider => unitResult.typeProvider;

  /// Return the type system appropriate to the library in which the correction
  /// was requested.
  TypeSystem get typeSystem => unitResult.typeSystem;
}

/// An object that can compute a correction (fix or assist) in a Dart file using
/// the parsed AST.
abstract class ParsedCorrectionProducer
    extends CorrectionProducer<ParsedUnitResult> {}

/// An object that can compute a correction (fix or assist) in a Dart file using
/// the resolved AST.
abstract class ResolvedCorrectionProducer
    extends CorrectionProducer<ResolvedUnitResult> {
  /// Return the type for the class `bool` from `dart:core`.
  DartType get coreTypeBool => unitResult.typeProvider.boolType;

  /// Returns `true` if [node] is in a static context.
  bool get inStaticContext {
    // constructor initializer cannot reference "this"
    if (node.thisOrAncestorOfType<ConstructorInitializer>() != null) {
      return true;
    }
    // field initializer cannot reference "this"
    final fieldDeclaration = node.thisOrAncestorOfType<FieldDeclaration>();
    if (fieldDeclaration != null) {
      return fieldDeclaration.isStatic || !fieldDeclaration.fields.isLate;
    }
    // static method
    var method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.isStatic;
  }

  /// Return the library element for the library in which a correction is being
  /// produced.
  LibraryElement get libraryElement => unitResult.libraryElement;

  TypeProvider get typeProvider => unitResult.typeProvider;

  /// Return the type system appropriate to the library in which the correction
  /// was requested.
  TypeSystem get typeSystem => unitResult.typeSystem;

  /// Return the class for the given [element].
  Future<ClassDeclaration?> getClassDeclaration(ClassElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var node = result?.node;
    if (node is ClassDeclaration) {
      return node;
    }
    return null;
  }

  /// Return the extension declaration for the given [element].
  Future<ExtensionDeclaration?> getExtensionDeclaration(
      ExtensionElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var node = result?.node;
    if (node is ExtensionDeclaration) {
      return node;
    }
    return null;
  }

  LinterContext getLinterContext(path.Context pathContext) {
    return LinterContextImpl(
      [], // unused
      LinterContextUnit(unitResult.content, unitResult.unit),
      unitResult.session.declaredVariables,
      typeProvider,
      typeSystem as TypeSystemImpl,
      InheritanceManager3(), // unused
      sessionHelper.session.analysisContext.analysisOptions,
      null,
      pathContext,
    );
  }

  /// Return the mixin declaration for the given [element].
  Future<MixinDeclaration?> getMixinDeclaration(MixinElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var node = result?.node;
    if (node is MixinDeclaration) {
      return node;
    }
    return null;
  }

  /// Return the class element associated with the [target], or `null` if there
  /// is no such class element.
  InterfaceElement? getTargetInterfaceElement(Expression target) {
    var type = target.staticType;
    if (type is InterfaceType) {
      return type.element;
    } else if (target is Identifier) {
      var element = target.staticElement;
      if (element is InterfaceElement) {
        return element;
      }
    }
    return null;
  }

  /// Returns an expected [DartType] of [expression], may be `null` if cannot be
  /// inferred.
  DartType? inferUndefinedExpressionType(Expression expression) {
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
        return rhs.staticType;
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
        if (statement.expression == expression) {
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

/// The behavior shared by [ResolvedCorrectionProducer] and [MultiCorrectionProducer].
abstract class _AbstractCorrectionProducer<T extends ParsedUnitResult> {
  /// The context used to produce corrections.
  /// TODO(migration) Make it not `late`, require in constructor.
  late CorrectionProducerContext<T> _context;

  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic, such a node does not
  /// exist, or if it hasn't been computed yet. Use [coveredNode] to access this
  /// field.
  AstNode? _coveredNode;

  /// Initialize a newly created producer.
  _AbstractCorrectionProducer();

  /// Return `true` if the fixes are being built for the bulk-fix request.
  bool get applyingBulkFixes => _context.applyingBulkFixes;

  CodeStyleOptions get codeStyleOptions =>
      sessionHelper.session.analysisContext.analysisOptions.codeStyleOptions;

  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic or if such a node does
  /// not exist.
  AstNode? get coveredNode {
    // TODO(brianwilkerson) Consider renaming this to `coveringNode`.
    if (_coveredNode == null) {
      final diagnostic = this.diagnostic;
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
  Diagnostic? get diagnostic => _context.diagnostic;

  /// Returns the EOL to use for this [CompilationUnit].
  String get eol => utils.endOfLine;

  String get file => _context.file;

  Flutter get flutter => Flutter.instance;

  /// See [CompilationUnitImpl.invalidNodes]
  List<AstNode> get invalidNodes {
    return (unit as CompilationUnitImpl).invalidNodes;
  }

  AstNode get node => _context.node;

  /// Return the set of overrides to be applied to the transform set when
  /// running tests, or `null` if there are no overrides to apply.
  TransformOverrideSet? get overrideSet => _context.overrideSet;

  /// Return the resource provider used to access the file system.
  ResourceProvider get resourceProvider => unitResult.session.resourceProvider;

  int get selectionEnd => _context.selectionEnd;

  int get selectionLength => _context.selectionLength;

  int get selectionOffset => _context.selectionOffset;

  AnalysisSessionHelper get sessionHelper => _context.sessionHelper;

  Token get token => _context.token;

  CompilationUnit get unit => _context.unit;

  T get unitResult => _context.unitResult;

  CorrectionUtils get utils => _context.utils;

  /// Configure this producer based on the [context].
  void configure(CorrectionProducerContext<T> context) {
    _context = context;
  }

  /// Return the text that should be displayed to users when referring to the
  /// given [type].
  String displayStringForType(DartType type) =>
      type.getDisplayString(withNullability: _context.isNonNullableByDefault);

  /// Return the function body of the most deeply nested method or function that
  /// encloses the [node], or `null` if the node is not in a method or function.
  FunctionBody? getEnclosingFunctionBody() {
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

  /// Return the mapping from a library (that is available to this context) to
  /// a top-level declaration that is exported (not necessary declared) by this
  /// library, and has the requested base name. For getters and setters the
  /// corresponding top-level variable is returned.
  Future<Map<LibraryElement, Element>> getTopLevelDeclarations(
    String baseName,
  ) {
    return _context.dartFixContext!.getTopLevelDeclarations(baseName);
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

  /// Return libraries with extensions that declare non-static public
  /// extension members with the [memberName].
  Stream<LibraryElement> librariesWithExtensions(String memberName) {
    return _context.dartFixContext!.librariesWithExtensions(memberName);
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

  /// If the [node] might be a type name, return its name.
  String? nameOfType(AstNode node) {
    if (node is SimpleIdentifier) {
      var name = node.name;
      if (node.parent is NamedType || _isNameOfType(name)) {
        return name;
      }
    }
    return null;
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
