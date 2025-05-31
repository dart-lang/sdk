// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/lint/linter_visitor.dart' show RuleVisitorRegistry;
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/workspace/workspace.dart';

export 'package:analyzer/analysis_rule/rule_state.dart'
    show dart2_12, dart3, dart3_3, RuleState;
export 'package:analyzer/src/lint/linter_visitor.dart' show NodeLintRegistry;

/// Returns whether [filePath] is in the top-level `lib` directory in [package].
bool _isInLibDir(String? filePath, WorkspacePackage? package) {
  if (package == null) return false;
  if (filePath == null) return false;
  var libDir = package.root.getChildAssumingFolder('lib');
  return libDir.contains(filePath);
}

/// A soon-to-be deprecated alias for [RuleContext].
typedef LinterContext = RuleContext;

/// Describes an [AbstractAnalysisRule] which reports diagnostics using exactly
/// one [DiagnosticCode].
typedef LintRule = AnalysisRule;

/// Describes a static analysis rule, either a lint rule (which must be enabled
/// via analysis options) or a warning rule (which is enabled by default).
sealed class AbstractAnalysisRule {
  /// Used to report lints and warnings.
  /// NOTE: this is set by the framework before any node processors start
  /// visiting nodes.
  late ErrorReporter _reporter;

  /// Short description suitable for display in console output.
  final String description;

  /// The rule name.
  final String name;

  /// The state of this analysis rule, optionally indicating the "version" that
  /// this state started applying to this rule.
  final RuleState state;

  AbstractAnalysisRule({
    required this.name,
    required this.description,
    this.state = const RuleState.stable(),
  });

  /// Indicates whether this analysis rule can work with just the parsed
  /// information or if it requires a resolved unit.
  bool get canUseParsedResult => false;

  /// The diagnostic codes associated with this analysis rule.
  List<DiagnosticCode> get diagnosticCodes;

  /// A list of incompatible rule ids.
  List<String> get incompatibleRules => const [];

  /// A visitor that visits a [Pubspec] to perform analysis.
  ///
  /// Diagnostics are reported via this [AbstractAnalysisRule]'s error
  /// [reporter].
  PubspecVisitor? get pubspecVisitor => null;

  /// Sets the [ErrorReporter] for the [CompilationUnit] currently being
  /// visited.
  set reporter(ErrorReporter value) => _reporter = value;

  /// Registers node processors in the given [registry].
  ///
  /// The node processors may use the provided [context] to access information
  /// that is not available from the AST nodes or their associated elements.
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {}

  void _reportAtNode(
    AstNode? node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
    required DiagnosticCode diagnosticCode,
  }) {
    if (node != null && !node.isSynthetic) {
      _reporter.atNode(
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
    _reporter.atOffset(
      offset: offset,
      length: length,
      diagnosticCode: diagnosticCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
  }

  void _reportAtPubNode(
    PSNode node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage> contextMessages = const [],
    required DiagnosticCode diagnosticCode,
  }) {
    // Cache diagnostic and location info for creating `AnalysisErrorInfo`s.
    var diagnostic = Diagnostic.tmp(
      source: node.source,
      offset: node.span.start.offset,
      length: node.span.length,
      errorCode: diagnosticCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
    _reporter.reportError(diagnostic);
  }

  void _reportAtToken(
    Token token, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) {
    if (!token.isSynthetic) {
      _reporter.atToken(
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

  /// The code to report for a violation.
  DiagnosticCode get diagnosticCode;

  @override
  List<DiagnosticCode> get diagnosticCodes => [diagnosticCode];

  /// Reports a diagnostic at [node] with message [arguments] and
  /// [contextMessages].
  void reportAtNode(
    AstNode? node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtNode(
    node,
    diagnosticCode: diagnosticCode,
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
    diagnosticCode: diagnosticCode,
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
    diagnosticCode: diagnosticCode,
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
    diagnosticCode: diagnosticCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );
}

/// Describes an [AbstractAnalysisRule] which reports diagnostics using multiple
/// [DiagnosticCode]s).
abstract class MultiAnalysisRule extends AbstractAnalysisRule {
  MultiAnalysisRule({
    required super.name,
    required super.description,
    super.state,
  });

  /// Reports [diagnosticCode] at [node] with message [arguments] and
  /// [contextMessages].
  void reportAtNode(
    AstNode? node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
    required DiagnosticCode diagnosticCode,
  }) => _reportAtNode(
    node,
    diagnosticCode: diagnosticCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );

  /// Reports [diagnosticCode] at [offset], with [length], with message [arguments]
  /// and [contextMessages].
  void reportAtOffset(
    int offset,
    int length, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtOffset(
    offset,
    length,
    diagnosticCode: diagnosticCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );

  /// Reports [diagnosticCode] at Pubspec [node], with message [arguments] and
  /// [contextMessages].
  void reportAtPubNode(
    PSNode node, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage> contextMessages = const [],
  }) {
    // Cache error and location info for creating `AnalysisErrorInfo`s.
    var error = Diagnostic.tmp(
      source: node.source,
      offset: node.span.start.offset,
      length: node.span.length,
      errorCode: diagnosticCode,
      arguments: arguments,
      contextMessages: contextMessages,
    );
    _reporter.reportError(error);
  }

  /// Reports [diagnosticCode] at [token], with message [arguments] and
  /// [contextMessages].
  void reportAtToken(
    Token token, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) => _reportAtToken(
    token,
    diagnosticCode: diagnosticCode,
    arguments: arguments,
    contextMessages: contextMessages,
  );
}

/// A [RuleContext] for a library, parsed into [ParsedUnitResult]s.
///
/// This is available for analysis rules that can operate on parsed,
/// unresolved syntax trees.
final class RuleContextWithParsedResults implements RuleContext {
  @override
  final List<RuleContextUnit> allUnits;

  @override
  final RuleContextUnit definingUnit;

  @override
  RuleContextUnit? currentUnit;

  RuleContextWithParsedResults(this.allUnits, this.definingUnit);

  @override
  bool get isInLibDir =>
      _isInLibDir(definingUnit.unit.declaredFragment?.source.fullName, package);

  @override
  bool get isInTestDirectory => false;

  @override
  LibraryElement get libraryElement =>
      throw UnsupportedError(
        'RuleContext with parsed results does not include a LibraryElement',
      );

  @override
  WorkspacePackage? get package => null;

  @override
  TypeProvider get typeProvider =>
      throw UnsupportedError(
        'RuleContext with parsed results does not include a TypeProvider',
      );

  @override
  TypeSystem get typeSystem =>
      throw UnsupportedError(
        'RuleContext with parsed results does not include a TypeSystem',
      );

  @override
  bool isFeatureEnabled(Feature feature) =>
      throw UnsupportedError(
        'RuleContext with parsed results does not include a LibraryElement',
      );
}

/// A [RuleContext] for a library, resolved into [ResolvedUnitResult]s.
final class RuleContextWithResolvedResults implements RuleContext {
  @override
  final List<RuleContextUnit> allUnits;

  @override
  final RuleContextUnit definingUnit;

  @override
  RuleContextUnit? currentUnit;

  @override
  final WorkspacePackage? package;

  @override
  final TypeProvider typeProvider;

  @override
  final TypeSystem typeSystem;

  RuleContextWithResolvedResults(
    this.allUnits,
    this.definingUnit,
    this.typeProvider,
    this.typeSystem,
    this.package,
  );

  @override
  bool get isInLibDir =>
      _isInLibDir(definingUnit.unit.declaredFragment?.source.fullName, package);

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
      definingUnit.unit.declaredFragment!.element;

  @override
  bool isFeatureEnabled(Feature feature) =>
      libraryElement.featureSet.isEnabled(feature);
}
