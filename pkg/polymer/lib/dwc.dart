// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point to the compiler. Used to implement `bin/dwc.dart`. */
library dwc;

import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart' show Level;

import 'src/compiler.dart';
import 'src/file_system/console.dart';
import 'src/messages.dart';
import 'src/compiler_options.dart';
import 'src/utils.dart';

void main() {
  run(new Options().arguments).then((result) {
    exit(result.success ? 0 : 1);
  });
}

/** Contains the result of a compiler run. */
class AnalysisResults {

  /** False when errors were found by our polymer analyzer. */
  final bool success;

  /** Error and warning messages collected by the analyzer. */
  final List<String> messages;

  AnalysisResults(this.success, this.messages);
}

/**
 * Runs the polymer analyzer with the command-line options in [args].
 * See [CompilerOptions] for the definition of valid arguments.
 */
// TODO(sigmund): rename to analyze? and rename file as analyzer.dart
Future<AnalysisResults> run(List<String> args, {bool printTime,
    bool shouldPrint: true}) {
  var options = CompilerOptions.parse(args);
  if (options == null) return new Future.value(new AnalysisResults(true, []));
  if (printTime == null) printTime = options.verbose;

  return asyncTime('Total time spent on ${options.inputFile}', () {
    var messages = new Messages(options: options, shouldPrint: shouldPrint);
    var compiler = new Compiler(new ConsoleFileSystem(), options, messages);
    return compiler.run().then((_) {
      var success = messages.messages.every((m) => m.level != Level.SEVERE);
      var msgs = options.jsonFormat
          ? messages.messages.map((m) => m.toJson())
          : messages.messages.map((m) => m.toString());
      return new AnalysisResults(success, msgs.toList());
    });
  }, printTime: printTime, useColors: options.useColors);
}
