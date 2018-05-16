// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program that shows the equivalence-based data on a dart program.

import 'dart:io';
import 'package:args/args.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'id_equivalence_helper.dart';

ArgParser createArgParser() {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('verbose', negatable: true, defaultsTo: false);
  argParser.addFlag('colors', negatable: true);
  argParser.addFlag('all', negatable: false, defaultsTo: false);
  argParser.addFlag('strong', negatable: false, defaultsTo: false);
  argParser.addFlag('omit-implicit-checks',
      negatable: false, defaultsTo: false);
  argParser.addFlag('trust-type-annotations',
      negatable: false, defaultsTo: false);
  return argParser;
}

show(ArgResults argResults, ComputeMemberDataFunction computeKernelData,
    {ComputeClassDataFunction computeKernelClassData,
    bool testFrontend: false,
    List<String> options: const <String>[]}) async {
  if (argResults.wasParsed('colors')) {
    useColors = argResults['colors'];
  }
  bool verbose = argResults['verbose'];
  bool strongMode = argResults['strong'];
  bool omitImplicitChecks = argResults['omit-implicit-checks'];
  bool trustTypeAnnotations = argResults['trust-type-annotations'];

  String file = argResults.rest.first;
  Uri entryPoint = Uri.base.resolve(nativeToUriPath(file));
  List<String> show;
  if (argResults['all']) {
    show = null;
  } else if (argResults.rest.length > 1) {
    show = argResults.rest.skip(1).toList();
  } else {
    show = [entryPoint.pathSegments.last];
  }

  options = new List<String>.from(options);
  if (strongMode) {
    options.add(Flags.strongMode);
  }
  if (trustTypeAnnotations) {
    options.add(Flags.trustTypeAnnotations);
  }
  if (omitImplicitChecks) {
    options.add(Flags.omitImplicitChecks);
  }
  CompiledData data = await computeData(entryPoint, const {}, computeKernelData,
      computeClassData: computeKernelClassData,
      options: options,
      testFrontend: testFrontend,
      forUserLibrariesOnly: false,
      skipUnprocessedMembers: true,
      skipFailedCompilations: true,
      verbose: verbose);
  if (data == null) {
    print('Compilation failed.');
  } else {
    SourceFileProvider provider = data.compiler.provider;
    for (Uri uri in data.actualMaps.keys) {
      if (show != null && !show.any((f) => '$uri'.endsWith(f))) {
        continue;
      }
      SourceFile sourceFile = await provider.autoReadFromFile(uri);
      String sourceCode = sourceFile?.slowText();
      if (sourceCode == null) {
        sourceCode = new File.fromUri(uri).readAsStringSync();
      }
      if (sourceCode == null) {
        print('--source code missing for $uri--------------------------------');
      } else {
        print('--annotations for $uri----------------------------------------');
        print(withAnnotations(sourceCode, data.computeAnnotations(uri)));
      }
    }
  }
}
