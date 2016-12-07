// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator;

import 'compilation_error.dart';
import 'compiler_options.dart';
import 'dart:async';

// TODO(sigmund): move loader logic under front_end/lib/src/kernel/
import 'package:kernel/analyzer/loader.dart';
import 'package:kernel/kernel.dart';
import 'package:source_span/source_span.dart' show SourceSpan;

/// Generates a kernel representation of the program whose main library is in
/// the given [source].
///
/// Intended for whole program (non-modular) compilation.
///
/// Given the Uri of a file containing a program's `main` method, this function
/// follows `import`, `export`, and `part` declarations to discover the whole
/// program, and converts the result to Dart Kernel format.
///
/// If summaries are provided in [options], they may be used to speed up
/// analysis, but they will not take the place of Dart source code (since the
/// Dart source code is still needed to access the contents of method bodies).
///
/// TODO(paulberry): will the VM have a pickled version of the SDK inside it? If
/// so, then maybe this method should not convert SDK libraries to kernel.
Future<Program> kernelForProgram(Uri source, CompilerOptions options) async {
  var loader = await _createLoader(options);
  Program program = loader.loadProgram(source);
  _reportErrors(loader.errors, options.onError);
  return program;
}

/// Generates a kernel representation of the build unit whose source files are
/// in [sources].
///
/// Intended for modular compilation.
///
/// [sources] should be the complete set of source files for a build unit
/// (including both library and part files).  All of the library files are
/// transformed into Dart Kernel Library objects.
///
/// The compilation process is hermetic, meaning that the only files which will
/// be read are those listed in [sources], [CompilerOptions.inputSummaries], and
/// [CompilerOptions.sdkSummary].  If a source file attempts to refer to a file
/// which is not obtainable from these paths, that will result in an error, even
/// if the file exists on the filesystem.
///
/// Any `part` declarations found in [sources] must refer to part files which
/// are also listed in [sources], otherwise an error results.  (It is not
/// permitted to refer to a part file declared in another build unit).
///
/// The return value is a [Program] object with no main method set.
/// TODO(paulberry): would it be better to define a data type in kernel to
/// represent a bundle of all the libraries in a given build unit?
///
/// TODO(paulberry): does additional information need to be output to allow the
/// caller to match up referenced elements to the summary files they were
/// obtained from?
Future<Program> kernelForBuildUnit(
        List<Uri> sources, CompilerOptions options) async {
  var repository = new Repository();
  var loader = await _createLoader(options, repository: repository);
  // TODO(sigmund): add special handling for part files.
  sources.forEach(loader.loadLibrary);
  Program program = new Program(repository.libraries);
  _reportErrors(loader.errors, options.onError);
  return program;
}

Future<DartLoader> _createLoader(CompilerOptions options,
    {Repository repository}) async {
  var kernelOptions = _convertOptions(options);
  var packages = await createPackages(options.packagesFilePath);
  return new DartLoader(
      repository ?? new Repository(), kernelOptions, packages);
}

DartOptions _convertOptions(CompilerOptions options) {
  return new DartOptions(
      sdk: options.sdkPath,
      packagePath: options.packagesFilePath,
      declaredVariables: options.declaredVariables);
}

void _reportErrors(List errors, ErrorHandler onError) {
  if (onError == null) return;
  for (var error in errors) {
    onError(new _DartkError(error));
  }
}

// TODO(sigmund): delete this class. Dartk should not format errors itself, we
// should just pass them along.
class _DartkError implements CompilationError {
  String get correction => null;
  SourceSpan get span => null;
  final String message;
  _DartkError(this.message);
}
