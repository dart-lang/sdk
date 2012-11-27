// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * TODO(amouravski): Document stuff here.
 */

import 'dart:io';

import '../lib/html_to_json.dart' as html_to_json;
import '../lib/json_to_html.dart' as json_to_html;
import '../../../pkg/args/lib/args.dart';

// Need this because ArgParser.getUsage doesn't show command invocation.
const USAGE = 'Usage htmlJsonDoc [options] --mode=<mode> <HTML.dart directory> '
    '<json path>\n[options] include:';
final argParser = new ArgParser();

main() {
  final args = new Options().arguments;

  if (args.isEmpty) {
    printUsage('No arguments provided.');
    return;
  }

  var mode;
  argParser.addOption('mode', abbr: 'm',
      help: '(Required) Convert from HTML docs to JSON or vice versa.',
      allowed: ['html-to-json', 'json-to-html'], allowedHelp: {
        'html-to-json': 'Processes all HTML .dart files at given\n'
          'location and outputs JSON.',
          'json-to-html': 'Takes JSON file at location and inserts docs into\n'
      'HTML .dart files.'},
      callback: (m) => mode = m
  );
  
  final argResults = argParser.parse(args);

  if (mode == null) {
    printUsage('Mode is a required option.');
    return;
  } else if (argResults.rest.length < 2) {
    printUsage('Insufficient arguments.');
    return;
  }

  var htmlPath = new Path.fromNative(argResults.rest[0]);
  var jsonPath = new Path.fromNative(argResults.rest[1]);

  var convertFuture;
  if (mode == 'html-to-json') {
    convertFuture = html_to_json.convert(htmlPath, jsonPath);
  } else {
    convertFuture = json_to_html.convert(htmlPath, jsonPath);
  }

  convertFuture.then((anyErrors) {
    print('Completed ${anyErrors ? "with" : "without"} errors.');
  });
}

/// Prints the usage of the tool. [message] is printed if provided.
void printUsage([String message]) {
  print(message);
  print(USAGE);
  print(argParser.getUsage());
}