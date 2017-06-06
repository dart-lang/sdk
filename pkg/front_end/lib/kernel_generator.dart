// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to Dart Kernel objects.
library front_end.kernel_generator;

import 'compiler_options.dart';
import 'dart:async' show Future;
import 'dart:async';
import 'package:front_end/src/base/processed_options.dart';
import 'src/fasta/dill/dill_target.dart' show DillTarget;
import 'src/fasta/errors.dart' show InputError;
import 'src/fasta/kernel/kernel_target.dart' show KernelTarget;
import 'package:kernel/kernel.dart' show Program;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm_fasta.dart' show VmFastaTarget;
import 'src/fasta/ticker.dart' show Ticker;
import 'src/fasta/translate_uri.dart' show TranslateUri;
import 'src/simple_error.dart';

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
/// If summaries are provided in [options], they will be used to speed up
/// the process. If in addition `compileSdk` is false, then the resulting
/// program will not contain the sdk contents. This is useful when building apps
/// for platforms that already embed the sdk (e.g. the VM), so there is no need
/// to spend time and space rebuilding it.
Future<Program> kernelForProgram(Uri source, CompilerOptions options) async {
  var fs = options.fileSystem;
  report(String msg) {
    options.onError(new SimpleError(msg));
    return null;
  }

  if (!await fs.entityForUri(source).exists()) {
    return report("Entry-point file not found: $source");
  }

  var pOptions = new ProcessedOptions(options);

  if (!await pOptions.validateOptions()) return null;

  try {
    TranslateUri uriTranslator = await pOptions.getUriTranslator();

    var dillTarget = new DillTarget(new Ticker(isVerbose: false), uriTranslator,
        new VmFastaTarget(new TargetFlags(strongMode: options.strongMode)));
    var summary = await pOptions.sdkSummaryProgram;
    if (summary != null) {
      dillTarget.loader.appendLibraries(summary);
    }

    var kernelTarget =
        new KernelTarget(options.fileSystem, dillTarget, uriTranslator);
    kernelTarget.read(source);

    await dillTarget.buildOutlines();
    await kernelTarget.buildOutlines();
    Program program = await kernelTarget.buildProgram(trimDependencies: true);

    if (kernelTarget.errors.isNotEmpty) {
      kernelTarget.errors.forEach(report);
      return null;
    }

    if (program.mainMethod == null) {
      return report("No 'main' method found.");
    }

    if (!options.compileSdk) {
      // TODO(sigmund): ensure that the result is not including
      // sources for the sdk, only external references.
    }
    return program;
  } on InputError catch (e) {
    options.onError(new SimpleError(e.format()));
    return null;
  }
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
  var fs = options.fileSystem;
  report(String msg) {
    options.onError(new SimpleError(msg));
    return null;
  }

  if (!options.chaseDependencies) {
    // TODO(sigmund): add support, most likely we can do so by adding a wrapper
    // on top of filesystem that restricts reads to a set of known files.
    report("hermetic mode (chaseDependencies = false) is not implemented");
    return null;
  }

  for (var source in sources) {
    if (!await fs.entityForUri(source).exists()) {
      return report("Entry-point file not found: $source");
    }
  }

  var pOptions = new ProcessedOptions(options);

  if (!await pOptions.validateOptions()) return null;

  try {
    TranslateUri uriTranslator = await pOptions.getUriTranslator();

    var dillTarget = new DillTarget(new Ticker(isVerbose: false), uriTranslator,
        new VmFastaTarget(new TargetFlags(strongMode: options.strongMode)));
    var summary = await pOptions.sdkSummaryProgram;
    if (summary != null) {
      dillTarget.loader.appendLibraries(summary);
    }

    // TODO(sigmund): this is likely not going to work if done naively: if
    // summaries contain external references we need to ensure they are loaded
    // in a specific order.
    for (var inputSummary in await pOptions.inputSummariesPrograms) {
      dillTarget.loader.appendLibraries(inputSummary);
    }

    await dillTarget.buildOutlines();

    var kernelTarget =
        new KernelTarget(options.fileSystem, dillTarget, uriTranslator);
    sources.forEach(kernelTarget.read);
    await kernelTarget.buildOutlines();

    Program program = await kernelTarget.buildProgram(trimDependencies: true);

    if (kernelTarget.errors.isNotEmpty) {
      kernelTarget.errors.forEach(report);
      return null;
    }

    return program;
  } on InputError catch (e) {
    options.onError(new SimpleError(e.format()));
    return null;
  }
}
