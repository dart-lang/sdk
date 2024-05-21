// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/results.dart';
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
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// How broadly a [CorrectionProducer] can be applied.
///
/// Each value of this enum is cumulative, as the index increases. When a
/// correctiopn producer has a given applicability, it also can be applied with
/// each lower-indexed value. For example, a correction producer with an
/// applicability of [CorrectionApplicability.acrossFiles] can also be used to
/// apply corrections across a single file
/// ([CorrectionApplicability.singleLocation]) and at a single location
/// ([CorrectionApplicability.singleLocation]). The [CorrectionProducer] getters
/// reflect this property: [CorrectionProducer.canBeAppliedAcrossSingleFile],
/// [CorrectionProducer.canBeAppliedAcrossFiles],
/// [CorrectionProducer.canBeAppliedAutomatically].
enum CorrectionApplicability {
  /// Indicates a correction can be applied only at a specific location.
  ///
  /// A correction with this applicability is not applicable across a file,
  /// across multiple files, or valid to be applied automatically.
  singleLocation,

  /// Indicates a correction can be applied in multiple positions in the same
  /// file.
  ///
  /// A correction with this applicability is also applicable at a specific
  /// location, but not applicable across multiple files, or valid to be applied
  /// automatically.
  ///
  /// This flag is used to provide the option for a user to fix a specific
  /// diagnostic across a file (such as a quick fix to "fix all _something_ in
  /// this file").
  acrossSingleFile,

  /// Indicates a correction can be applied across in bulk across multiple files
  /// and/or at the same time as applying fixes from other producers.
  ///
  /// A correction with this applicability is also applicable at a specific
  /// location, and across a file, but not valid to be applied automatically.
  ///
  /// Cases where this is not applicable include fixes for which
  /// - the modified regions can overlap, and
  /// - fixes that have not been tested to ensure that they can be used this
  ///   way.
  acrossFiles,

  /// Indicates a correction can be applied in multiple locations, even if not
  /// chosen explicitly as a tool action, and can be applied to potentially
  /// incomplete code.
  ///
  /// A correction with this applicability is also applicable at a specific
  /// location, and across a file, and across multiple files.
  automatically,
}

/// An object that can compute a correction (fix or assist) in a Dart file.
abstract class CorrectionProducer<T extends ParsedUnitResult>
    extends _AbstractCorrectionProducer<T> {
  CorrectionApplicability get applicability;

  /// The arguments that should be used when composing the message for an
  /// assist, or `null` if the assist message has no parameters or if this
  /// producer doesn't support assists.
  List<String>? get assistArguments => null;

  /// The assist kind that should be used to build an assist, or `null` if this
  /// producer doesn't support assists.
  AssistKind? get assistKind => null;

  /// Whether this producer can be used to apply a correction in multiple
  /// positions simultaneously in bulk across multiple files and/or at the same
  /// time as applying corrections from other producers.
  bool get canBeAppliedAcrossFiles =>
      applicability == CorrectionApplicability.acrossFiles ||
      applicability == CorrectionApplicability.automatically;

  /// Whether this producer can be used to apply a correction in multiple
  /// positions simultaneously across a file.
  bool get canBeAppliedAcrossSingleFile =>
      applicability == CorrectionApplicability.acrossSingleFile ||
      applicability == CorrectionApplicability.acrossFiles ||
      applicability == CorrectionApplicability.automatically;

  /// Whether this producer can be used to apply a correction automatically when
  /// code could be incomplete, as well as in multiple positions simultaneously
  /// in bulk across multiple files and/or at the same time as applying
  /// corrections from other producers.
  bool get canBeAppliedAutomatically =>
      applicability == CorrectionApplicability.automatically;

  /// The length of the error message being fixed, or `null` if there is no
  /// diagnostic.
  int? get errorLength => diagnostic?.problemMessage.length;

  /// The text of the error message being fixed, or `null` if there is no
  /// diagnostic.
  String? get errorMessage =>
      diagnostic?.problemMessage.messageText(includeUrl: true);

  /// The offset of the error message being fixed, or `null` if there is no
  /// diagnostic.
  int? get errorOffset => diagnostic?.problemMessage.offset;

  /// The arguments that should be used when composing the message for a fix, or
  /// `null` if the fix message has no parameters or if this producer doesn't
  /// support fixes.
  List<String>? get fixArguments => null;

  /// The fix kind that should be used to build a fix, or `null` if this
  /// producer doesn't support fixes.
  ///
  /// If the kind of fix is dynamic, it should be computed during [configure]
  /// and not [compute] because some callers may need to know the kind of fix
  /// in advance of computing.
  FixKind? get fixKind => null;

  /// The arguments that should be used when composing the message for a
  /// multi-fix, or `null` if the fix message has no parameters or if this
  /// producer doesn't support multi-fixes.
  List<String>? get multiFixArguments => null;

  /// The fix kind that should be used to build a multi-fix, or `null` if this
  /// producer doesn't support multi-fixes.
  FixKind? get multiFixKind => null;

  /// Computes the changes for this producer using [builder].
  ///
  /// This method should not modify [fixKind]. If this producer supports
  /// multiple kinds of fixes, the kind should be computed during [configure].
  Future<void> compute(ChangeBuilder builder);

  /// Configures this producer based on the [context].
  ///
  /// If the fix needs to dynamically set [fixKind], it should be done here.
  @override
  void configure(CorrectionProducerContext<T> context) {
    super.configure(context);
  }
}

class CorrectionProducerContext<UnitResult extends ParsedUnitResult> {
  final int _selectionOffset;
  final int _selectionLength;

  final CorrectionUtils _utils;

  final AnalysisSessionHelper _sessionHelper;
  final UnitResult _unitResult;

  // TODO(migration): Make it non-nullable, specialize "fix" context?
  final DartFixContext? dartFixContext;

  /// A flag indicating whether the correction producers will be run in the
  /// context of applying bulk fixes.
  final bool _applyingBulkFixes;

  final Diagnostic? _diagnostic;

  final AstNode _node;

  final Token _token;

  CorrectionProducerContext._({
    required UnitResult unitResult,
    bool applyingBulkFixes = false,
    this.dartFixContext,
    Diagnostic? diagnostic,
    required AstNode node,
    required Token token,
    int selectionOffset = -1,
    int selectionLength = 0,
  })  : _unitResult = unitResult,
        _sessionHelper = AnalysisSessionHelper(unitResult.session),
        _utils = CorrectionUtils(unitResult),
        _applyingBulkFixes = applyingBulkFixes,
        _diagnostic = diagnostic,
        _node = node,
        _token = token,
        _selectionOffset = selectionOffset,
        _selectionLength = selectionLength;

  String get path => _unitResult.path;

  int get _selectionEnd => _selectionOffset + _selectionLength;

  static CorrectionProducerContext<ParsedUnitResult> createParsed({
    required ParsedUnitResult resolvedResult,
    bool applyingBulkFixes = false,
    DartFixContext? dartFixContext,
    Diagnostic? diagnostic,
    int selectionOffset = -1,
    int selectionLength = 0,
  }) {
    var selection = resolvedResult.unit.select(
      offset: selectionOffset,
      length: selectionLength,
    );
    var node = selection?.coveringNode;
    node ??= resolvedResult.unit;

    var token = _tokenAt(node, selectionOffset) ?? node.beginToken;

    return CorrectionProducerContext._(
      unitResult: resolvedResult,
      node: node,
      token: token,
      applyingBulkFixes: applyingBulkFixes,
      dartFixContext: dartFixContext,
      diagnostic: diagnostic,
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
    );
  }

  static CorrectionProducerContext<ResolvedUnitResult>? createResolved({
    required ResolvedUnitResult resolvedResult,
    bool applyingBulkFixes = false,
    DartFixContext? dartFixContext,
    Diagnostic? diagnostic,
    int selectionOffset = -1,
    int selectionLength = 0,
  }) {
    var selectionEnd = selectionOffset + selectionLength;
    var locator = NodeLocator(selectionOffset, selectionEnd);
    var node = locator.searchWithin(resolvedResult.unit);
    node ??= resolvedResult.unit;

    var token = _tokenAt(node, selectionOffset) ?? node.beginToken;

    return CorrectionProducerContext._(
      unitResult: resolvedResult,
      node: node,
      token: token,
      applyingBulkFixes: applyingBulkFixes,
      dartFixContext: dartFixContext,
      diagnostic: diagnostic,
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
    );
  }

  static Token? _tokenAt(AstNode node, int offset) {
    for (var entity in node.childEntities) {
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
  // TODO(migration): Consider providing it via constructor.
  @override
  Diagnostic get diagnostic => super.diagnostic!;
}

/// An object that can dynamically compute multiple corrections (fixes or
/// assists).
abstract class MultiCorrectionProducer
    extends _AbstractCorrectionProducer<ResolvedUnitResult> {
  /// The library element for the library in which a correction is being
  /// produced.
  LibraryElement get libraryElement => unitResult.libraryElement;

  /// The individual producers generated by this producer.
  Future<List<ResolvedCorrectionProducer>> get producers;

  TypeProvider get typeProvider => unitResult.typeProvider;

  /// The type system appropriate to the library in which the correction is
  /// requested.
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
  AnalysisOptionsImpl get analysisOptions =>
      sessionHelper.session.analysisContext
          .getAnalysisOptionsForFile(unitResult.file) as AnalysisOptionsImpl;

  /// The type for the class `bool` from `dart:core`.
  DartType get coreTypeBool => unitResult.typeProvider.boolType;

  /// Whether [node] is in a static context.
  bool get inStaticContext {
    // Constructor initializers cannot reference `this`.
    if (node.thisOrAncestorOfType<ConstructorInitializer>() != null) {
      return true;
    }
    // Field initializers cannot reference `this`.
    var fieldDeclaration = node.thisOrAncestorOfType<FieldDeclaration>();
    if (fieldDeclaration != null) {
      return fieldDeclaration.isStatic || !fieldDeclaration.fields.isLate;
    }
    // Static method.
    var method = node.thisOrAncestorOfType<MethodDeclaration>();
    return method != null && method.isStatic;
  }

  /// The library element for the library in which a correction is being
  /// produced.
  LibraryElement get libraryElement => unitResult.libraryElement;

  TypeProvider get typeProvider => unitResult.typeProvider;

  /// The type system appropriate to the library in which the correction is
  /// requested.
  TypeSystem get typeSystem => unitResult.typeSystem;

  /// Returns the class declaration for the given [element], or `null` if there
  /// is no such class.
  Future<ClassDeclaration?> getClassDeclaration(ClassElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var node = result?.node;
    if (node is ClassDeclaration) {
      return node;
    }
    return null;
  }

  /// Returns the extension declaration for the given [element], or `null` if
  /// there is no such extension.
  Future<ExtensionDeclaration?> getExtensionDeclaration(
      ExtensionElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var node = result?.node;
    if (node is ExtensionDeclaration) {
      return node;
    }
    return null;
  }

  /// Returns the extension type for the given [element], or `null` if there
  /// is no such extension type.
  Future<ExtensionTypeDeclaration?> getExtensionTypeDeclaration(
      ExtensionTypeElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var node = result?.node;
    if (node is ExtensionTypeDeclaration) {
      return node;
    }
    return null;
  }

  /// Returns the mixin declaration for the given [element], or `null` if there
  /// is no such mixin.
  Future<MixinDeclaration?> getMixinDeclaration(MixinElement element) async {
    var result = await sessionHelper.getElementDeclaration(element);
    var node = result?.node;
    if (node is MixinDeclaration) {
      return node;
    }
    return null;
  }

  /// Returns the class element associated with the [target], or `null` if there
  /// is no such element.
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
    // `myFunction();`.
    if (parent is ExpressionStatement) {
      if (expression is MethodInvocation) {
        return VoidTypeImpl.instance;
      }
    }
    // `return myFunction();`.
    if (parent is ReturnStatement) {
      var executable = getEnclosingExecutableElement(expression);
      return executable?.returnType;
    }
    // `int v = myFunction();`.
    if (parent is VariableDeclaration) {
      var variableDeclaration = parent;
      if (variableDeclaration.initializer == expression) {
        var variableElement = variableDeclaration.declaredElement;
        if (variableElement != null) {
          return variableElement.type;
        }
      }
    }
    // `myField = 42;`.
    if (parent is AssignmentExpression) {
      var assignment = parent;
      if (assignment.leftHandSide == expression) {
        var rhs = assignment.rightHandSide;
        return rhs.staticType;
      }
    }
    // `v = myFunction();`.
    if (parent is AssignmentExpression) {
      var assignment = parent;
      if (assignment.rightHandSide == expression) {
        if (assignment.operator.type == TokenType.EQ) {
          // `v = myFunction();`.
          return assignment.writeType;
        } else {
          // `v += myFunction();`.
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
    // `v + myFunction();`.
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
    // `foo( myFunction() );`.
    if (parent is ArgumentList) {
      var parameter = expression.staticParameterElement;
      return parameter?.type;
    }
    // `bool`.
    {
      // `assert( myFunction() );`.
      if (parent is AssertStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // `if ( myFunction() ) {}`.
      if (parent is IfStatement) {
        var statement = parent;
        if (statement.expression == expression) {
          return coreTypeBool;
        }
      }
      // `while ( myFunction() ) {}`.
      if (parent is WhileStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // `do {} while ( myFunction() );`.
      if (parent is DoStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return coreTypeBool;
        }
      }
      // `!myFunction()`.
      if (parent is PrefixExpression) {
        var prefixExpression = parent;
        if (prefixExpression.operator.type == TokenType.BANG) {
          return coreTypeBool;
        }
      }
      // Binary expression `&&` or `||`.
      if (parent is BinaryExpression) {
        var binaryExpression = parent;
        var operatorType = binaryExpression.operator.type;
        if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
            operatorType == TokenType.BAR_BAR) {
          return coreTypeBool;
        }
      }
    }
    // We don't know.
    return null;
  }
}

/// The behavior shared by [ResolvedCorrectionProducer] and
/// [MultiCorrectionProducer].
abstract class _AbstractCorrectionProducer<T extends ParsedUnitResult> {
  /// The context used to produce corrections.
  // TODO(migration): Make it not `late`, require in constructor.
  late CorrectionProducerContext<T> _context;

  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic, such a node does not
  /// exist, or if it hasn't been computed yet.
  ///
  /// Use [coveredNode] to access this field.
  AstNode? _coveredNode;

  /// Whether the fixes are being built for the bulk-fix request.
  bool get applyingBulkFixes => _context._applyingBulkFixes;

  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic or if such a node does
  /// not exist.
  AstNode? get coveredNode {
    // TODO(brianwilkerson): Consider renaming this to `coveringNode`.
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

  /// The diagnostic being fixed, or `null` if this producer is being
  /// used to produce an assist.
  Diagnostic? get diagnostic => _context._diagnostic;

  /// The EOL sequence to use for this [CompilationUnit].
  String get eol => utils.endOfLine;

  String get file => _context.path;

  /// See [CompilationUnitImpl.invalidNodes].
  List<AstNode> get invalidNodes {
    return (unit as CompilationUnitImpl).invalidNodes;
  }

  AstNode get node => _context._node;

  ResourceProvider get resourceProvider => unitResult.session.resourceProvider;

  int get selectionEnd => _context._selectionEnd;

  int get selectionLength => _context._selectionLength;

  int get selectionOffset => _context._selectionOffset;

  AnalysisSessionHelper get sessionHelper => _context._sessionHelper;

  bool get strictCasts {
    var file = _context.dartFixContext?.resolvedResult.file;
    // TODO(pq): can this ever happen?
    if (file == null) return false;
    var analysisOptions = _context._unitResult.session.analysisContext
        .getAnalysisOptionsForFile(file) as AnalysisOptionsImpl;
    return analysisOptions.strictCasts;
  }

  Token get token => _context._token;

  CompilationUnit get unit => _context._unitResult.unit;

  T get unitResult => _context._unitResult;

  CorrectionUtils get utils => _context._utils;

  /// Configure this producer based on the [context].
  @mustCallSuper
  void configure(CorrectionProducerContext<T> context) {
    _context = context;
  }

  /// Returns the text that should be displayed to users when referring to the
  /// given [type].
  String displayStringForType(DartType type) => type.getDisplayString();

  CodeStyleOptions getCodeStyleOptions(File file) =>
      sessionHelper.session.analysisContext
          .getAnalysisOptionsForFile(file)
          .codeStyleOptions;

  /// Returns the function body of the most deeply nested method or function
  /// that encloses the [node], or `null` if the node is not in a method or
  /// function.
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

  /// Returns the text of the given [range] in the unit.
  String getRangeText(SourceRange range) {
    return utils.getRangeText(range);
  }

  /// Returns the mapping from a library (that is available to this context) to
  /// a top-level declaration that is exported (not necessary declared) by this
  /// library, and has the requested base name. For getters and setters the
  /// corresponding top-level variable is returned.
  Future<Map<LibraryElement, Element>> getTopLevelDeclarations(
    String baseName,
  ) {
    return _context.dartFixContext!.getTopLevelDeclarations(baseName);
  }

  /// Returns whether the selection covers an operator of the given
  /// [binaryExpression].
  bool isOperatorSelected(BinaryExpression binaryExpression) {
    AstNode left = binaryExpression.leftOperand;
    AstNode right = binaryExpression.rightOperand;
    // Between the nodes.
    if (selectionOffset >= left.end &&
        selectionOffset + selectionLength <= right.offset) {
      return true;
    }
    // Or exactly select the node (but not with infix expressions).
    if (selectionOffset == left.offset &&
        selectionOffset + selectionLength == right.end) {
      if (left is BinaryExpression || right is BinaryExpression) {
        return false;
      }
      return true;
    }
    // Invalid selection (part of node, etc).
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
  // TODO(brianwilkerson): Consider moving this to DartFileEditBuilder.
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
