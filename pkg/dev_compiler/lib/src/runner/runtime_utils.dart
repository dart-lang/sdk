// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// JS runtime files utilities used by dartdevrun.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';

import '../compiler.dart' show defaultRuntimeFiles;
import '../options.dart';
import 'file_utils.dart';

/// In node.js / io.js, these modules need to be aliased globally
/// (e.g. `var foo = require('./path/to/foo.js')`).
/// TODO(ochafik): Investigate alternative module / alias patterns.
const _ALIASED_RUNTIME_FILES = const {'dart_library.js': 'dart_library',};

/// If [path] is a runtime file with an alias, returns that alias, otherwise
/// returns null.
String getRuntimeFileAlias(CompilerOptions options, File file) =>
    file.absolute.path.startsWith(_getRuntimeDir(options).absolute.path)
        ? _ALIASED_RUNTIME_FILES[basename(file.path)]
        : null;

Directory _getRuntimeDir(CompilerOptions options) => new Directory(
    join(options.codegenOptions.outputDir, 'dev_compiler', 'runtime'));

Future<List<File>> listOutputFiles(CompilerOptions options) async {
  List<File> files =
      await listJsFiles(new Directory(options.codegenOptions.outputDir));

  var runtimePath = _getRuntimeDir(options).absolute.path;
  isRuntimeFile(File file) => file.path.startsWith(runtimePath);

  final maxIndex = defaultRuntimeFiles.length;
  getPriorityIndex(File file) {
    if (!isRuntimeFile(file)) return maxIndex;
    int i = defaultRuntimeFiles.indexOf(basename(file.path));
    return i < 0 ? maxIndex : i;
  }
  return files
    ..sort((File a, File b) {
      int pa = getPriorityIndex(a), pb = getPriorityIndex(b);
      return pa != pb ? (pa - pb) : a.path.compareTo(b.path);
    });
}

/// TODO(ochafik): Split / reuse [AbstractCompiler.getModuleName].
String getMainModuleName(CompilerOptions options) =>
    basename(withoutExtension(options.inputs.single));
