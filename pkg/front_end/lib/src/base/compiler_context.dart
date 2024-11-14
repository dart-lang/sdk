// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Zone, runZoned;

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart'
    show clearStringCanonicalizationCache;
import 'package:_fe_analyzer_shared/src/util/colors.dart' as colors;
import 'package:kernel/ast.dart' show Source;

import '../api_prototype/file_system.dart' show FileSystem;
import '../base/processed_options.dart' show ProcessedOptions;
import 'command_line_reporting.dart' as command_line_reporting;

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

  FileSystem get fileSystem => options.fileSystem;

  Uri? cachedSdkRoot = null;

  bool compilingPlatform = false;

  CompilerContext(this.options) {
    if (options.verbose) {
      colors.printEnableColorsReason = print;
    }
  }

  /// Report [message], for example, by printing it.
  void report(LocatedMessage message, Severity severity,
      {List<LocatedMessage>? context, List<Uri>? involvedFiles}) {
    options.report(this, message, severity,
        context: context, involvedFiles: involvedFiles);
  }

  /// Format [message] as a text string that can be included in generated code.
  PlainAndColorizedString format(LocatedMessage message, Severity severity) {
    return command_line_reporting.format(this, message, severity);
  }

  /// Perform [action] in a [Zone].
  Future<T> runInContext<T>(Future<T> action(CompilerContext c)) {
    return runZoned(
        () => new Future<T>.sync(() => action(this)).whenComplete(clear));
  }

  /// Perform [action] in a [Zone].
  static Future<T> runWithOptions<T>(
      ProcessedOptions options, Future<T> action(CompilerContext c),
      {bool errorOnMissingInput = true}) {
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
    clearStringCanonicalizationCache();
  }
}
