// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/null_compiler_output.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:package_config/discovery.dart';

main(var argv) async {
  var parser = new ArgParser();
  parser.addOption('deps', abbr: 'd', allowMultiple: true);
  parser.addOption('out', abbr: 'o');
  parser.addOption('library-root', abbr: 'l');
  parser.addOption('packages', abbr: 'p');
  parser.addOption('bazel-paths', abbr: 'I', allowMultiple: true);
  var args = parser.parse(argv);

  var resolutionInputs = args['deps']
      .map((uri) => currentDirectory.resolve(nativeToUriPath(uri)))
      .toList();
  var root = args['library-root'];
  var libraryRoot = root == null
      ? Platform.script.resolve('../../../sdk/')
      : currentDirectory.resolve(nativeToUriPath(root));

  var options = new CompilerOptions(
      libraryRoot: libraryRoot,
      packageConfig: args['packages'] == null
          ? null
          : currentDirectory.resolve(args['packages']),
      resolveOnly: true,
      resolutionInputs: resolutionInputs,
      packagesDiscoveryProvider: findPackages);

  var bazelSearchPaths = args['bazel-paths'];
  var inputProvider = bazelSearchPaths != null
      ? new BazelInputProvider(bazelSearchPaths)
      : new CompilerSourceFileProvider();

  var outputProvider = const NullCompilerOutput();
  var diagnostics = new FormattingDiagnosticHandler(inputProvider)
    ..enableColors = true;
  var compiler =
      new CompilerImpl(inputProvider, outputProvider, diagnostics, options);

  if (args.rest.isEmpty) {
    print('missing input files');
    exit(1);
  }

  var inputs = args.rest
      .map((uri) => currentDirectory.resolve(nativeToUriPath(uri)))
      .toList();

  await compiler.setupSdk();
  await compiler.setupPackages(inputs.first);

  for (var library in inputs) {
    await compiler.libraryLoader.loadLibrary(library);
  }

  for (var library in inputs) {
    compiler.fullyEnqueueLibrary(compiler.libraryLoader.lookupLibrary(library),
        compiler.enqueuer.resolution);
  }

  compiler.processQueue(compiler.enqueuer.resolution, null);

  var librariesToSerialize =
      inputs.map((lib) => compiler.libraryLoader.lookupLibrary(lib)).toList();

  var serializer =
      compiler.serialization.createSerializer(librariesToSerialize);
  var text = serializer.toText(const JsonSerializationEncoder());

  var outFile = args['out'] ?? 'out.data';

  await new File(outFile).writeAsString(text);
}
