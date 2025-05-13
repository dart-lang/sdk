// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

export 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;
export 'package:analyzer/src/lint/state.dart'
    show dart2_12, dart3, dart3_3, State;

/// Describes an [AbstractAnalysisRule] which reports diagnostics using exactly
/// one [DiagnosticCode].
typedef LintRule = AnalysisRule;

/// Describes a static analysis rule, either a lint rule (which must be enabled
/// via analysis options) or a warning rule (which is enabled by default).
sealed class AbstractAnalysisRule {
  /// Used to report lint warnings.
  /// NOTE: this is set by the framework before any node processors start
  /// visiting nodes.
  late ErrorReporter _reporter;

  /// Short description suitable for display in console output.
  final String description;

  /// Lint name.
  final String name;

  /// The state of a lint, and optionally since when the state began.
  final State state;

  AbstractAnalysisRule({
    required this.name,
    required this.description,
    this.state = const State.stable(),
  });

  /// Indicates whether the lint rule can work with just the parsed information
  /// or if it requires a resolved unit.
  bool get canUseParsedResult => false;

  /// A list of incompatible rule ids.
  List<String> get incompatibleRules => const [];

  /// The lint codes associated with this lint rule.
  List<LintCode> get lintCodes;

  /// Returns a visitor that visits a [Pubspec] to perform analysis.
  ///
  /// Diagnostics are reported via this [LintRule]'s error [reporter].
  PubspecVisitor? get pubspecVisitor => null;

  @protected
  // Protected so that lint rule visitors do not access this directly.
  // TODO(srawlins): With the new availability of an ErrorReporter on
  // LinterContextUnit, we should probably remove this reporter. But whatever
  // the new API would be is not yet decided. It might also change with the
  // notion of post-processing lint rules that have access to all unit
  // reporters at once.
  ErrorReporter get reporter => _reporter;

  set reporter(ErrorReporter value) => _reporter = value;

  /// Registers node processors in the given [registry].
  ///
  /// The node processors may use the provided [context] to access information
  /// that is not available from the AST nodes or their associated elements.
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {}

  void _reportAtNode(
    AstNode? node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
    required DiagnosticCode diagnosticCode,
  }) {
    if (node != null && !node.isSynthetic) {
      reporter.atNode(
        node,
        diagnosticCode,
        arguments: arguments,
        contextMessages: contextMessages,
      );
    }
  }

  void _reportAtOffset(
    int offset,
    int length, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) {
    reporter.atOffset(
      offset: offset,
      length: length,
      errorCode: diagnosticCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
  }

  void _reportAtPubNode(
    PSNode node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage> contextMessages = const [],
    required DiagnosticCode errorCode,
  }) {
    // Cache error and location info for creating `AnalysisErrorInfo`s.
    var error = Diagnostic.tmp(
      source: node.source,
      offset: node.span.start.offset,
      length: node.span.length,
      errorCode: errorCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
    reporter.reportError(error);
  }

  void _reportAtToken(
    Token token, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) {
    if (!token.isSynthetic) {
      reporter.atToken(
        token,
        diagnosticCode,
        arguments: arguments,
        contextMessages: contextMessages,
      );
    }
  }
}

/// Describes an [AbstractAnalysisRule] which reports exactly one type of
/// diagnostic (one [DiagnosticCode]).
abstract class AnalysisRule extends AbstractAnalysisRule {
  AnalysisRule({required super.name, required super.description, super.state});

  LintCode get lintCode;

  @override
  List<LintCode> get lintCodes => [lintCode];

  /// Reports a diagnostic at [node] with message [arguments] and
  /// [contextMessages].
  void reportAtNode(
    AstNode? node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtNode(
    node,
    diagnosticCode: lintCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );

  /// Reports a diagnostic at [offset], with [length], with message [arguments]
  /// and [contextMessages].
  void reportAtOffset(
    int offset,
    int length, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtOffset(
    offset,
    length,
    diagnosticCode: lintCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );

  /// Reports a diagnostic at Pubspec [node], with message [arguments] and
  /// [contextMessages].
  void reportAtPubNode(
    PSNode node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage> contextMessages = const [],
  }) => _reportAtPubNode(
    node,
    errorCode: lintCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );

  /// Reports a diagnostic at [token], with message [arguments] and
  /// [contextMessages].
  void reportAtToken(
    Token token, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtToken(
    token,
    diagnosticCode: lintCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );
}

/// Provides access to information needed by analysis rules that is not
/// available from AST nodes or the element model.
abstract class LinterContext {
  /// The list of all compilation units that make up the library under analysis,
  /// including the defining compilation unit, all parts, and all augmentations.
  List<LintRuleUnitContext> get allUnits;

  /// The compilation unit being linted.
  ///
  /// `null` when a unit is not currently being linted (for example when node
  /// processors are being registered).
  LintRuleUnitContext? get currentUnit;

  /// The defining compilation unit of the library under analysis.
  LintRuleUnitContext get definingUnit;

  /// Whether the [definingUnit]'s location is in a package's top-level 'lib'
  /// directory, including locations deeply nested, and locations in the
  /// package-implementation directory, 'lib/src'.
  bool get isInLibDir;

  /// Whether the [definingUnit] is in a [package]'s "test" directory.
  bool get isInTestDirectory;

  /// The library element representing the library that contains the compilation
  /// unit being linted.
  @experimental
  LibraryElement? get libraryElement2;

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
  LintRuleUnitContext? currentUnit;

  LinterContextWithParsedResults(this.allUnits, this.definingUnit);

  @override
  bool get isInLibDir => LinterContext._isInLibDir(
    definingUnit.unit.declaredFragment?.source.fullName,
    package,
  );

  @override
  bool get isInTestDirectory => false;

  @experimental
  @override
  LibraryElement get libraryElement2 =>
      throw UnsupportedError(
        'LinterContext with parsed results does not include a LibraryElement',
      );

  @override
  WorkspacePackage? get package => null;

  @override
  TypeProvider get typeProvider =>
      throw UnsupportedError(
        'LinterContext with parsed results does not include a TypeProvider',
      );

  @override
  TypeSystem get typeSystem =>
      throw UnsupportedError(
        'LinterContext with parsed results does not include a TypeSystem',
      );
}

/// A [LinterContext] for a library, resolved into [ResolvedUnitResult]s.
final class LinterContextWithResolvedResults implements LinterContext {
  @override
  final List<LintRuleUnitContext> allUnits;

  @override
  final LintRuleUnitContext definingUnit;

  @override
  LintRuleUnitContext? currentUnit;

  @override
  final WorkspacePackage? package;

  @override
  final TypeProvider typeProvider;

  @override
  final TypeSystem typeSystem;

  LinterContextWithResolvedResults(
    this.allUnits,
    this.definingUnit,
    this.typeProvider,
    this.typeSystem,
    this.package,
  );

  @override
  bool get isInLibDir => LinterContext._isInLibDir(
    definingUnit.unit.declaredFragment?.source.fullName,
    package,
  );

  @override
  bool get isInTestDirectory {
    if (package case var package?) {
      var file = definingUnit._file;
      return package.isInTestDirectory(file);
    }
    return false;
  }

  @experimental
  @override
  LibraryElement get libraryElement2 =>
      definingUnit.unit.declaredFragment!.element;
}

/// Provides access to information needed by lint rules that is not available
/// from AST nodes or the element model.
class LintRuleUnitContext {
  final File _file;
  final String content;
  final ErrorReporter errorReporter;
  final CompilationUnit unit;

  LintRuleUnitContext({
    required File file,
    required this.content,
    required this.errorReporter,
    required this.unit,
  }) : _file = file;
}

/// Describes an [AbstractAnalysisRule] which reports diagnostics using multiple
/// [DiagnosticCode]s).
abstract class MultiAnalysisRule extends AbstractAnalysisRule {
  MultiAnalysisRule({
    required super.name,
    required super.description,
    super.state,
  });

  /// Reports [errorCode] at [node] with message [arguments] and
  /// [contextMessages].
  void reportAtNode(
    AstNode? node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
    required DiagnosticCode errorCode,
  }) => _reportAtNode(
    node,
    diagnosticCode: errorCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );

  /// Reports [errorCode] at [offset], with [length], with message [arguments]
  /// and [contextMessages].
  void reportAtOffset(
    int offset,
    int length, {
    required DiagnosticCode errorCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtOffset(
    offset,
    length,
    diagnosticCode: errorCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );

  /// Reports [errorCode] at Pubspec [node], with message [arguments] and
  /// [contextMessages].
  void reportAtPubNode(
    PSNode node, {
    required DiagnosticCode errorCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage> contextMessages = const [],
  }) {
    // Cache error and location info for creating `AnalysisErrorInfo`s.
    var error = Diagnostic.tmp(
      source: node.source,
      offset: node.span.start.offset,
      length: node.span.length,
      errorCode: errorCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
    reporter.reportError(error);
  }

  /// Reports [errorCode] at [token], with message [arguments] and
  /// [contextMessages].
  void reportAtToken(
    Token token, {
    required DiagnosticCode errorCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtToken(
    token,
    diagnosticCode: errorCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );
}
