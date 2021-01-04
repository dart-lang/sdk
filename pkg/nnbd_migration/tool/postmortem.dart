// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/postmortem_file.dart';
import 'package:nnbd_migration/src/variables.dart';

void main(List<String> args) {
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
    Subcommand(
        name: 'files', help: 'Print input file paths', argParser: ArgParser()),
    Subcommand(
        name: 'decorations',
        suffix: '<path>',
        help: 'Print decorations for a file',
        argParser: ArgParser()),
    Subcommand(
      name: 'node',
      suffix: '<id>',
      help: 'Print details about a node',
      argParser: ArgParser(),
    ),
    Subcommand(
      name: 'trace',
      suffix: '<id>',
      help: 'Print a trace of why a node was made nullable/non-nullable',
      argParser: ArgParser(),
    ),
    Subcommand(
      name: 'trace_lengths',
      help: 'Print the lengths of all traces',
      argParser: ArgParser(),
    ),
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
      var suffix = subcommand.suffix == null ? '' : ' ${subcommand.suffix}';
      print('Subcommand ${subcommand.name}$suffix: ${subcommand.help}');
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
      for (var step in reader.propagationSteps) {
        print(step.toString(idMapper: reader.idMapper));
      }
      break;
    case 'trace':
      var nodes = command.rest;
      if (nodes.length != 1) {
        print('Must specify exactly one node id after "node"');
        exit(1);
      }
      var id = int.parse(nodes[0]);
      var node = reader.deserializer.nodeForId(id);
      for (var step in reader.propagationSteps) {
        if (step is DownstreamPropagationStep &&
            identical(node, step.targetNode)) {
          print('Trace');
          int i = 0;
          while (step != null) {
            var codeReference = step.codeReference;
            var codeReferencePrefix =
                codeReference == null ? '' : '$codeReference: ';
            print('#${i++}\t$codeReferencePrefix$step');
            step = step.principalCause;
          }
        }
      }
      break;
    case 'trace_lengths':
      for (var step in reader.propagationSteps) {
        if (step is DownstreamPropagationStep) {
          print('trace length ${_traceLength(step)} for node id '
              '${reader.deserializer.idForNode(step.targetNode)}');
        }
      }
      break;
    case 'files':
      for (var entry in reader.fileDecorations.keys) {
        print(entry);
      }
      break;
    case 'decorations':
      var paths = command.rest;
      if (paths.length != 1) {
        print('Must specify exactly one path after "decorations"');
        exit(1);
      }
      var path = paths[0];
      var decorations = reader.fileDecorations[path];
      if (decorations == null) {
        print('Path not found: $path');
        exit(1);
      }
      for (var decorationEntry in decorations.entries) {
        for (var roleEntry in decorationEntry.value.entries) {
          var span = Variables.spanForUniqueIdentifier(decorationEntry.key);
          var nodeId = reader.idMapper.idForNode(roleEntry.value);
          print('${span.offset}-${span.end}${roleEntry.key}: $nodeId');
        }
      }
      break;
    case 'node':
      var nodes = command.rest;
      if (nodes.length != 1) {
        print('Must specify exactly one node id after "node"');
        exit(1);
      }
      var id = int.parse(nodes[0]);
      var node = reader.deserializer.nodeForId(id);
      print('Node $id: $node');
      print('Decorations:');
      reader.findDecorationsByNode(node, (path, span, role) {
        print('  $path:$span$role');
      });
      print('Upstream edges:');
      for (var edge in node.upstreamEdges) {
        var description =
            (edge as NullabilityEdge).toString(idMapper: reader.idMapper);
        print('  $description');
      }
      print('Downstream edges:');
      for (var edge in node.downstreamEdges) {
        var description =
            (edge as NullabilityEdge).toString(idMapper: reader.idMapper);
        print('  $description');
      }
      if (node is NullabilityNodeCompound) {
        var componentsByName = node.componentsByName;
        print('Components:');
        for (var entry in componentsByName.entries) {
          var description = entry.value.toString(idMapper: reader.idMapper);
          print('  ${entry.key}: $description');
        }
      }
      break;
    default:
      throw StateError('Unrecognized command: $command');
  }
}

int _traceLength(PropagationStep step) {
  int traceLength = 0;
  while (step != null) {
    traceLength++;
    step = step.principalCause;
  }
  return traceLength;
}

class Subcommand {
  final String name;
  final String suffix;
  final String help;
  final ArgParser argParser;

  Subcommand(
      {@required this.name,
      this.suffix,
      @required this.help,
      @required this.argParser});
}
