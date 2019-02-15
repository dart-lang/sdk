// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';

import 'code_deps.dart';
import 'coverage_log_server.dart';
import 'debug_info.dart';
import 'diff.dart';
import 'deferred_library_check.dart';
import 'deferred_library_size.dart';
import 'deferred_library_layout.dart';
import 'convert.dart';
import 'function_size_analysis.dart';
import 'library_size_split.dart';
import 'live_code_size_analysis.dart';
import 'show_inferred_types.dart';

/// Entrypoint to run all dart2js_info tools.
void main(args) {
  var commandRunner = new CommandRunner("dart2js_info",
      "collection of tools to digest the output of dart2js's --dump-info")
    ..addCommand(new CodeDepsCommand())
    ..addCommand(new CoverageLogServerCommand())
    ..addCommand(new DebugCommand())
    ..addCommand(new DiffCommand())
    ..addCommand(new DeferredLibraryCheck())
    ..addCommand(new DeferredLibrarySize())
    ..addCommand(new DeferredLibraryLayout())
    ..addCommand(new ConvertCommand())
    ..addCommand(new FunctionSizeCommand())
    ..addCommand(new LibrarySizeCommand())
    ..addCommand(new LiveCodeAnalysisCommand())
    ..addCommand(new ShowInferredTypesCommand());
  commandRunner.run(args);
}
