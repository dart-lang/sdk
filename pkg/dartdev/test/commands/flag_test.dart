// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:dartdev/dartdev.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('flag', help);
}

void help() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync('--help', []);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(DartdevRunner.dartdevDescription));
    expect(result.stdout, contains('Usage: dart <command> [arguments]'));
    expect(result.stdout, contains('Global options:'));
    expect(result.stdout, contains('Available commands:'));
  });

  // For each command description, assert that the values are not empty, don't
  // have trailing white space, and end with a period.
  test('descriptions formats', () {
    DartdevRunner([]).commands.forEach((String commandKey, Command command) {
      expect(commandKey, isNotEmpty);
      expect(command.description, isNotEmpty);
      expect(command.description, endsWith('.'));
      expect(command.description.trim(), equals(command.description));
    });
  });
}
