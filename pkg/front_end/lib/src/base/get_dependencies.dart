// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:kernel/kernel.dart' show Component, loadComponentFromBytes;
import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;
import '../api_prototype/file_system.dart' show FileSystem;
import '../api_prototype/standard_file_system.dart';
import '../base/processed_options.dart' show ProcessedOptions;
import '../dill/dill_target.dart' show DillTarget;
import '../kernel/kernel_target.dart' show KernelTarget;
import 'compiler_context.dart' show CompilerContext;
import 'file_system_dependency_tracker.dart';
import 'uri_translator.dart' show UriTranslator;

// Coverage-ignore(suite): Not run.
Future<List<Uri>> getDependencies(Uri script,
    {Uri? sdk,
    Uri? packages,
    Uri? platform,
    bool verbose = false,
    Target? target}) async {
  FileSystemDependencyTracker tracker = new FileSystemDependencyTracker();
  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..verbose = verbose
    ..packagesFileUri = packages
    ..sdkSummary = platform
    ..sdkRoot = sdk
    ..fileSystem = StandardFileSystem.instanceWithTracking(tracker);
  ProcessedOptions pOptions =
      new ProcessedOptions(options: options, inputs: <Uri>[script]);
  return await CompilerContext.runWithOptions(pOptions,
      (CompilerContext c) async {
    FileSystem fileSystem = c.options.fileSystem;
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    c.options.ticker.logMs("Read packages file");
    DillTarget dillTarget =
        new DillTarget(c, c.options.ticker, uriTranslator, c.options.target);
    if (platform != null) {
      Uint8List bytes = await fileSystem.entityForUri(platform).readAsBytes();
      Component platformComponent = loadComponentFromBytes(bytes);
      dillTarget.loader.appendLibraries(platformComponent);
    }
    KernelTarget kernelTarget =
        new KernelTarget(c, fileSystem, false, dillTarget, uriTranslator);

    kernelTarget.setEntryPoints(<Uri>[script]);
    dillTarget.buildOutlines();
    await kernelTarget.loader.buildOutlines();
    return new List<Uri>.of(tracker.dependencies);
  });
}
