// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:front_end/src/api_prototype/physical_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/scanner/token.dart' show StringToken;
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:front_end/src/multi_root_file_system.dart';
import 'package:kernel/kernel.dart' show Program;
import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart';
import 'compiler_state.dart';

export 'compiler_state.dart';

export '../api_prototype/compilation_message.dart';

class DdcResult {
  final Program program;
  final List<Program> inputSummaries;

  DdcResult(this.program, this.inputSummaries);
}

Future<InitializedCompilerState> initializeCompiler(
    InitializedCompilerState oldState,
    Uri sdkSummary,
    Uri packagesFile,
    List<Uri> inputSummaries,
    Target target) async {
  inputSummaries.sort((a, b) => a.toString().compareTo(b.toString()));
  bool listEqual(List<Uri> a, List<Uri> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; ++i) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  if (oldState != null &&
      oldState.options.sdkSummary == sdkSummary &&
      oldState.options.packagesFileUri == packagesFile &&
      listEqual(oldState.options.inputSummaries, inputSummaries)) {
    // Reuse old state.

    // These libraries are marked external when compiling. If not un-marking
    // them compilation will fail.
    // Remove once [kernel_generator_impl.dart] no longer marks the libraries
    // as external.
    (await oldState.processedOpts.loadSdkSummary(null))
        .libraries
        .forEach((lib) => lib.isExternal = false);
    (await oldState.processedOpts.loadInputSummaries(null))
        .forEach((p) => p.libraries.forEach((lib) => lib.isExternal = false));

    // Avoid static leak.
    StringToken.canonicalizer.clear();

    return oldState;
  }

  // To make the output .dill agnostic of the current working directory,
  // we use a custom-uri scheme for all app URIs (these are files outside the
  // lib folder). The following [FileSystem] will resolve those references to
  // the correct location and keeps the real file location hidden from the
  // front end.
  // TODO(sigmund): technically we don't need a "multi-root" file system,
  // because we are providing a single root, the alternative here is to
  // implement a new file system with a single root instead.
  var fileSystem = new MultiRootFileSystem(
      'org-dartlang-app', [Uri.base], PhysicalFileSystem.instance);

  CompilerOptions options = new CompilerOptions()
    ..sdkSummary = sdkSummary
    ..packagesFileUri = packagesFile
    ..inputSummaries = inputSummaries
    ..target = target
    ..fileSystem = fileSystem
    ..chaseDependencies = true
    ..reportMessages = true;

  ProcessedOptions processedOpts = new ProcessedOptions(options, true, []);

  return new InitializedCompilerState(options, processedOpts);
}

Future<DdcResult> compile(InitializedCompilerState compilerState,
    List<Uri> inputs, ErrorHandler errorHandler) async {
  CompilerOptions options = compilerState.options;
  options..onError = errorHandler;

  ProcessedOptions processedOpts = compilerState.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);

  var compilerResult = await generateKernel(processedOpts);

  var program = compilerResult?.program;
  if (program == null) return null;

  // This should be cached.
  var summaries = await processedOpts.loadInputSummaries(null);
  return new DdcResult(program, summaries);
}
