// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compiler_context;

import 'dart:async' show Zone, runZoned;

import 'package:kernel/ast.dart' show Source;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import 'scanner/token.dart' show StringToken;

import 'command_line_reporting.dart' as command_line_reporting;

import 'colors.dart' show computeEnableColors;

import 'fasta_codes.dart'
    show LocatedMessage, Message, messageInternalProblemMissingContext;

import 'severity.dart' show Severity;

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

  final List errors = <Object>[];

  FileSystem get fileSystem => options.fileSystem;

  bool enableColorsCached = null;

  CompilerContext(this.options);

  void disableColors() {
    enableColorsCached = false;
  }

  /// Report [message], for example, by printing it.
  void report(LocatedMessage message, Severity severity) {
    options.report(message, severity);
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

  void logError(Object message, Severity severity) {
    errors.add(message);
    errors.add(severity);
  }

  static CompilerContext get current {
    var context = Zone.current[compilerContextKey];
    if (context == null) {
      // Note: we throw directly and don't use internalProblem, because
      // internalProblem depends on having a compiler context available.
      var message = messageInternalProblemMissingContext.message;
      var tip = messageInternalProblemMissingContext.tip;
      throw "Internal problem: $message\nTip: $tip";
    }
    return context;
  }

  /// Perform [action] in a [Zone] where [this] will be available as
  /// `CompilerContext.current`.
  T runInContext<T>(T action(CompilerContext c)) {
    try {
      return runZoned(() => action(this),
          zoneValues: {compilerContextKey: this});
    } finally {
      clear();
    }
  }

  /// Perform [action] in a [Zone] where [options] will be available as
  /// `CompilerContext.current.options`.
  static T runWithOptions<T>(
      ProcessedOptions options, T action(CompilerContext c)) {
    return new CompilerContext(options).runInContext(action);
  }

  static T runWithDefaultOptions<T>(T action(CompilerContext c)) {
    var options = new ProcessedOptions(new CompilerOptions());
    return new CompilerContext(options).runInContext(action);
  }

  static bool get enableColors {
    return current.enableColorsCached ??= computeEnableColors(current);
  }

  static void clear() {
    StringToken.canonicalizer.clear();
  }
}
