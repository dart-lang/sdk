// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.get_dependencies;

import 'package:kernel/kernel.dart' show Component, loadComponentFromBytes;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import 'compiler_context.dart' show CompilerContext;

import 'dill/dill_target.dart' show DillTarget;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'uri_translator.dart' show UriTranslator;

Future<List<Uri>> getDependencies(Uri script,
    {Uri sdk,
    Uri packages,
    Uri platform,
    bool verbose: false,
    Target target}) async {
  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..verbose = verbose
    ..packagesFileUri = packages
    ..sdkSummary = platform
    ..sdkRoot = sdk;
  ProcessedOptions pOptions =
      new ProcessedOptions(options: options, inputs: <Uri>[script]);
  return await CompilerContext.runWithOptions(pOptions,
      (CompilerContext c) async {
    FileSystem fileSystem = c.options.fileSystem;
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    c.options.ticker.logMs("Read packages file");
    DillTarget dillTarget =
        new DillTarget(c.options.ticker, uriTranslator, c.options.target);
    if (platform != null) {
      List<int> bytes = await fileSystem.entityForUri(platform).readAsBytes();
      Component platformComponent = loadComponentFromBytes(bytes);
      dillTarget.loader.appendLibraries(platformComponent);
    }
    KernelTarget kernelTarget =
        new KernelTarget(fileSystem, false, dillTarget, uriTranslator);

    kernelTarget.setEntryPoints(<Uri>[script]);
    await dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();
    return new List<Uri>.from(c.dependencies);
  });
}
