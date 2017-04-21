// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/task/model.dart';
import 'package:args/args.dart';
import 'package:analyzer/src/kernel/loader.dart';
import 'package:kernel/kernel.dart';
import 'package:package_config/discovery.dart';

ArgParser parser = new ArgParser()
  ..addOption('sdk',
      help: 'Path to Dart SDK', valueHelp: 'path', defaultsTo: '/usr/lib/dart')
  ..addOption('packages',
      abbr: 'p',
      help: 'Path to the packages folder or .packages file',
      valueHelp: 'path')
  ..addFlag('strong', help: 'Use strong mode');

String get usage => '''
Usage: frontend_bench [options] FILE.dart

Benchmark the analyzer-based frontend.

Options:
${parser.options}
''';

main(List<String> args) {
  if (args.length == 0) {
    print(usage);
    exit(1);
  }
  ArgResults options = parser.parse(args);

  if (options.rest.length != 1) {
    print('Exactly one file must be given');
    exit(1);
  }

  String sdk = options['sdk'];
  String packagePath = options['packages'];
  bool strongMode = options['strong'];

  String path = options.rest.single;
  var uri = new Uri(scheme: 'file', path: new File(path).absolute.path);
  var packages =
      getPackagesDirectory(new Uri(scheme: 'file', path: packagePath));
  Program repository = new Program();

  new DartLoader(
          repository,
          new DartOptions(
              strongMode: strongMode, sdk: sdk, packagePath: packagePath),
          packages)
      .loadProgram(uri);

  CacheEntry.recomputedCounts.forEach((key, value) {
    print('Recomputed $key $value times');
  });

  AnalysisTask.stopwatchMap.forEach((key, Stopwatch watch) {
    print('$key took ${watch.elapsedMilliseconds} ms');
  });
}
