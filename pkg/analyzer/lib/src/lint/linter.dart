// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

export 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;
export 'package:analyzer/src/lint/state.dart'
    show dart2_12, dart3, dart3_3, State;

/// Describes a static analysis rule, either a lint rule (which must be enabled
/// via analysis options) or a warning rule (which is enabled by default).
typedef AnalysisRule = LintRule;

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
  final TypeSystem typeSystem;

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

/// Describes a lint rule.
abstract class LintRule {
  /// Used to report lint warnings.
  /// NOTE: this is set by the framework before any node processors start
  /// visiting nodes.
  late ErrorReporter _reporter;

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
  LibraryFragment get libraryFragment => unit.declaredFragment!;
}
