// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator;

import 'compilation_error.dart';
import 'compiler_options.dart';
import 'dart:async';

import 'package:analyzer/src/generated/source.dart' show SourceKind;
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummarySource;
// TODO(sigmund): move loader logic under front_end/lib/src/kernel/
import 'package:analyzer/src/kernel/loader.dart';
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
/// If `compileSdk` in [options] is true, the generated program will include
/// code for the SDK.
///
/// If summaries are provided in [options], they may be used to speed up
/// analysis. If in addition `compileSdk` is false, this will speed up
/// compilation, as no source of the sdk will be generated.  Note however, that
/// summaries for application code can also speed up analysis, but they will not
/// take the place of Dart source code (since the Dart source code is still
/// needed to access the contents of method bodies).
Future<Program> kernelForProgram(Uri source, CompilerOptions options) async {
  var loader = await _createLoader(options, entry: source);

  if (options.compileSdk) {
    options.additionalLibraries.forEach(loader.loadLibrary);
  }

  // TODO(sigmund): merge what we have in loadEverything and the logic below in
  // kernelForBuildUnit so there is a single place where we crawl for
  // dependencies.
  loader.loadProgram(source, compileSdk: options.compileSdk);
  _reportErrors(loader.errors, options.onError);
  return loader.program;
}

/// Generates a kernel representation for a build unit.
///
/// Intended for modular compilation.
///
/// The build unit by default contains only the source files in [sources]
/// (including library and part files), but if
/// [CompilerOptions.chaseDependencies] is true, it may include some additional
/// source files.  All of the library files are transformed into Dart Kernel
/// Library objects.
///
/// By default, the compilation process is hermetic, meaning that the only files
/// which will be read are those listed in [sources],
/// [CompilerOptions.inputSummaries], and [CompilerOptions.sdkSummary].  If a
/// source file attempts to refer to a file which is not obtainable from these
/// URIs, that will result in an error, even if the file exists on the
/// filesystem.
///
/// When [CompilerOptions.chaseDependencies] is true, this default behavior
/// changes, and any dependency of [sources] that is not listed in
/// [CompilerOptions.inputSummaries] and [CompilerOptions.sdkSummary] is treated
/// as an additional source file for the build unit.
///
/// Any `part` declarations found in [sources] must refer to part files which
/// are also listed in the build unit sources, otherwise an error results.  (It
/// is not permitted to refer to a part file declared in another build unit).
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
  var program = new Program();
  var loader = await _createLoader(options, program: program);
  var context = loader.context;

  // Process every library in the build unit.
  for (var uri in sources) {
    var source = context.sourceFactory.forUri2(uri);
    //  We ignore part files, those are handled by their enclosing library.
    if (context.computeKindOf(source) == SourceKind.PART) {
      // TODO(sigmund): record it and ensure that this part is within a provided
      // library.
      continue;
    }
    loader.loadLibrary(uri);
  }

  // Check whether all dependencies were included in [sources].
  // TODO(sigmund): we should look for dependencies using import, export, and
  // part directives intead of relying on the dartk-loader.  In particular, if a
  // library is imported but not used, the logic below will not detect it.
  for (int i = 0; i < program.libraries.length; ++i) {
    // Note: we don't use a for-in loop because program.libraries grows as
    // the loader processes libraries.
    var lib = program.libraries[i];
    var source = context.sourceFactory.forUri2(lib.importUri);
    if (source is InSummarySource) continue;
    if (options.chaseDependencies) {
      loader.ensureLibraryIsLoaded(lib);
    } else if (lib.isExternal) {
      // Default behavior: the build should be hermetic and all dependencies
      // should be listed.
      options.onError(new _DartkError('hermetic build error: '
          'no source or summary was given for ${lib.importUri}'));
    }
  }

  _reportErrors(loader.errors, options.onError);
  return program;
}

/// Create a [DartLoader] using the provided [options].
///
/// If [options] contain no configuration to resolve `.packages`, the [entry]
/// file will be used to search for a `.packages` file.
Future<DartLoader> _createLoader(CompilerOptions options,
    {Program program, Uri entry}) async {
  var kernelOptions = _convertOptions(options);
  var packages = await createPackages(
      _uriToPath(options.packagesFileUri, options),
      discoveryPath: entry?.path);
  var loader =
      new DartLoader(program ?? new Program(), kernelOptions, packages);
  var patchPaths = <String, List<String>>{};

  // TODO(sigmund,paulberry): use ProcessedOptions so that we can resolve the
  // URIs correctly even if sdkRoot is inferred and not specified explicitly.
  String resolve(Uri patch) =>
      options.fileSystem.context.fromUri(options.sdkRoot.resolveUri(patch));

  options.targetPatches.forEach((uri, patches) {
    patchPaths['$uri'] = patches.map(resolve).toList();
  });
  AnalysisOptionsImpl analysisOptions = loader.context.analysisOptions;
  analysisOptions.patchPaths = patchPaths;
  return loader;
}

DartOptions _convertOptions(CompilerOptions options) {
  return new DartOptions(
      strongMode: options.strongMode,
      sdk: _uriToPath(options.sdkRoot, options),
      // TODO(sigmund): make it possible to use summaries and still compile the
      // sdk sources.
      sdkSummary:
          options.compileSdk ? null : _uriToPath(options.sdkSummary, options),
      packagePath: _uriToPath(options.packagesFileUri, options),
      customUriMappings: options.uriOverride,
      declaredVariables: options.declaredVariables);
}

void _reportErrors(List errors, ErrorHandler onError) {
  if (onError == null) return;
  for (var error in errors) {
    onError(new _DartkError(error));
  }
}

String _uriToPath(Uri uri, CompilerOptions options) {
  if (uri == null) return null;
  if (uri.scheme != 'file') {
    throw new StateError('Only file URIs are supported: $uri');
  }
  return options.fileSystem.context.fromUri(uri);
}

// TODO(sigmund): delete this class. Dartk should not format errors itself, we
// should just pass them along.
class _DartkError implements CompilationError {
  String get correction => null;
  SourceSpan get span => null;
  final String message;
  _DartkError(this.message);
}
