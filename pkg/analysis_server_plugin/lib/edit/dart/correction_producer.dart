// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:meta/meta.dart';

/// How broadly a [CorrectionProducer] can be applied.
///
/// Each value of this enum is cumulative, as the index increases, except for
/// [CorrectionApplicability.automaticallyButOncePerFile]. When a correction
/// producer has a given applicability, it also can be applied with each
/// lower-indexed value. For example, a correction producer with an
/// applicability of [CorrectionApplicability.acrossFiles] can also be used to
/// apply corrections across a single file
/// ([CorrectionApplicability.singleLocation]) and at a single location
/// ([CorrectionApplicability.singleLocation]). The [CorrectionProducer] getters
/// reflect this property: [CorrectionProducer.canBeAppliedAcrossSingleFile],
/// [CorrectionProducer.canBeAppliedAcrossFiles],
/// [CorrectionProducer.canBeAppliedAutomatically].
///
/// Note that [CorrectionApplicability.automaticallyButOncePerFile] is the one
/// value that does not have this cumulative property.
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

  /// Indicates a correction can be applied in multiple files, except only one
  /// location per file; the correction can be applied even if not chosen
  /// explicitly as a tool action, and can be applied to potentially incomplete
  /// code.
  ///
  /// A correction with this applicability is also applicable at a specific
  /// location, and across multiple files.
  automaticallyButOncePerFile,
}

/// An object that can compute a correction (fix or assist) in a Dart file.
sealed class CorrectionProducer<T extends ParsedUnitResult>
    extends _AbstractCorrectionProducer<T> {
  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic, such a node does not
  /// exist, or if it hasn't been computed yet.
  ///
  /// Use [coveringNode] to access this field.
  AstNode? _coveringNode;

  /// Whether the [_coveringNode] field has been set.
  ///
  /// The field may be set to `null`, so it's nullity is not a signal of whether
  /// it needs to be computed.
  bool _coveringNodeIsSet = false;

  CorrectionProducer({required super.context});

  /// The applicability of this producer.
  ///
  /// This property is to be implemented by each subclass, but outside code must
  /// use other properties to determine a producer's applicability:
  /// [canBeAppliedAcrossSingleFile], [canBeAppliedAcrossFiles], and
  /// [canBeAppliedAutomatically].
  @protected
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
      applicability == CorrectionApplicability.automatically ||
      applicability == CorrectionApplicability.automaticallyButOncePerFile;

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
      applicability == CorrectionApplicability.automatically ||
      applicability == CorrectionApplicability.automaticallyButOncePerFile;

  /// The most deeply nested node that completely covers the highlight region of
  /// the diagnostic, or `null` if there is no diagnostic or if such a node does
  /// not exist.
  AstNode? get coveringNode {
    if (_coveringNodeIsSet) {
      return _coveringNode;
    }

    _coveringNodeIsSet = true;
    var diagnostic = this.diagnostic;
    if (diagnostic == null) {
      return null;
    }
    var diagnosticOffset = diagnostic.problemMessage.offset;
    var diagnosticLength = diagnostic.problemMessage.length;
    return _coveringNode = unit.nodeCovering(
      offset: diagnosticOffset,
      length: diagnosticLength,
    );
  }

  /// The length of the source range associated with the diagnostic being
  /// fixed, or `null` if there is no diagnostic.
  int? get diagnosticLength => diagnostic?.problemMessage.length;

  /// The offset of the source range associated with the diagnostic being
  /// fixed, or `null` if there is no diagnostic.
  int? get diagnosticOffset => diagnostic?.problemMessage.offset;

  @Deprecated("Use 'diagnosticLength' instead")
  int? get errorLength => diagnosticLength;

  @Deprecated("Use 'diagnosticOffset' instead")
  int? get errorOffset => diagnosticOffset;

  /// The arguments that should be used when composing the message for a fix, or
  /// `null` if the fix message has no parameters or if this producer doesn't
  /// support fixes.
  List<String>? get fixArguments => null;

  /// The fix kind that should be used to build a fix, or `null` if this
  /// producer doesn't support fixes.
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
  /// This method should not modify [fixKind].
  Future<void> compute(ChangeBuilder builder);
}

final class CorrectionProducerContext {
  final int _selectionOffset;
  final int _selectionLength;

  final CorrectionUtils _utils;

  final AnalysisSessionHelper _sessionHelper;
  final ParsedLibraryResult _libraryResult;
  final ParsedUnitResult _unitResult;

  final DartFixContext? dartFixContext;

  /// Whether the correction producers are run in the context of applying bulk
  /// fixes.
  final bool _applyingBulkFixes;

  final Diagnostic? _diagnostic;

  final AstNode node;

  final Token _token;

  CorrectionProducerContext._({
    required ParsedLibraryResult libraryResult,
    required ParsedUnitResult unitResult,
    required bool applyingBulkFixes,
    required this.dartFixContext,
    required Diagnostic? diagnostic,
    required this.node,
    required Token token,
    required int selectionOffset,
    required int selectionLength,
  }) : _libraryResult = libraryResult,
       _unitResult = unitResult,
       _sessionHelper = AnalysisSessionHelper(unitResult.session),
       _utils = dartFixContext?.correctionUtils ?? CorrectionUtils(unitResult),
       _applyingBulkFixes = applyingBulkFixes,
       _diagnostic = diagnostic,
       _token = token,
       _selectionOffset = selectionOffset,
       _selectionLength = selectionLength;

  String get path => _unitResult.path;

  int get _selectionEnd => _selectionOffset + _selectionLength;

  static CorrectionProducerContext createParsed({
    required ParsedLibraryResult libraryResult,
    required ParsedUnitResult unitResult,
    bool applyingBulkFixes = false,
    DartFixContext? dartFixContext,
    Diagnostic? diagnostic,
    int selectionOffset = -1,
    int selectionLength = 0,
  }) {
    var selection = unitResult.unit.select(
      offset: selectionOffset,
      length: selectionLength,
    );
    var node = selection?.coveringNode;
    node ??= unitResult.unit;

    var token = _tokenAt(node, selectionOffset) ?? node.beginToken;

    return CorrectionProducerContext._(
      libraryResult: libraryResult,
      unitResult: unitResult,
      node: node,
      token: token,
      applyingBulkFixes: applyingBulkFixes,
      dartFixContext: dartFixContext,
      diagnostic: diagnostic,
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
    );
  }

  static CorrectionProducerContext createResolved({
    required ResolvedLibraryResult libraryResult,
    required ResolvedUnitResult unitResult,
    bool applyingBulkFixes = false,
    DartFixContext? dartFixContext,
    Diagnostic? diagnostic,
    int selectionOffset = -1,
    int selectionLength = 0,
  }) {
    var node = unitResult.unit.nodeCovering(
      offset: selectionOffset,
      length: selectionLength,
    );
    node ??= unitResult.unit;

    var token = _tokenAt(node, selectionOffset) ?? node.beginToken;

    return CorrectionProducerContext._(
      libraryResult: libraryResult,
      unitResult: unitResult,
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
  CorrectionProducerWithDiagnostic({required super.context});

  // TODO(migration): Consider providing it via constructor.
  @override
  Diagnostic get diagnostic => super.diagnostic!;
}

/// An object that can dynamically compute multiple corrections (fixes or
/// assists).
abstract class MultiCorrectionProducer
    extends _AbstractCorrectionProducer<ResolvedUnitResult> {
  MultiCorrectionProducer({required super.context});

  CorrectionProducerContext get context => _context;

  /// The library element for the library in which a correction is being
  /// produced.
  LibraryElement get libraryElement2 => unitResult.libraryElement;

  @override
  ResolvedLibraryResult get libraryResult =>
      super.libraryResult as ResolvedLibraryResult;

  /// The individual producers generated by this producer.
  Future<List<ResolvedCorrectionProducer>> get producers;

  @override
  ResolvedUnitResult get unitResult => super.unitResult as ResolvedUnitResult;
}

/// A correction producer that can work on non-resolved units
/// ([ParsedUnitResult]s).
abstract class ParsedCorrectionProducer
    extends CorrectionProducer<ParsedUnitResult> {
  ParsedCorrectionProducer({required super.context});
}

/// A [CorrectionProducer] that can compute a correction (fix or assist) in a
/// Dart file using the resolved AST.
abstract class ResolvedCorrectionProducer
    extends CorrectionProducer<ResolvedUnitResult> {
  ResolvedCorrectionProducer({required super.context});

  AnalysisOptions get analysisOptions => sessionHelper.session.analysisContext
      .getAnalysisOptionsForFile(unitResult.file);

  @Deprecated('Use InterfaceElement members instead')
  InheritanceManager3 get inheritanceManager {
    return (libraryElement2 as LibraryElementImpl).session.inheritanceManager;
  }

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
  LibraryElement get libraryElement2 => unitResult.libraryElement;

  @override
  ResolvedLibraryResult get libraryResult =>
      super.libraryResult as ResolvedLibraryResult;

  TypeProvider get typeProvider => unitResult.typeProvider;

  /// The type system appropriate to the library in which the correction is
  /// requested.
  TypeSystem get typeSystem => unitResult.typeSystem;

  @override
  ResolvedUnitResult get unitResult => super.unitResult as ResolvedUnitResult;

  /// The type for the class `bool` from `dart:core`.
  DartType get _coreTypeBool => typeProvider.boolType;

  /// Returns the class declaration for the given [fragment], or `null` if there
  /// is no such class.
  Future<ClassDeclaration?> getClassDeclaration(ClassFragment fragment) async {
    var result = await sessionHelper.getFragmentDeclaration(fragment);
    var node = result?.node;
    if (node is ClassDeclaration) {
      return node;
    }
    return null;
  }

  Future<CompilationUnitMember?> getDeclarationNodeFromElement(
    InstanceElement element, {
    bool includeExtensions = false,
  }) async {
    if (element.library.isInSdk) return null;
    return switch (element) {
      ClassElement(:var firstFragment) => getClassDeclaration(firstFragment),
      EnumElement(:var firstFragment) => getEnumDeclaration(firstFragment),
      ExtensionElement(:var firstFragment) when includeExtensions =>
        getExtensionDeclaration(firstFragment),
      ExtensionTypeElement(:var firstFragment) => getExtensionTypeDeclaration(
        firstFragment,
      ),
      MixinElement(:var firstFragment) => getMixinDeclaration(firstFragment),
      _ => null,
    };
  }

  /// Returns the class declaration for the given [fragment], or `null` if there
  /// is no such class.
  Future<EnumDeclaration?> getEnumDeclaration(EnumFragment fragment) async {
    var result = await sessionHelper.getFragmentDeclaration(fragment);
    var node = result?.node;
    if (node is EnumDeclaration) {
      return node;
    }
    return null;
  }

  /// Returns the extension declaration for the given [fragment], or `null` if
  /// there is no such extension.
  Future<ExtensionDeclaration?> getExtensionDeclaration(
    ExtensionFragment fragment,
  ) async {
    var result = await sessionHelper.getFragmentDeclaration(fragment);
    var node = result?.node;
    if (node is ExtensionDeclaration) {
      return node;
    }
    return null;
  }

  /// Returns the extension type for the given [fragment], or `null` if there
  /// is no such extension type.
  Future<ExtensionTypeDeclaration?> getExtensionTypeDeclaration(
    ExtensionTypeFragment fragment,
  ) async {
    var result = await sessionHelper.getFragmentDeclaration(fragment);
    var node = result?.node;
    if (node is ExtensionTypeDeclaration) {
      return node;
    }
    return null;
  }

  /// Returns the mixin declaration for the given [fragment], or `null` if there
  /// is no such mixin.
  Future<MixinDeclaration?> getMixinDeclaration(MixinFragment fragment) async {
    var result = await sessionHelper.getFragmentDeclaration(fragment);
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
      var element = target.element;
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
    // `(myFunction(),)` or `(name: myFunction())`.
    if (parent case NamedExpression(parent: var grandParent) && var named) {
      parent = grandParent;
      expression = named;
    }
    if (parent is RecordLiteral) {
      var recordType = inferUndefinedExpressionType(parent);
      if (recordType is RecordType) {
        if (expression case NamedExpression named) {
          return recordType.namedFields
              .firstWhere((field) => field.name == named.name.label.name)
              .type;
        } else {
          var index = parent.fields.indexed
              .firstWhere((record) => record.$2 == expression)
              .$1;
          return recordType.positionalFields[index].type;
        }
      }
    }
    // `await (v + v2)`
    if (parent is ParenthesizedExpression) {
      return inferUndefinedExpressionType(parent);
    }
    // `myFunction();`.
    if (expression is MethodInvocation) {
      if (parent is CascadeExpression && parent.parent is ExpressionStatement) {
        return VoidTypeImpl.instance;
      }
      if (parent is ExpressionStatement) {
        return VoidTypeImpl.instance;
      }
    }
    if (parent case ConditionalExpression conditionalExpression) {
      // `v = myFunction() ? 1 : 2;`.
      if (conditionalExpression.condition == expression) {
        return _coreTypeBool;
      } else {
        var type = conditionalExpression.correspondingParameter?.type;
        if (type is InterfaceType && type.isDartCoreFunction) {
          return FunctionTypeImpl(
            typeParameters: const [],
            parameters: const [],
            returnType: DynamicTypeImpl.instance,
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
        return type;
      }
    }
    // `=> myFunction();`.
    if (parent is ExpressionFunctionBody) {
      if (_closureReturnType(expression) case var returnType?) {
        return returnType;
      }
      var executable = expression.enclosingExecutableElement;
      return executable?.returnType;
    }
    // `return myFunction();`.
    if (parent is ReturnStatement) {
      if (_closureReturnType(expression) case var returnType?) {
        return returnType;
      }
      var executable = expression.enclosingExecutableElement;
      return executable?.returnType;
    }
    // `int v = myFunction();`.
    if (parent is VariableDeclaration) {
      var variableDeclaration = parent;
      if (variableDeclaration.initializer == expression) {
        var variableElement = variableDeclaration.declaredFragment?.element;
        if (variableElement case VariableElement(:var type)) {
          if (type is InvalidType) {
            return typeProvider.dynamicType;
          }
          return type;
        }
      }
    }
    if (parent is AssignmentExpression) {
      var assignment = parent;
      // `myField = 42;`.
      if (assignment.leftHandSide == expression) {
        var rhs = assignment.rightHandSide;
        return rhs.staticType;
      } else if (assignment.rightHandSide == expression) {
        if (assignment.operator.type == TokenType.EQ) {
          // `v = myFunction();`.
          return assignment.writeType;
        } else if (assignment.writeType case var expectedType?) {
          // `v += myFunction();`.
          var method = assignment.element;
          if (method case MethodElement(
            :var returnType,
            formalParameters: List(length: 1, :var first),
          )) {
            if (typeSystem.isAssignableTo(returnType, expectedType)) {
              // The return type is assignable to the expected type, then use
              // the expected parameter type.
              return first.type;
            } else if (typeSystem.isAssignableTo(expectedType, returnType) &&
                typeSystem.isAssignableTo(expectedType, first.type)) {
              // The expected type is a subtype of the return type and the
              // parameter would accept the expected type, then use the
              // expected type.
              // ---
              // Spec (section 17.31) reads:
              // The static type of an additive expression is usually
              // determined by the signature given in the declaration of the
              // operator used. However, invocations of the operators + and -
              // of class int, double and num are treated specially by the
              // typechecker.
              // ---
              // This ensures that cases like `int v = 0; v += myFunction();`
              // will return `int`.
              if (_isSpecialCaseNumTypes(method, expectedType)) {
                return expectedType;
              }
            }
          }
          return InvalidTypeImpl.instance;
        }
      }
    }
    if (parent is BinaryExpression) {
      var binary = parent;
      var method = binary.element;
      // `v + myFunction();`.
      if (method != null) {
        if (binary.rightOperand == expression) {
          var parameters = method.formalParameters;
          return parameters.length == 1 ? parameters[0].type : null;
        }
      } else if (binary.operator.type == TokenType.QUESTION_QUESTION) {
        // `v ?? myFunction();`.
        // This handles when the expression is being assigned somewhere.
        var type = inferUndefinedExpressionType(binary);
        if (binary.rightOperand == expression) {
          return type ?? binary.leftOperand.staticType;
        } else if (binary.leftOperand == expression) {
          type ??= binary.rightOperand.staticType;
          return switch (type) {
            TypeImpl type => type.withNullability(NullabilitySuffix.question),
            _ => null,
          };
        }
      }
    }
    // `foo( myFunction() );`.
    if (parent is ArgumentList) {
      var parameter = expression.correspondingParameter;
      return parameter?.type;
    }
    // `bool`.
    {
      // `assert( myFunction() );`.
      if (parent is AssertStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return _coreTypeBool;
        }
      }
      // `if ( myFunction() ) {}`.
      if (parent is IfStatement) {
        var statement = parent;
        if (statement.expression == expression) {
          return _coreTypeBool;
        }
      }
      if (parent is WhenClause) {
        var clause = parent;
        if (clause.expression == expression) {
          return _coreTypeBool;
        }
      }
      // `while ( myFunction() ) {}`.
      if (parent is WhileStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return _coreTypeBool;
        }
      }
      // `do {} while ( myFunction() );`.
      if (parent is DoStatement) {
        var statement = parent;
        if (statement.condition == expression) {
          return _coreTypeBool;
        }
      }
      // `!myFunction()`.
      if (parent is PrefixExpression) {
        var prefixExpression = parent;
        if (prefixExpression.operator.type == TokenType.BANG) {
          return _coreTypeBool;
        }
      }
      // Binary expression `&&` or `||`.
      if (parent is BinaryExpression) {
        var binaryExpression = parent;
        var operatorType = binaryExpression.operator.type;
        if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
            operatorType == TokenType.BAR_BAR) {
          return _coreTypeBool;
        }
      }
    }
    // Handle `await`, infer a `Future` type.
    if (parent is AwaitExpression) {
      var grandParent = parent.parent;
      // `await myFunction();`
      if (grandParent is ExpressionStatement) {
        return typeProvider.futureType(typeProvider.voidType);
      }
      var inferredParentType =
          inferUndefinedExpressionType(parent) ?? typeProvider.dynamicType;
      if (inferredParentType is InvalidType) {
        inferredParentType = typeProvider.dynamicType;
      }
      return typeProvider.futureType(inferredParentType);
    }
    // We don't know.
    return null;
  }

  bool isEnabled(Feature feature) =>
      libraryElement2.featureSet.isEnabled(feature);

  /// Looks if the [expression] is directly inside a closure and returns the
  /// return type of the closure.
  DartType? _closureReturnType(Expression expression) {
    if (expression.enclosingClosure case FunctionExpression(
      :var correspondingParameter,
      :var staticType,
    )) {
      if (correspondingParameter?.type ?? staticType case FunctionType(
        :var returnType,
      )) {
        return returnType;
      }
    }
    return null;
  }

  bool _isSpecialCaseNumTypes(MethodElement method, DartType expectedType) {
    if (!expectedType.isDartCoreInt) {
      return false;
    }
    if (method.name == TokenType.PLUS.lexeme ||
        method.name == TokenType.MINUS.lexeme ||
        method.name == TokenType.STAR.lexeme) {
      return true;
    }
    return false;
  }
}

/// A stub implementation of [CorrectionProducerContext], which can be used to
/// instantiate a correction producer for the purpose of examining fixed
/// properties on it.
///
/// This has several acceptable use cases:
/// * checking the applicability of a correction producer,
/// * testing purposes,
/// * short-circuiting logic in a correction producer factory constructor that
///   relies on the context's `node` property.
final class StubCorrectionProducerContext implements CorrectionProducerContext {
  static final instance = StubCorrectionProducerContext._();

  StubCorrectionProducerContext._();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unimplemented: ${invocation.memberName}');
}

/// The behavior shared by [CorrectionProducer] and
/// [MultiCorrectionProducer].
sealed class _AbstractCorrectionProducer<T extends ParsedUnitResult> {
  /// The context used to produce corrections.
  final CorrectionProducerContext _context;

  _AbstractCorrectionProducer({required CorrectionProducerContext context})
    : _context = context;

  /// Whether the fixes are being built for the bulk-fix request.
  bool get applyingBulkFixes => _context._applyingBulkFixes;

  /// The default EOL to be used for new files and files that do not have EOLs.
  ///
  /// Existing files with EOL markers will always have the same EOL in inserted
  /// text.
  String get defaultEol => utils.endOfLine;

  /// The diagnostic being fixed, or `null` if this producer is being
  /// used to produce an assist.
  Diagnostic? get diagnostic => _context._diagnostic;

  String get file => _context.path;

  ParsedLibraryResult get libraryResult => _context._libraryResult;

  AstNode get node => _context.node;

  ResourceProvider get resourceProvider => unitResult.session.resourceProvider;

  int get selectionEnd => _context._selectionEnd;

  int get selectionLength => _context._selectionLength;

  int get selectionOffset => _context._selectionOffset;

  AnalysisSessionHelper get sessionHelper => _context._sessionHelper;

  Token get token => _context._token;

  CompilationUnit get unit => _context._unitResult.unit;

  ParsedUnitResult get unitResult => _context._unitResult;

  CorrectionUtils get utils => _context._utils;

  CodeStyleOptions getCodeStyleOptions(File file) => sessionHelper
      .session
      .analysisContext
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
  String getRangeText(SourceRange range) => utils.getRangeText(range);

  /// Returns the mapping from a library (that is available to this context) to
  /// a top-level declaration that is exported (not necessary declared) by this
  /// library, and has the requested base name.
  ///
  /// For getters and setters the corresponding top-level variable is returned.
  Future<Map<LibraryElement, Element>> getTopLevelDeclarations(
    String baseName,
  ) async {
    return await _context.dartFixContext!.getTopLevelDeclarations(baseName);
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

  /// Returns libraries with extensions that declare non-static public
  /// extension members with the [memberName].
  Stream<LibraryElement> librariesWithExtensions(Name memberName) {
    return _context.dartFixContext!.librariesWithExtensions(memberName);
  }
}
