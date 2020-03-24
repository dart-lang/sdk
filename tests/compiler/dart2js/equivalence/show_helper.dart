// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Helper program that shows the equivalence-based data on a dart program.

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:_fe_analyzer_shared/src/util/filenames.dart';
import 'package:args/args.dart';
import 'package:compiler/src/commandline_options.dart';
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
  return argParser;
}

show<T>(ArgResults argResults, DataComputer<T> dataComputer,
    {List<String> options: const <String>[]}) async {
  dataComputer.setup();

  if (argResults.wasParsed('colors')) {
    useColors = argResults['colors'];
  }
  bool verbose = argResults['verbose'];
  bool omitImplicitChecks = argResults['omit-implicit-checks'];

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
  if (omitImplicitChecks) {
    options.add(Flags.omitImplicitChecks);
  }
  Dart2jsCompiledData<T> data = await computeData<T>(
      entryPoint, const {}, dataComputer,
      options: options,
      testFrontend: dataComputer.testFrontend,
      forUserLibrariesOnly: false,
      skipUnprocessedMembers: true,
      skipFailedCompilations: true,
      verbose: verbose);
  if (data == null) {
    print('Compilation failed.');
  } else {
    SourceFileProvider provider = data.compiler.provider;
    for (Uri uri in data.actualMaps.keys) {
      Uri fileUri = uri;
      if (fileUri.scheme == 'org-dartlang-sdk') {
        fileUri = Uri.base.resolve(fileUri.path.substring(1));
      }
      if (show != null && !show.any((f) => '$fileUri'.endsWith(f))) {
        continue;
      }
      SourceFile sourceFile = await provider.autoReadFromFile(fileUri);
      String sourceCode = sourceFile?.slowText();
      if (sourceCode == null) {
        sourceCode = new File.fromUri(fileUri).readAsStringSync();
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
