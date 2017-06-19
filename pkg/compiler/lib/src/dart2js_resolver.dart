// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/null_compiler_output.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:package_config/discovery.dart';
import 'package:compiler/src/elements/elements.dart';

Future<String> resolve(List<Uri> inputs,
    {List<String> deps: const <String>[],
    List<String> bazelSearchPaths,
    String root,
    String packages,
    Uri packageRoot,
    String platformConfig}) async {
  var resolutionInputs = deps
      .map((uri) => currentDirectory.resolve(nativeToUriPath(uri)))
      .toList();
  var libraryRoot = root == null
      ? Platform.script.resolve('../../../sdk/')
      : currentDirectory.resolve(nativeToUriPath(root));

  var options = new CompilerOptions(
      libraryRoot: libraryRoot,
      resolveOnly: true,
      analyzeMain: true,
      resolutionInputs: resolutionInputs,
      packageRoot: packageRoot,
      packageConfig:
          packages != null ? currentDirectory.resolve(packages) : null,
      packagesDiscoveryProvider: findPackages,
      platformConfigUri:
          platformConfig != null ? libraryRoot.resolve(platformConfig) : null);

  var inputProvider = bazelSearchPaths != null
      ? new BazelInputProvider(bazelSearchPaths)
      : new CompilerSourceFileProvider();

  var outputProvider = const NullCompilerOutput();
  var diagnostics = new FormattingDiagnosticHandler(inputProvider)
    ..enableColors = !Platform.isWindows;
  var compiler =
      new CompilerImpl(inputProvider, outputProvider, diagnostics, options);

  await compiler.setupSdk();
  await compiler.setupPackages(inputs.first);

  var librariesToSerialize = <LibraryElement>[];
  for (var uri in inputs) {
    var library = await compiler.analyzeUri(uri);
    if (library != null) {
      // [library] is `null` if [uri] is a part file.
      librariesToSerialize.add(library);
    }
  }

  if (librariesToSerialize.isEmpty) {
    print('no library input files');
    exit(1);
  }

  var serializer =
      compiler.serialization.createSerializer(librariesToSerialize);
  return serializer.toText(const JsonSerializationEncoder());
}
