// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A wrapper on top of the [IncrementalKernelGenerator] that tracks
/// file modifications between subsequent compilation requests and only
/// invalidates those files that appear to be modified.
library front_end.example.incremental_reload.compiler_with_invalidation;

import 'dart:io';
import 'dart:async';
import 'dart:convert' show JSON;

import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/src/incremental/file_byte_store.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/limited_ast_to_binary.dart';

/// Create an instance of an [IncrementalCompiler] to compile a program whose
/// main entry point file is [entry]. This uses some default options
/// for the location of the sdk and temporary folder to save intermediate
/// results.
// TODO(sigmund): make this example work outside of the SDK repo.
Future<IncrementalCompiler> createIncrementalCompiler(String entry,
    {bool persistent: true}) {
  var entryUri = Uri.base.resolve(entry);
  var dartVm = Uri.base.resolve(Platform.resolvedExecutable);
  var sdkRoot = dartVm.resolve("patched_sdk/");
  var tmpDir = Directory.systemTemp.createTempSync('ikg_cache');
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..packagesFileUri = Uri.base.resolve('.packages')
    ..strongMode = false
    ..dartLibraries = loadDartLibraries(sdkRoot)
    ..byteStore =
        persistent ? new FileByteStore(tmpDir.path) : new MemoryByteStore();
  return IncrementalCompiler.create(options, entryUri);
}

/// Reads the `libraries.json` file for an SDK to provide the location of the
/// SDK files.
// TODO(sigmund): this should be handled by package:front_end internally.
Map<String, Uri> loadDartLibraries(Uri sdkRoot) {
  var libraries = sdkRoot.resolve('lib/libraries.json');
  var map =
      JSON.decode(new File.fromUri(libraries).readAsStringSync())['libraries'];
  var dartLibraries = <String, Uri>{};
  map.forEach((k, v) => dartLibraries[k] = libraries.resolve(v));
  return dartLibraries;
}

/// An incremental compiler that monitors file modifications on disk and
/// invalidates only files that have been modified since the previous time the
/// compiler was invoked.
class IncrementalCompiler {
  /// Underlying incremental compiler implementation.
  IncrementalKernelGenerator _generator;

  /// Last modification for each tracked input file.
  Map<Uri, DateTime> lastModified = {};

  /// Create an instance of [IncrementalCompiler].
  static Future<IncrementalCompiler> create(
      CompilerOptions options, Uri entryUri) async {
    return new IncrementalCompiler._internal(
        await IncrementalKernelGenerator.newInstance(options, entryUri));
  }

  IncrementalCompiler._internal(this._generator);

  /// Callback for the [IncrementalKernelGenerator] to keep track of relevant
  /// files.
  Future _watch(Uri uri, bool used) {
    if (used) {
      lastModified[uri] ??= new File.fromUri(uri).lastModifiedSync();
    } else {
      lastModified.remove(uri);
    }
    return new Future.value(null);
  }

  /// How many files changed during the last call to [recompile].
  int changed;

  /// Time spent updating time-stamps from disk during the last call to
  /// [recompile].
  int invalidateTime;

  /// Time actually spent compiling the code in the incremental compiler during
  /// the last call to [recompile].
  int compileTime;

  /// Determine which files have been modified, and recompile the program
  /// incrementally based on that information.
  Future<Program> recompile() async {
    changed = 0;
    invalidateTime = 0;
    compileTime = 0;

    var invalidateTimer = new Stopwatch()..start();
    for (var uri in lastModified.keys.toList()) {
      var last = lastModified[uri];
      var current = new File.fromUri(uri).lastModifiedSync();
      if (last != current) {
        lastModified[uri] = current;
        _generator.invalidate(uri);
        changed++;
      }
    }
    invalidateTimer.stop();
    invalidateTime = invalidateTimer.elapsedMilliseconds;
    if (changed == 0 && lastModified.isNotEmpty) return null;

    var compileTimer = new Stopwatch()..start();
    var delta = await _generator.computeDelta(watch: _watch);
    compileTimer.stop();
    compileTime = compileTimer.elapsedMilliseconds;
    var program = delta.newProgram;
    return program;
  }
}

/// The result of an incremental compile and metrics collected during the
/// the compilation.
class CompilationResult {
  /// How many files were modified by the time we invoked the compiler again.
  int changed = 0;

  /// How many files are currently being tracked for modifications.
  int totalFiles = 0;

  /// How long it took to invalidate files that have been modified.
  int invalidateTime = 0;

  /// How long it took to build the incremental program.
  int compileTime = 0;

  /// How long it took to do the hot-reload in the VM.
  int reloadTime = 0;

  /// Whether we saw errors during compilation or reload.
  bool errorSeen = false;

  /// Error message when [errorSeen] is true.
  String errorDetails;

  /// The program that was generated by the incremental compiler.
  Program program;
}

/// Request a recompile and possibly a reload, and gather timing metrics.
Future<CompilationResult> rebuild(
    IncrementalCompiler compiler, Uri outputUri) async {
  var result = new CompilationResult();
  try {
    var program = result.program = await compiler.recompile();
    if (program != null && !program.libraries.isEmpty) {
      var sink = new File.fromUri(outputUri).openWrite();
      // TODO(sigmund): should the incremental generator always filter these
      // libraries instead?
      new LimitedBinaryPrinter(
              sink, (library) => library.importUri.scheme != 'dart')
          .writeProgramFile(program);
      await sink.close();
    }
  } catch (e, t) {
    result.errorDetails = 'compilation error: $e, $t';
    result.errorSeen = true;
  }

  result.changed = compiler.changed;
  result.totalFiles = compiler.lastModified.length;
  result.invalidateTime = compiler.invalidateTime;
  result.compileTime = compiler.compileTime;
  result.reloadTime = 0;
  return result;
}
