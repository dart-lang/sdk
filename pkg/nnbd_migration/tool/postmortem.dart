// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/postmortem_file.dart';

main(List<String> args) {
  ArgParser argParser = ArgParser();
  ArgResults parsedArgs;

  argParser.addOption('file',
      abbr: 'f', help: 'The postmortem file to analyze');

  argParser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Print usage info');

  List<Subcommand> subcommands = [
    Subcommand(
        name: 'dot', help: 'Output graph as dot file', argParser: ArgParser()),
    Subcommand(name: 'help', help: 'Print usage info', argParser: ArgParser()),
    Subcommand(
        name: 'steps', help: 'Print propagation steps', argParser: ArgParser()),
  ];

  for (var subcommand in subcommands) {
    argParser.addCommand(subcommand.name, subcommand.argParser);
  }

  try {
    parsedArgs = argParser.parse(args);
  } on ArgParserException {
    stderr.writeln(argParser.usage);
    exit(1);
  }
  var command = parsedArgs.command;
  if (parsedArgs['help'] as bool || command == null || command.name == 'help') {
    print(argParser.usage);
    for (var subcommand in subcommands) {
      print('');
      print('Subcommand ${subcommand.name}: ${subcommand.help}');
      print(subcommand.argParser.usage);
    }
    exit(0);
  }
  var filePath = parsedArgs['file'] as String;
  if (filePath == null) {
    print('Must specify a file to analyze using -f');
    exit(1);
  }
  var reader = PostmortemFileReader.read(
      PhysicalResourceProvider.INSTANCE.getFile(filePath));
  switch (command.name) {
    case 'dot':
      reader.graph.debugDump();
      break;
    case 'steps':
      for (var step in reader.downstreamPropagationSteps) {
        print(step.toString(idMapper: reader.idMapper));
      }
      break;
    default:
      throw StateError('Unrecognized command: $command');
  }
}

class Subcommand {
  final String name;
  final String help;
  final ArgParser argParser;

  Subcommand(
      {@required this.name, @required this.help, @required this.argParser});
}
