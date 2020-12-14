// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dartdev/dartdev.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('help', help, timeout: longTimeout);
}

void help() {
  TestProject p;

  tearDown(() => p?.dispose());

  /// Commands not tested by the following loop.
  List<String> _commandsNotTested = <String>[
    'help', // `dart help help` is redundant
  ];
  DartdevRunner(['--no-analytics'])
      .commands
      .forEach((String commandKey, Command command) {
    if (!_commandsNotTested.contains(commandKey)) {
      test('(help $commandKey == $commandKey --help)', () {
        p = project();
        var result = p.runSync(['help', commandKey]);
        var verbHelpResult = p.runSync([commandKey, '--help']);

        expect(result.stdout, contains(verbHelpResult.stdout));
        expect(result.stderr, contains(verbHelpResult.stderr));
      });
    }
  });

  test('(help pub == pub --help)', () {
    p = project();
    var result = p.runSync(['help', 'pub']);
    var pubHelpResult = p.runSync(['pub', '--help']);

    expect(result.stdout, contains(pubHelpResult.stdout));
    expect(result.stderr, contains(pubHelpResult.stderr));
  });

  test('(--help flags also have -h abbr)', () {
    DartdevRunner(['--no-analytics'])
        .commands
        .forEach((String commandKey, Command command) {
      var helpOption = command.argParser.options['help'];
      // Some commands (like pub which use
      // "argParser = ArgParser.allowAnything()") may not have the help Option
      // accessible with the API used above:
      if (helpOption != null) {
        expect(helpOption.abbr, 'h', reason: '');
      }
    });
  });
}
