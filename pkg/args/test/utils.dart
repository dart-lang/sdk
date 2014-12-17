// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:unittest/unittest.dart';

class CommandRunnerWithFooter extends CommandRunner {
  final usageFooter = "Also, footer!";

  CommandRunnerWithFooter(String executableName, String description)
      : super(executableName, description);
}

class FooCommand extends Command {
  var hasRun = false;

  final name = "foo";
  final description = "Set a value.";
  final takesArguments = false;

  void run() {
    hasRun = true;
  }
}

class HiddenCommand extends Command {
  var hasRun = false;

  final name = "hidden";
  final description = "Set a value.";
  final hidden = true;
  final takesArguments = false;

  void run() {
    hasRun = true;
  }
}

class AliasedCommand extends Command {
  var hasRun = false;

  final name = "aliased";
  final description = "Set a value.";
  final takesArguments = false;
  final aliases = const ["alias", "als"];

  void run() {
    hasRun = true;
  }
}

class AsyncCommand extends Command {
  var hasRun = false;

  final name = "async";
  final description = "Set a value asynchronously.";
  final takesArguments = false;

  Future run() => new Future.value().then((_) => hasRun = true);
}

void throwsIllegalArg(function, {String reason: null}) {
  expect(function, throwsArgumentError, reason: reason);
}

void throwsFormat(ArgParser parser, List<String> args) {
  expect(() => parser.parse(args), throwsFormatException);
}

Matcher throwsUsageError(message, usage) {
  return throwsA(predicate((error) {
    expect(error, new isInstanceOf<UsageError>());
    expect(error.message, message);
    expect(error.usage, usage);
    return true;
  }));
}
