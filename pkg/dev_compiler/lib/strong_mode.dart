// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Types needed to implement "strong" checking in the Dart analyzer.
/// This is intended to be used by analyzer_cli and analysis_server packages.
library dev_compiler.strong_mode;

import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContextImpl, AnalysisErrorInfo, AnalysisErrorInfoImpl;
import 'package:analyzer/src/generated/error.dart'
    show
        AnalysisError,
        ErrorCode,
        CompileTimeErrorCode,
        StaticTypeWarningCode,
        HintCode;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:args/args.dart';
import 'package:logging/logging.dart' show Level;

import 'src/checker/checker.dart' show CodeChecker;
import 'src/checker/resolver.dart' show LibraryResolverWithInference;
import 'src/checker/rules.dart' show RestrictedRules;
import 'src/report.dart' show CheckerReporter, Message;

/// A type checker for Dart code that operates under stronger rules, and has
/// the ability to do local type inference in some situations.
class StrongChecker {
  final AnalysisContextImpl _context;
  final CodeChecker _checker;
  final _ErrorReporter _reporter;
  final StrongModeOptions _options;

  StrongChecker._(this._context, this._options, this._checker, this._reporter);

  factory StrongChecker(
      AnalysisContextImpl context, StrongModeOptions options) {
    // TODO(jmesserly): is there a cleaner way to plug this in?
    if (context.libraryResolverFactory != null) {
      throw new ArgumentError.value(context, 'context',
          'Analysis context must not have libraryResolverFactory already set.');
    }
    context.libraryResolverFactory =
        (c) => new LibraryResolverWithInference(c, options);

    var rules = new RestrictedRules(context.typeProvider, options: options);
    var reporter = new _ErrorReporter();
    var checker = new CodeChecker(rules, reporter, options);
    return new StrongChecker._(context, options, checker, reporter);
  }

  /// Computes and returns DDC errors for the [source].
  AnalysisErrorInfo computeErrors(Source source) {
    var errors = new List<AnalysisError>();

    // TODO(jmesserly): change DDC to emit ErrorCodes directly.
    _reporter._log = (Message msg) {
      // Skip hints unless requested.
      if (msg.level < Level.WARNING && !_options.hints) return;

      var errorCodeFactory = _levelToErrorCode[msg.level];
      var category = '${msg.runtimeType}';
      var errorCode = errorCodeFactory(category, msg.message);
      var len = msg.end - msg.begin;
      errors.add(new AnalysisError(source, msg.begin, len, errorCode));
    };

    for (Source librarySource in _context.getLibrariesContaining(source)) {
      var resolved = _context.resolveCompilationUnit2(source, librarySource);
      _checker.visitCompilationUnit(resolved);
    }
    _reporter._log = null;
    return new AnalysisErrorInfoImpl(errors, _context.getLineInfo(source));
  }
}

/// Maps a DDC log level to an analyzer ErrorCode subclass.
final _levelToErrorCode = <Level, _ErrorCodeFactory>{
  Level.SEVERE: (n, m) => new CompileTimeErrorCode(n, m),
  Level.WARNING: (n, m) => new StaticTypeWarningCode(n, m),
  Level.INFO: (n, m) => new HintCode(n, m)
};

class _ErrorReporter implements CheckerReporter {
  _CheckerReporterLog _log;
  void log(Message message) => _log(message);
}

class StrongModeOptions {

  /// Whether to infer return types and field types from overridden members.
  final bool inferFromOverrides;
  static const inferFromOverridesDefault = true;

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

  /// A list of non-nullable type names (e.g., 'int')
  final List<String> nonnullableTypes;
  static const List<String> NONNULLABLE_TYPES = const <String>[];

  /// Whether to include hints about dynamic invokes and runtime checks.
  // TODO(jmesserly): this option is not used yet by DDC server mode or batch
  // compile to JS.
  final bool hints;

  const StrongModeOptions({this.hints: false,
      this.inferFromOverrides: inferFromOverridesDefault,
      this.inferTransitively: inferTransitivelyDefault,
      this.onlyInferConstsAndFinalFields: onlyInferConstAndFinalFieldsDefault,
      this.inferDownwards: inferDownwardsDefault, this.relaxedCasts: true,
      this.nonnullableTypes: StrongModeOptions.NONNULLABLE_TYPES});

  StrongModeOptions.fromArguments(ArgResults args, {String prefix: ''})
      : relaxedCasts = args[prefix + 'relaxed-casts'],
        inferDownwards = args[prefix + 'infer-downwards'],
        inferFromOverrides = args[prefix + 'infer-from-overrides'],
        inferTransitively = args[prefix + 'infer-transitively'],
        onlyInferConstsAndFinalFields = args[prefix + 'infer-only-finals'],
        nonnullableTypes = _optionsToList(args[prefix + 'nonnullable'],
            defaultValue: StrongModeOptions.NONNULLABLE_TYPES),
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
      ..addFlag(prefix + 'infer-from-overrides',
          help: 'Infer unspecified types of fields and return types from\n'
          'definitions in supertypes',
          defaultsTo: inferFromOverridesDefault,
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
    return inferFromOverrides == s.inferFromOverrides &&
        inferTransitively == s.inferTransitively &&
        onlyInferConstsAndFinalFields == s.onlyInferConstsAndFinalFields &&
        inferDownwards == s.inferDownwards &&
        relaxedCasts == s.relaxedCasts &&
        nonnullableTypes.length == s.nonnullableTypes.length &&
        new Set.from(nonnullableTypes).containsAll(s.nonnullableTypes);
  }
}

typedef void _CheckerReporterLog(Message message);
typedef ErrorCode _ErrorCodeFactory(String name, String message);

List<String> _optionsToList(String option,
    {List<String> defaultValue: const <String>[]}) {
  if (option == null) {
    return defaultValue;
  } else if (option.isEmpty) {
    return <String>[];
  } else {
    return option.split(',');
  }
}
