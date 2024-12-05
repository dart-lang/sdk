// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/analysis.dart';
import 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

export 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;
export 'package:analyzer/src/lint/state.dart'
    show dart2_12, dart3, dart3_3, State;

/// The result of attempting to evaluate an expression as a constant.
final class LinterConstantEvaluationResult {
  /// The value of the expression, or `null` if has [errors].
  final DartObject? value;

  /// The errors reported during the evaluation.
  final List<AnalysisError> errors;

  LinterConstantEvaluationResult._(this.value, this.errors);
}

/// Provides access to information needed by lint rules that is not available
/// from AST nodes or the element model.
abstract class LinterContext {
  /// The list of all compilation units that make up the library under analysis,
  /// including the defining compilation unit, all parts, and all augmentations.
  List<LintRuleUnitContext> get allUnits;

  /// The defining compilation unit of the library under analysis.
  LintRuleUnitContext get definingUnit;

  InheritanceManager3 get inheritanceManager;

  /// Whether the [definingUnit]'s location is in a package's top-level 'lib'
  /// directory, including locations deeply nested, and locations in the
  /// package-implementation directory, 'lib/src'.
  bool get isInLibDir;

  /// Whether the [definingUnit] is in a [package]'s "test" directory.
  bool get isInTestDirectory;

  LibraryElement? get libraryElement;

  /// The library element representing the library that contains the compilation
  /// unit being linted.
  @experimental
  LibraryElement2? get libraryElement2;

  /// The package in which the library being analyzed lives, or `null` if it
  /// does not live in a package.
  WorkspacePackage? get package;

  TypeProvider get typeProvider;

  TypeSystem get typeSystem;

  static bool _isInLibDir(String? path, WorkspacePackage? package) {
    if (package == null) return false;
    if (path == null) return false;
    var libDir = p.join(package.root, 'lib');
    return p.isWithin(libDir, path);
  }
}

/// A [LinterContext] for a library, resolved into [ParsedUnitResult]s.
final class LinterContextWithParsedResults implements LinterContext {
  @override
  final List<LintRuleUnitContext> allUnits;

  @override
  final LintRuleUnitContext definingUnit;

  @override
  final InheritanceManager3 inheritanceManager = InheritanceManager3();

  LinterContextWithParsedResults(this.allUnits, this.definingUnit);

  @override
  bool get isInLibDir => LinterContext._isInLibDir(
      definingUnit.unit.declaredElement?.source.fullName, package);

  @override
  bool get isInTestDirectory => false;

  @override
  LibraryElement get libraryElement => throw UnsupportedError(
      'LinterContext with parsed results does not include a LibraryElement');

  @experimental
  @override
  LibraryElement2 get libraryElement2 => throw UnsupportedError(
      'LinterContext with parsed results does not include a LibraryElement');

  @override
  WorkspacePackage? get package => null;

  @override
  TypeProvider get typeProvider => throw UnsupportedError(
      'LinterContext with parsed results does not include a TypeProvider');

  @override
  TypeSystem get typeSystem => throw UnsupportedError(
      'LinterContext with parsed results does not include a TypeSystem');
}

/// A [LinterContext] for a library, resolved into [ResolvedUnitResult]s.
final class LinterContextWithResolvedResults implements LinterContext {
  @override
  final List<LintRuleUnitContext> allUnits;

  @override
  final LintRuleUnitContext definingUnit;

  @override
  final WorkspacePackage? package;

  @override
  final TypeProvider typeProvider;

  @override
  final TypeSystemImpl typeSystem;

  @override
  final InheritanceManager3 inheritanceManager;

  LinterContextWithResolvedResults(
    this.allUnits,
    this.definingUnit,
    this.typeProvider,
    this.typeSystem,
    this.inheritanceManager,
    this.package,
  );

  @override
  bool get isInLibDir => LinterContext._isInLibDir(
      definingUnit.unit.declaredElement?.source.fullName, package);

  @override
  bool get isInTestDirectory {
    if (package case var package?) {
      var file = definingUnit.file;
      return package.isInTestDirectory(file);
    }
    return false;
  }

  @override
  LibraryElement get libraryElement =>
      definingUnit.unit.declaredElement!.library;

  @experimental
  @override
  LibraryElement2 get libraryElement2 => libraryElement as LibraryElement2;
}

class LinterOptions extends DriverOptions {
  final Iterable<LintRule> enabledRules;
  final String? analysisOptions;
  LintFilter? filter;

  LinterOptions({
    Iterable<LintRule>? enabledRules,
    this.analysisOptions,
    this.filter,
  }) : enabledRules = enabledRules ?? Registry.ruleRegistry;
}

/// Filtered lints are omitted from linter output.
abstract class LintFilter {
  bool filter(AnalysisError lint);
}

/// Describes a lint rule.
abstract class LintRule {
  /// Used to report lint warnings.
  /// NOTE: this is set by the framework before any node processors start
  /// visiting nodes.
  late ErrorReporter _reporter;

  /// Description (in markdown format) suitable for display in a detailed lint
  /// description.
  ///
  /// This property is deprecated and will be removed in a future release.
  @Deprecated('Use .description for a short description and consider placing '
      'long-form documentation on an external website.')
  final String details;

  /// Short description suitable for display in console output.
  final String description;

  /// Deprecated field of lint groups (for example, 'style', 'errors', 'pub').
  @Deprecated('Lint rule categories are no longer used.')
  final Set<String> categories;

  /// Lint name.
  final String name;

  /// The state of a lint, and optionally since when the state began.
  final State state;

  LintRule({
    required this.name,
    @Deprecated('Lint rule categories are no longer used. Remove the argument.')
    this.categories = const <String>{},
    required this.description,
    @Deprecated("Specify 'details' for a short description and consider "
        'placing long-form documentation on an external website.')
    this.details = '',
    State? state,
  }) : state = state ?? State.stable();

  /// Indicates whether the lint rule can work with just the parsed information
  /// or if it requires a resolved unit.
  bool get canUseParsedResult => false;

  /// A list of incompatible rule ids.
  List<String> get incompatibleRules => const [];

  /// The lint code associated with this linter, if it is only associated with a
  /// single lint code.
  ///
  /// Note that this property is just a convenient shorthand for a rule to
  /// associate a lint rule with a single lint code. Use [lintCodes] for the
  /// full list of (possibly multiple) lint codes which a lint rule may be
  /// associated with.
  LintCode get lintCode => throw UnimplementedError(
      "'lintCode' is not implemented for $runtimeType");

  /// The lint codes associated with this lint rule.
  List<LintCode> get lintCodes => [lintCode];

  @protected
  // Protected so that lint rule visitors do not access this directly.
  // TODO(srawlins): With the new availability of an ErrorReporter on
  // LinterContextUnit, we should probably remove this reporter. But whatever
  // the new API would be is not yet decided. It might also change with the
  // notion of post-processing lint rules that have access to all unit
  // reporters at once.
  ErrorReporter get reporter => _reporter;

  set reporter(ErrorReporter value) => _reporter = value;

  /// Return a visitor to be passed to pubspecs to perform lint
  /// analysis.
  /// Lint errors are reported via this [Linter]'s error [reporter].
  PubspecVisitor? getPubspecVisitor() => null;

  /// Registers node processors in the given [registry].
  ///
  /// The node processors may use the provided [context] to access information
  /// that is not available from the AST nodes or their associated elements.
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {}

  void reportLint(AstNode? node,
      {List<Object> arguments = const [],
      List<DiagnosticMessage>? contextMessages,
      ErrorCode? errorCode,
      bool ignoreSyntheticNodes = true}) {
    if (node != null && (!node.isSynthetic || !ignoreSyntheticNodes)) {
      reporter.atNode(
        node,
        errorCode ?? lintCode,
        arguments: arguments,
        contextMessages: contextMessages,
      );
    }
  }

  void reportLintForOffset(int offset, int length,
      {List<Object> arguments = const [],
      List<DiagnosticMessage>? contextMessages,
      ErrorCode? errorCode}) {
    reporter.atOffset(
      offset: offset,
      length: length,
      errorCode: errorCode ?? lintCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
  }

  void reportLintForToken(Token? token,
      {List<Object> arguments = const [],
      List<DiagnosticMessage>? contextMessages,
      ErrorCode? errorCode,
      bool ignoreSyntheticTokens = true}) {
    if (token != null && (!token.isSynthetic || !ignoreSyntheticTokens)) {
      reporter.atToken(
        token,
        errorCode ?? lintCode,
        arguments: arguments,
        contextMessages: contextMessages,
      );
    }
  }

  void reportPubLint(PSNode node,
      {List<Object> arguments = const [],
      List<DiagnosticMessage> contextMessages = const [],
      ErrorCode? errorCode}) {
    // Cache error and location info for creating `AnalysisErrorInfo`s.
    var error = AnalysisError.tmp(
      source: node.source,
      offset: node.span.start.offset,
      length: node.span.length,
      errorCode: errorCode ?? lintCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
    reporter.reportError(error);
  }
}

/// Provides access to information needed by lint rules that is not available
/// from AST nodes or the element model.
class LintRuleUnitContext {
  final File file;
  final String content;
  final ErrorReporter errorReporter;
  final CompilationUnit unit;

  LintRuleUnitContext({
    required this.file,
    required this.content,
    required this.errorReporter,
    required this.unit,
  });

  /// The library fragment representing the compilation unit.
  @experimental
  LibraryFragment get libraryFragment => unit as LibraryFragment;
}

/// An error listener that only records whether any constant related errors have
/// been reported.
class _ConstantAnalysisErrorListener extends AnalysisErrorListener {
  /// A flag indicating whether any constant related errors have been reported
  /// to this listener.
  bool hasConstError = false;

  @override
  void onError(AnalysisError error) {
    ErrorCode errorCode = error.errorCode;
    if (errorCode is CompileTimeErrorCode) {
      switch (errorCode) {
        case CompileTimeErrorCode
              .CONST_CONSTRUCTOR_CONSTANT_FROM_DEFERRED_LIBRARY:
        case CompileTimeErrorCode
              .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST:
        case CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD:
        case CompileTimeErrorCode.CONST_EVAL_EXTENSION_TYPE_METHOD:
        case CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION:
        case CompileTimeErrorCode.CONST_EVAL_PROPERTY_ACCESS:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_INT:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_NUM:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_NUM_STRING:
        case CompileTimeErrorCode.CONST_EVAL_TYPE_STRING:
        case CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION:
        case CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE:
        case CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT:
        case CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY:
        case CompileTimeErrorCode.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY:
        case CompileTimeErrorCode.CONST_TYPE_PARAMETER:
        case CompileTimeErrorCode.CONST_WITH_NON_CONST:
        case CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT:
        case CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS:
        case CompileTimeErrorCode
              .CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF:
        case CompileTimeErrorCode.INVALID_CONSTANT:
        case CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL:
        case CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL:
        case CompileTimeErrorCode.MISSING_CONST_IN_SET_LITERAL:
        case CompileTimeErrorCode.NON_BOOL_CONDITION:
        case CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT:
        case CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT:
        case CompileTimeErrorCode.NON_CONSTANT_MAP_KEY:
        case CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE:
        case CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD:
        case CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT:
          hasConstError = true;
      }
    }
  }
}

extension on AstNode {
  /// Whether [ConstantVerifier] reports an error when computing the value of
  /// `this` as a constant.
  bool get hasConstantVerifierError {
    var unitElement = thisOrAncestorOfType<CompilationUnit>()?.declaredElement;
    if (unitElement == null) return false;
    var libraryElement = unitElement.library as LibraryElementImpl;

    var dependenciesFinder = ConstantExpressionsDependenciesFinder();
    accept(dependenciesFinder);
    computeConstants(
      declaredVariables: unitElement.session.declaredVariables,
      constants: dependenciesFinder.dependencies.toList(),
      featureSet: libraryElement.featureSet,
      configuration: ConstantEvaluationConfiguration(),
    );

    var listener = _ConstantAnalysisErrorListener();
    var errorReporter = ErrorReporter(listener, unitElement.source);

    accept(
      ConstantVerifier(
        errorReporter,
        libraryElement,
        unitElement.session.declaredVariables,
      ),
    );
    return listener.hasConstError;
  }
}

extension ConstructorDeclarationExtension on ConstructorDeclaration {
  bool get canBeConst {
    var element = declaredElement!;

    var classElement = element.enclosingElement3;
    if (classElement is ClassElement && classElement.hasNonFinalField) {
      return false;
    }

    var oldKeyword = constKeyword;
    var self = this as ConstructorDeclarationImpl;
    try {
      temporaryConstConstructorElements[element] = true;
      self.constKeyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      temporaryConstConstructorElements[element] = null;
      self.constKeyword = oldKeyword;
    }
  }
}

extension ExpressionExtension on Expression {
  /// Whether it would be valid for this expression to have a `const` keyword.
  ///
  /// Note that this method can cause constant evaluation to occur, which can be
  /// computationally expensive.
  bool get canBeConst {
    var self = this;
    return switch (self) {
      InstanceCreationExpressionImpl() => _canBeConstInstanceCreation(self),
      TypedLiteralImpl() => _canBeConstTypedLiteral(self),
      _ => false,
    };
  }

  /// Computes the constant value of `this`, if it has one.
  ///
  /// Returns a [LinterConstantEvaluationResult], containing both the computed
  /// constant value, and a list of errors that occurred during the computation.
  LinterConstantEvaluationResult computeConstantValue() {
    var unitElement = thisOrAncestorOfType<CompilationUnit>()?.declaredElement;
    if (unitElement == null) return LinterConstantEvaluationResult._(null, []);
    var libraryElement = unitElement.library as LibraryElementImpl;

    var errorListener = RecordingErrorListener();

    var evaluationEngine = ConstantEvaluationEngine(
      declaredVariables: unitElement.session.declaredVariables,
      configuration: ConstantEvaluationConfiguration(),
    );

    var dependencies = <ConstantEvaluationTarget>[];
    accept(ReferenceFinder(dependencies.add));

    computeConstants(
      declaredVariables: unitElement.session.declaredVariables,
      constants: dependencies,
      featureSet: libraryElement.featureSet,
      configuration: ConstantEvaluationConfiguration(),
    );

    var visitor = ConstantVisitor(
      evaluationEngine,
      libraryElement,
      ErrorReporter(errorListener, unitElement.source),
    );

    var constant = visitor.evaluateAndReportInvalidConstant(this);
    var dartObject = constant is DartObjectImpl ? constant : null;
    return LinterConstantEvaluationResult._(dartObject, errorListener.errors);
  }

  bool _canBeConstInstanceCreation(InstanceCreationExpressionImpl node) {
    var element = node.constructorName.staticElement;
    if (element == null || !element.isConst) return false;

    // Ensure that dependencies (e.g. default parameter values) are computed.
    var implElement = element.declaration as ConstructorElementImpl;
    implElement.computeConstantDependencies();

    // Verify that the evaluation of the constructor would not produce an
    // exception.
    var oldKeyword = node.keyword;
    try {
      node.keyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      node.keyword = oldKeyword;
    }
  }

  bool _canBeConstTypedLiteral(TypedLiteralImpl node) {
    var oldKeyword = node.constKeyword;
    try {
      node.constKeyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      node.constKeyword = oldKeyword;
    }
  }
}
