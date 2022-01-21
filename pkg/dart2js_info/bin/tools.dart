// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';

import 'src/code_deps.dart';
import 'src/common_command.dart';
import 'src/coverage_log_server.dart';
import 'src/debug_info.dart';
import 'src/diff.dart';
import 'src/deferred_library_check.dart';
import 'src/deferred_library_size.dart';
import 'src/deferred_library_layout.dart';
import 'src/convert.dart';
import 'src/function_size_analysis.dart';
import 'src/library_size_split.dart';
import 'src/live_code_size_analysis.dart';
import 'src/runtime_coverage_analysis.dart';
import 'src/show_inferred_types.dart';
import 'src/text_print.dart';

/// Entrypoint to run all dart2js_info tools.
void main(args) {
  var commandRunner = CommandRunner("dart2js_info",
      "collection of tools to digest the output of dart2js's --dump-info")
    ..addCommand(CodeDepsCommand())
    ..addCommand(CommonCommand())
    ..addCommand(CoverageLogServerCommand())
    ..addCommand(DebugCommand())
    ..addCommand(DiffCommand())
    ..addCommand(DeferredLibraryCheck())
    ..addCommand(DeferredLibrarySize())
    ..addCommand(DeferredLibraryLayout())
    ..addCommand(ConvertCommand())
    ..addCommand(FunctionSizeCommand())
    ..addCommand(LibrarySizeCommand())
    ..addCommand(LiveCodeAnalysisCommand())
    ..addCommand(RuntimeCoverageAnalysisCommand())
    ..addCommand(ShowInferredTypesCommand())
    ..addCommand(ShowCommand());
  commandRunner.run(args);
}
