// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator;

import 'dart:async' show Future;
import 'dart:async';

import 'package:kernel/kernel.dart' show Program;

import 'compiler_options.dart';
import 'src/base/processed_options.dart';
import 'src/fasta/fasta_codes.dart';
import 'src/fasta/compiler_context.dart';
import 'src/fasta/severity.dart';
import 'src/kernel_generator_impl.dart';

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
/// If summaries are provided in [options], the compiler will use them instead
/// of compiling the libraries contained in those summaries. This is useful, for
/// example, when compiling for platforms that already embed those sources (like
/// the sdk in the standalone VM).
///
/// The input [source] is expected to be a script with a main method, otherwise
/// an error is reported.
// TODO(sigmund): rename to kernelForScript?
Future<Program> kernelForProgram(Uri source, CompilerOptions options) async {
  var pOptions = new ProcessedOptions(options, false, [source]);
  return await CompilerContext.runWithOptions(pOptions, (context) async {
    var program = (await generateKernelInternal())?.program;
    if (program == null) return null;

    if (program.mainMethod == null) {
      context.options
          .report(messageMissingMain.withLocation(source, -1), Severity.error);
      return null;
    }
    return program;
  });
}

/// Generates a kernel representation for a build unit containing [sources].
///
/// A build unit is a collection of libraries that are compiled together.
/// Libraries in the build unit may depend on each other and may have
/// dependencies to libraries in other build units. Unlinke library
/// dependencies, build unit dependencies must be acyclic.
///
/// This API is intended for modular compilation. Dependencies to other build
/// units are specified using [CompilerOptions.inputSummaries].
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
/// The return value is a [Program] object with no main method set. The
/// [Program] includes external libraries for those libraries loaded through
/// summaries.
Future<Program> kernelForBuildUnit(
    List<Uri> sources, CompilerOptions options) async {
  return (await generateKernel(new ProcessedOptions(options, true, sources)))
      ?.program;
}
