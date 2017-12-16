// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program that shows the equivalence-based data on a dart program.

import 'dart:io';
import 'package:args/args.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/inferrer/inferrer_engine.dart';
import 'package:compiler/src/io/source_file.dart';
import 'package:compiler/src/source_file_provider.dart';
import '../kernel/test_helpers.dart';
import 'id_equivalence_helper.dart';

show(List<String> args, ComputeMemberDataFunction computeAstData,
    ComputeMemberDataFunction computeKernelData) async {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('verbose', negatable: true, defaultsTo: false);
  argParser.addFlag('colors', negatable: true);
  argParser.addFlag('use-kernel', negatable: false, defaultsTo: false);
  ArgResults argResults = argParser.parse(args);
  if (argResults.wasParsed('colors')) {
    useColors = argResults['colors'];
  }
  bool verbose = argResults['verbose'];
  bool useKernel = argResults['use-kernel'];

  InferrerEngineImpl.useSorterForTesting = true;
  String file = argResults.rest.first;
  List<String> show;
  if (argResults.rest.length > 1) {
    show = argResults.rest.skip(1).toList();
  }

  Uri entryPoint = Uri.base.resolve(nativeToUriPath(file));
  List<String> options = <String>[];
  if (useKernel) {
    options.add(Flags.useKernel);
  }
  CompiledData data = await computeData(
      entryPoint, const {}, useKernel ? computeKernelData : computeAstData,
      options: options,
      forMainLibraryOnly: false,
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
      uri = resolveFastaUri(uri);
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
