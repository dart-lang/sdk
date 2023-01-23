// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script provides an alternative way of creating the
// lib/src/front_end/resources/resources.g.dart file, based on a set of provided
// files that has already been suitably compiled.

import 'dart:io';

import 'package:args/args.dart';

import 'generate_resources.dart';

main(List<String> args) {
  var argParser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output to FILE', valueHelp: 'FILE')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
  var parsedArgs = argParser.parse(args);
  if (parsedArgs['help'] as bool) {
    print('Usage: dart assemble_resources.dart INPUT_FILES');
    print('');
    print(argParser.usage);
    exit(1);
  }
  var content =
      generateResourceFile([for (var arg in parsedArgs.rest) File(arg)]);
  var output = parsedArgs['output'] as String?;
  if (output == null) {
    stdout.write(content);
  } else {
    File(output).writeAsStringSync(content);
  }
}
