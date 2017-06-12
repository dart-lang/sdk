// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.compiler_context;

import 'dart:async' show Zone, runZoned;

import 'package:front_end/file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:kernel/ast.dart' show Source;

import 'compiler_command_line.dart' show CompilerCommandLine;

import 'colors.dart' show computeEnableColors;

final Object compilerContextKey = new Object();

final CompilerContext rootContext =
    new CompilerContext(CompilerCommandLine.forRootContext());

class CompilerContext {
  final FileSystem fileSystem = PhysicalFileSystem.instance;
  final CompilerCommandLine options;

  final Map<String, Source> uriToSource = <String, Source>{};

  bool enableColorsCached = null;

  CompilerContext(this.options);

  static CompilerContext get current {
    return Zone.current[compilerContextKey] ?? rootContext;
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
