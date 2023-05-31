// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:args/args.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/utils.dart';

import '../github.dart';

/// Outputs a list of issues whose GH issue tags need updating.
Future<void> main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('token', abbr: 't', help: 'Specifies a GitHub auth token.');
  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var client = http.Client();
  var req = await client.get(
      Uri.parse('https://dart-lang.github.io/linter/lints/machine/rules.json'));

  var token = options['token'];
  var auth = token is String ? Authentication.withToken(token) : null;

  var machine = json.decode(req.body) as List;
  var rules = machine
      .map((e) => MapEntry(e['name'] as String, e['sets'] as List))
      .toList();

  var issues = await getLinterIssues(auth: auth);
  for (var issue in issues) {
    var title = issue.title;
    for (var rule in rules) {
      if (title.contains(rule.key)) {
        var sets = rule.value;
        for (var set in sets) {
          if (!issue.labels.any((label) => label.name.startsWith('set-'))) {
            printToConsole('${issue.htmlUrl} => set-$set');
          }
        }
      }
    }
  }
}

void printUsage(ArgParser parser, [String? error]) {
  var message = error ??
      'Query lint rules for containing rule sets and relevant GH issues.';

  printToConsole('''$message
Usage: query.dart rule_name
${parser.usage}
''');
}
