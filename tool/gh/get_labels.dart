// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:github/github.dart';
import 'package:linter/src/utils.dart';

import '../github.dart';

/// Outputs a list of labels.
Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('token', abbr: 't', help: 'Specifies a GitHub auth token.')
    ..addOption('owner',
        abbr: 'o', help: 'Specifies a GitHub repo owner (e.g., dart-lang).')
    ..addOption('name',
        abbr: 'n', help: 'Specifies a GitHub repo name (e.g., sdk).');

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var owner = options['owner'];
  if (owner is! String) {
    printUsage(parser, 'Must specify repo owner.');
    return;
  }
  var name = options['name'];
  if (name is! String) {
    printUsage(parser, 'Must specify repo name.');
    return;
  }

  var token = options['token'];
  var auth = token is String ? Authentication.withToken(token) : null;
  var labels = await getLabels(owner: owner, name: name, auth: auth);
  for (var label in labels) {
    printToConsole(label.name);
  }
}

void printUsage(ArgParser parser, [String? error]) {
  var message = error ?? 'Get labels for a given GitHub repo.';
  printToConsole('''$message
Usage: get_labels.dart rule_name
${parser.usage}
''');
}
