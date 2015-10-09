// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Types needed to implement "strong" checking in the Dart analyzer. This is
/// intended to be used by `analyzer_cli` and `analysis_server` packages.
library dev_compiler.strong_mode;

import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisContext,
        AnalysisContextImpl,
        AnalysisEngine,
        AnalysisErrorInfo,
        AnalysisErrorInfoImpl;
import 'package:analyzer/src/generated/error.dart'
    show
        AnalysisError,
        AnalysisErrorListener,
        CompileTimeErrorCode,
        ErrorCode,
        ErrorSeverity,
        HintCode,
        StaticTypeWarningCode;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:args/args.dart';

import 'src/analysis_context.dart' show enableDevCompilerInference;
import 'src/checker/checker.dart' show CodeChecker;
import 'src/checker/rules.dart' show RestrictedRules;

/// A type checker for Dart code that operates under stronger rules, and has
/// the ability to do local type inference in some situations.
class StrongChecker {
  final AnalysisContext _context;
  final CodeChecker _checker;
  final _ErrorCollector _reporter;

  StrongChecker._(this._context, this._checker, this._reporter);

  factory StrongChecker(AnalysisContext context, StrongModeOptions options) {
    // TODO(vsm): Remove this once analyzer_cli is completely switched to the
    // task model.
    if (!AnalysisEngine
        .instance.useTaskModel) enableDevCompilerInference(context, options);
    var rules = new RestrictedRules(context.typeProvider, options: options);
    var reporter = new _ErrorCollector(options.hints);
    var checker = new CodeChecker(rules, reporter);
    return new StrongChecker._(context, checker, reporter);
  }

  /// Computes and returns DDC errors for the [source].
  AnalysisErrorInfo computeErrors(Source source) {
    var errors = new List<AnalysisError>();
    _reporter.errors = errors;

    for (Source librarySource in _context.getLibrariesContaining(source)) {
      var resolved = _context.resolveCompilationUnit2(source, librarySource);
      _checker.visitCompilationUnit(resolved);
    }
    _reporter.errors = null;

    return new AnalysisErrorInfoImpl(errors, _context.getLineInfo(source));
  }
}

class _ErrorCollector implements AnalysisErrorListener {
  List<AnalysisError> errors;
  final bool hints;
  _ErrorCollector(this.hints);

  void onError(AnalysisError error) {
    // Unless DDC hints are requested, filter them out.
    var HINT = ErrorSeverity.INFO.ordinal;
    if (hints || error.errorCode.errorSeverity.ordinal > HINT) {
      errors.add(error);
    }
  }
}

class StrongModeOptions {
  /// Whether to infer types for consts and fields by looking at initializers on
  /// the RHS. For example, in a constant declaration like:
  ///
  ///      const A = B;
  ///
  /// We can infer the type of `A` based on the type of `B`.
  ///
  /// The inference algorithm determines what variables depend on others, and
  /// computes types by visiting the variable dependency graph in topological
  /// order. This ensures that the inferred type is deterministic when applying
  /// inference on library cycles.
  ///
  /// When this feature is turned off, we don't use the type of `B` to infer the
  /// type of `A`, even if `B` has a declared type.
  final bool inferTransitively;
  static const inferTransitivelyDefault = true;

  /// Restrict inference of fields and top-levels to those that are final and
  /// const.
  final bool onlyInferConstsAndFinalFields;
  static const onlyInferConstAndFinalFieldsDefault = false;

  /// Whether to infer types downwards from local context
  final bool inferDownwards;
  static const inferDownwardsDefault = true;

  /// Whether to inject casts between Dart assignable types.
  final bool relaxedCasts;

  /// Whether to include hints about dynamic invokes and runtime checks.
  // TODO(jmesserly): this option is not used yet by DDC server mode or batch
  // compile to JS.
  final bool hints;

  const StrongModeOptions(
      {this.hints: false,
      this.inferTransitively: inferTransitivelyDefault,
      this.onlyInferConstsAndFinalFields: onlyInferConstAndFinalFieldsDefault,
      this.inferDownwards: inferDownwardsDefault,
      this.relaxedCasts: true});

  StrongModeOptions.fromArguments(ArgResults args, {String prefix: ''})
      : relaxedCasts = args[prefix + 'relaxed-casts'],
        inferDownwards = args[prefix + 'infer-downwards'],
        inferTransitively = args[prefix + 'infer-transitively'],
        onlyInferConstsAndFinalFields = args[prefix + 'infer-only-finals'],
        hints = args[prefix + 'hints'];

  static ArgParser addArguments(ArgParser parser,
      {String prefix: '', bool hide: false}) {
    return parser
      ..addFlag(prefix + 'hints',
          help: 'Display hints about dynamic casts and dispatch operations',
          defaultsTo: false,
          hide: hide)
      ..addFlag(prefix + 'relaxed-casts',
          help: 'Cast between Dart assignable types',
          defaultsTo: true,
          hide: hide)
      ..addOption(prefix + 'nonnullable',
          abbr: prefix == '' ? 'n' : null,
          help: 'Comma separated string of non-nullable types',
          defaultsTo: null,
          hide: hide)
      ..addFlag(prefix + 'infer-downwards',
          help: 'Infer types downwards from local context',
          defaultsTo: inferDownwardsDefault,
          hide: hide)
      ..addFlag(prefix + 'infer-transitively',
          help: 'Infer consts/fields from definitions in other libraries',
          defaultsTo: inferTransitivelyDefault,
          hide: hide)
      ..addFlag(prefix + 'infer-only-finals',
          help: 'Do not infer non-const or non-final fields',
          defaultsTo: onlyInferConstAndFinalFieldsDefault,
          hide: hide);
  }

  bool operator ==(Object other) {
    if (other is! StrongModeOptions) return false;
    StrongModeOptions s = other;
    return inferTransitively == s.inferTransitively &&
        onlyInferConstsAndFinalFields == s.onlyInferConstsAndFinalFields &&
        inferDownwards == s.inferDownwards &&
        relaxedCasts == s.relaxedCasts;
  }
}
