#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'dart2aot.dart';

typedef void Command(ArgResults args, List<String> ds);

void main(List<String> args) {
  Map<String, Command> commands = <String, Command>{};
  commands['aot'] = callAOT;

  // Read -D args that the ArgParser can't handle.
  List<String> ds = [];
  args = filterDArgs(args, ds);

  ArgParser parser = ArgParser();
  parser.addFlag('help');
  ArgParser aotParser = parser.addCommand('aot');
  setupAOTArgs(aotParser);

  ArgResults result = null;
  try {
    result = parser.parse(args);
  } catch (ArgParserException) {
    // We handle this case as result == null below.
  }

  if (result == null || result.command == null || result['help']) {
    print('dart2native <command> <args>\n');
    print(' command: ');
    print('   aot  - Compile script into one ahead of time dart snapshot');
    return;
  }

  if (commands.containsKey(result.command.name)) {
    commands[result.command.name](result.command, ds);
    return;
  }
}

void callAOT(ArgResults args, List<String> ds) {
  List<String> rest = args.rest;
  if (rest.length != 2) {
    print(
        'Usage: dart2native aot [options] <dart-source-file> <dart-aot-file>\n');
    print(
        'Dart AOT (ahead-of-time) compile Dart source code into native machine code.');
    return;
  }

  aot(rest[0], rest[1], args['build-elf'], args['enable-asserts'], args['tfa'],
      args['no-tfa'], args['packages'], ds);
}

List<String> filterDArgs(List<String> args, List<String> ds) {
  List<String> result = <String>[];

  args.forEach((String arg) {
    if (!arg.startsWith('-D')) {
      result.add(arg);
    } else {
      ds.add(arg);
    }
  });

  return result;
}
