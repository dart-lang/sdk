// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:args/args.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:linter/src/utils.dart';

import 'github.dart';

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

  var rules = options.rest;
  if (rules.isEmpty) {
    printUsage(parser, 'At least one rule needs to be specified.');
    return;
  }

  var client = http.Client();
  var req = await client.get(
      Uri.parse('https://dart-lang.github.io/linter/lints/machine/rules.json'));

  var token = options['token'];
  var auth = token is String ? Authentication.withToken(token) : null;

  var machine = json.decode(req.body) as Iterable;

  for (var rule in rules) {
    for (var entry in machine) {
      if (entry['name'] == rule) {
        printToConsole('https://dart-lang.github.io/linter/lints/$rule.html');
        printToConsole('');
        printToConsole('contained in: ${entry["sets"]}');
        var issues = await getLinterIssues(auth: auth);
        for (var issue in issues) {
          var title = issue.title;
          if (title.contains(rule)) {
            printToConsole('issue: ${issue.title}');
            printToConsole(
                'labels: ${issue.labels.map((e) => e.name).join(", ")}');
            printToConsole(issue.htmlUrl);
            printToConsole('');
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
