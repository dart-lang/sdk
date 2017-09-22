// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.get_dependencies;

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show loadProgramFromBytes;

import 'package:kernel/target/targets.dart' show Target;

import '../../compiler_options.dart' show CompilerOptions;

import '../../file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_target.dart' show DillTarget;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'uri_translator.dart' show UriTranslator;

// TODO(sigmund): reimplement this API using the directive listener intead.
Future<List<Uri>> getDependencies(Uri script,
    {Uri sdk,
    Uri packages,
    Uri platform,
    bool verbose: false,
    Target target}) async {
  var options = new CompilerOptions()
    ..target = target
    ..verbose = verbose
    ..packagesFileUri = packages
    ..sdkSummary = platform
    ..sdkRoot = sdk;
  var pOptions = new ProcessedOptions(options);
  return await CompilerContext.runWithOptions(pOptions,
      (CompilerContext c) async {
    FileSystem fileSystem = c.options.fileSystem;
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    c.options.ticker.logMs("Read packages file");
    DillTarget dillTarget =
        new DillTarget(c.options.ticker, uriTranslator, c.options.target);
    if (platform != null) {
      var bytes = await fileSystem.entityForUri(platform).readAsBytes();
      var platformProgram = loadProgramFromBytes(bytes);
      dillTarget.loader.appendLibraries(platformProgram);
    }
    KernelTarget kernelTarget = new KernelTarget(
        fileSystem, false, dillTarget, uriTranslator, c.uriToSource);

    kernelTarget.read(script);
    await dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();
    return await kernelTarget.loader.getDependencies();
  });
}
