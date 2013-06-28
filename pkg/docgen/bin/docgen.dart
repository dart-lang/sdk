// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import '../lib/docgen.dart';

/**
 * Analyzes Dart files and generates a representation of included libraries, 
 * classes, and members. 
 */
void main() {
  logger.onRecord.listen((record) => print(record.message));
  var results = initArgParser().parse(new Options().arguments);
  if (results['help']) return;  
  docgen(results);
}

/**
 * Creates parser for docgen command line arguments. 
 */
ArgParser initArgParser() {
  var parser = new ArgParser();
  parser.addFlag('help', abbr: 'h', 
      help: 'Prints help and usage information.', 
      negatable: false, 
      callback: (help) {
        if (help) {
          logger.info(parser.getUsage());
          logger.info(USAGE);
        }
      });
  parser.addFlag('verbose', abbr: 'v', 
      help: 'Output more logging information.', negatable: false, 
      callback: (verbose) {
        if (verbose) Logger.root.level = Level.FINEST;
      });
  parser.addOption('output-format', abbr: 'o', 
      help: 'Sets the output format.', 
      allowed: ['yaml', 'json'], 
      allowedHelp: {'yaml' : 'Outputs to YAML. (Default)', 
        'json' : 'Outputs to JSON.'});
  parser.addFlag('yaml', abbr: 'y', 
      help: 'Same as output-format=yaml.', negatable: false);
  parser.addFlag('json', abbr: 'j', 
      help: 'Same as output-format=json.', negatable: false);
  parser.addFlag('include-private', 
      help: 'Flag to include private declarations.', negatable: false);
  parser.addFlag('include-sdk', 
      help: 'Flag to parse SDK Library files.', negatable: false);
  parser.addFlag('parse-sdk', 
      help: 'Parses the SDK libraries only.', 
      defaultsTo: false, negatable: false);
  
  return parser;
}
