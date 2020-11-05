// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compiler_context;

import 'dart:async' show Zone, runZoned;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show StringToken;

import 'package:kernel/ast.dart' show Source;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import 'command_line_reporting.dart' as command_line_reporting;

import 'fasta_codes.dart'
    show LocatedMessage, Message, messageInternalProblemMissingContext;

final Object compilerContextKey = new Object();

/// Shared context used throughout the compiler.
///
/// The compiler works with a single instance of this class. To avoid
/// passing it around as an argument everywhere, it is stored as a zone-value.
///
/// For convenience the static getter [CompilerContext.current] retrieves the
/// context stored in the current zone.
class CompilerContext {
  // TODO(sigmund): Move here any method in ProcessedOptions that doesn't seem
  // appropriate as an "option", or consider merging ProcessedOptions entirely
  // within this class, and depend only on the raw options here.
  final ProcessedOptions options;

  /// Sources seen by the compiler.
  ///
  /// This is populated as the compiler reads files, and it is used for error
  /// reporting and to generate source location information in the compiled
  /// programs.
  final Map<Uri, Source> uriToSource = <Uri, Source>{};

  // TODO(ahe): Remove this.
  final List<Object> errors = <Object>[];

  final List<Uri> dependencies = <Uri>[];

  FileSystem get fileSystem => options.fileSystem;

  Uri cachedSdkRoot = null;

  bool compilingPlatform = false;

  CompilerContext(this.options) {
    if (options.verbose) {
      colors.printEnableColorsReason = print;
    }
  }

  /// Report [message], for example, by printing it.
  void report(LocatedMessage message, Severity severity,
      {List<LocatedMessage> context, List<Uri> involvedFiles}) {
    options.report(message, severity,
        context: context, involvedFiles: involvedFiles);
  }

  /// Report [message], for example, by printing it.
  // TODO(askesc): Remove this and direct callers directly to report.
  void reportWithoutLocation(Message message, Severity severity) {
    options.reportWithoutLocation(message, severity);
  }

  /// Format [message] as a text string that can be included in generated code.
  String format(LocatedMessage message, Severity severity) {
    return command_line_reporting.format(message, severity);
  }

  /// Format [message] as a text string that can be included in generated code.
  // TODO(askesc): Remove this and direct callers directly to format.
  String formatWithoutLocation(Message message, Severity severity) {
    return command_line_reporting.format(message.withoutLocation(), severity);
  }

  // TODO(ahe): Remove this.
  void logError(Object message, Severity severity) {
    errors.add(message);
    errors.add(severity);
  }

  static void recordDependency(Uri uri) {
    if (uri.scheme != "file" && uri.scheme != "http") {
      throw new ArgumentError("Expected a file or http URI, but got: '$uri'.");
    }
    CompilerContext context = Zone.current[compilerContextKey];
    if (context != null) {
      context.dependencies.add(uri);
    }
  }

  static CompilerContext get current {
    CompilerContext context = Zone.current[compilerContextKey];
    if (context == null) {
      // Note: we throw directly and don't use internalProblem, because
      // internalProblem depends on having a compiler context available.
      String message = messageInternalProblemMissingContext.message;
      String tip = messageInternalProblemMissingContext.tip;
      throw "Internal problem: $message\nTip: $tip";
    }
    return context;
  }

  static bool get isActive => Zone.current[compilerContextKey] != null;

  /// Perform [action] in a [Zone] where [this] will be available as
  /// `CompilerContext.current`.
  Future<T> runInContext<T>(Future<T> action(CompilerContext c)) {
    return runZoned(
        () => new Future<T>.sync(() => action(this)).whenComplete(clear),
        zoneValues: {compilerContextKey: this});
  }

  /// Perform [action] in a [Zone] where [options] will be available as
  /// `CompilerContext.current.options`.
  static Future<T> runWithOptions<T>(
      ProcessedOptions options, Future<T> action(CompilerContext c),
      {bool errorOnMissingInput: true}) {
    return new CompilerContext(options)
        .runInContext<T>((CompilerContext c) async {
      await options.validateOptions(errorOnMissingInput: errorOnMissingInput);
      return action(c);
    });
  }

  static Future<T> runWithDefaultOptions<T>(
      Future<T> action(CompilerContext c)) {
    return new CompilerContext(new ProcessedOptions()).runInContext<T>(action);
  }

  void clear() {
    StringToken.canonicalizer.clear();
    errors.clear();
    dependencies.clear();
  }
}
