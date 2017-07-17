// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compiler_context;

import 'dart:async' show Zone, runZoned;

import 'package:front_end/file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:kernel/ast.dart' show Source;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'colors.dart' show computeEnableColors;

import 'fasta_codes.dart' show LocatedMessage, Message;

import 'severity.dart' show Severity;

final Object compilerContextKey = new Object();

class CompilerContext {
  final FileSystem fileSystem = PhysicalFileSystem.instance;

  final CompilerCommandLine options;

  final Map<String, Source> uriToSource = <String, Source>{};

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
  void reportWithoutLocation(Message message, Severity severity) {
    options.reportWithoutLocation(message, severity);
  }

  /// Format [message] as a text string that can be included in generated code.
  String format(LocatedMessage message, Severity severity) {
    return options.format(message, severity);
  }

  /// Format [message] as a text string that can be included in generated code.
  String formatWithoutLocation(Message message, Severity severity) {
    return options.formatWithoutLocation(message, severity);
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

  /// Perform [action] in a [Zone] where [cl] will be available as
  /// `CompilerContext.current.options`.
  static dynamic withGlobalOptions(
      CompilerCommandLine cl, dynamic action(CompilerContext c)) {
    CompilerContext c = new CompilerContext(cl);
    return runZoned(() => action(c), zoneValues: {compilerContextKey: c});
  }

  static bool get enableColors {
    return current.enableColorsCached ??= computeEnableColors(current);
  }
}
