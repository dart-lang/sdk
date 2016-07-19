// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.test.util;

import 'package:kernel/kernel.dart';
import 'package:args/args.dart';
import 'dart:io';

class Options {
  String dartSdk;
  String packageRoot;
  String inputFile;

  Options({this.dartSdk, this.packageRoot, this.inputFile});

  Repository repository;

  Repository getRepository() {
    return repository ??=
        new Repository(sdk: dartSdk, packageRoot: packageRoot);
  }

  Program loadProgram() {
    if (inputFile.endsWith('.dill')) {
      return loadProgramFromBinary(inputFile);
    } else {
      return loadProgramFromDart(inputFile, getRepository());
    }
  }
}

Options readOptions(List<String> args) {
  ArgParser parser = new ArgParser()
    ..addOption('sdk',
        defaultsTo: '/usr/lib/dart', // TODO: Locate the SDK more intelligently.
        help: 'Path to the Dart SDK.')
    ..addOption('package-root',
        abbr: 'p',
        help: 'Path to the packages folder.\n'
          'The .packages file is not yet supported.');
  ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    exit(1);
  }
  if (results.arguments.length != 1) {
    print('USAGE: test_file [options] INPUT\n\n${parser.usage}');
    exit(1);
  }
  return new Options(
      dartSdk: results['sdk'],
      packageRoot: results['package-root'],
      inputFile: results.arguments[0]);
}
