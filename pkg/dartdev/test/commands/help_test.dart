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
  late TestProject p;

  /// Commands not tested by the following loop.
  List<String> commandsNotTested = <String>[
    'help', // `dart help help` is redundant
    'test', // `dart help test` does not call `test:test --help`.
  ];
  DartdevRunner(['--suppress-analytics']).commands.forEach((
    String commandKey,
    Command<int> command,
  ) {
    if (!commandsNotTested.contains(commandKey)) {
      test('(help $commandKey == $commandKey --help)', () async {
        p = project();
        var result = await p.run(['help', commandKey]);
        var verbHelpResult = await p.run([commandKey, '--help']);

        expect(result.stdout, contains(verbHelpResult.stdout));
        expect(result.stderr, contains(verbHelpResult.stderr));
      });
    }
  });

  test('(help test ~= test --help) outside project', () async {
    p = project();
    p.deleteFile('pubspec.yaml');
    var result = await p.run(['help', 'test']);
    var testHelpResult = await p.run(['test', '--help']);

    expect(testHelpResult.stdout, contains(result.stdout));
    expect(testHelpResult.stderr, contains(result.stderr));
  });

  test('(help pub == pub --help)', () async {
    p = project();
    var result = await p.run(['help', 'pub']);
    var pubHelpResult = await p.run(['pub', '--help']);

    expect(result.stdout, contains(pubHelpResult.stdout));
    expect(result.stderr, contains(pubHelpResult.stderr));
  });

  test('(--help flags also have -h abbr)', () {
    DartdevRunner(['--suppress-analytics']).commands.forEach((
      String commandKey,
      Command<int> command,
    ) {
      var helpOption = command.argParser.options['help'];
      // Some commands (like pub which use
      // "argParser = ArgParser.allowAnything()") may not have the help Option
      // accessible with the API used above:
      if (helpOption != null) {
        expect(helpOption.abbr, 'h', reason: '');
      }
    });
  });

  test('command categories', () async {
    p = project();
    final result = await p.run(['help', '--verbose']);
    // Include the `Available commands:` with the empty line to ensure all
    // commands have a category.
    expect(
      result.stdout,
      contains('''
Available commands:

Global
  install               Install or upgrade a Dart CLI tool for global use.
  installed             List globally installed Dart CLI tools.
  uninstall             Remove a globally installed Dart CLI tool.

Project
  build                 Build a Dart application including code assets.
  compile               Compile Dart to various formats.
  create                Create a new Dart project.
  pub                   Work with packages.
  run                   Run a Dart program from a file or a local or remote package.
  test                  Run tests for a project.

Source code
  analyze               Analyze Dart code in a directory.
  doc                   Generate API documentation for Dart projects.
  fix                   Apply automated fixes to Dart source code.
  format                Idiomatically format Dart source code.

Tools
  compilation-server    Control resident frontend compilers.
  development-service   Start Dart's development service.
  devtools              Open DevTools (optionally connecting to an existing application).
  info                  Show diagnostic information about the installed tooling.
  language-server       Start Dart's analysis server.
  tooling-daemon        Start Dart's tooling daemon.
'''),
    );
  });
}
