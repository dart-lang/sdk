// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory_2/cli.dart';
import 'package:test/test.dart';

class TestCommand extends Command {
  TestCommand(this.out, name, children) : super(name, children);
  StringBuffer out;

  Future run(List<String> args) {
    out.write('executing ${name}(${args})\n');
    return new Future.value(null);
  }
}

class TestCompleteCommand extends Command {
  TestCompleteCommand(this.out, name, children) : super(name, children);
  StringBuffer out;

  Future<List<String>> complete(List<String> args) {
    var possibles = ['one ', 'two ', 'three '];
    return new Future.value(
        possibles.where((possible) => possible.startsWith(args[0])).toList());
  }

  Future run(List<String> args) {
    out.write('executing ${name}(${args})\n');
    return new Future.value(null);
  }
}

void testCommandComplete() {
  RootCommand cmd = new RootCommand([
    new TestCommand(null, 'alpha', <Command>[]),
    new TestCommand(null, 'game', <Command>[
      new TestCommand(null, 'checkers', <Command>[]),
      new TestCommand(null, 'chess', <Command>[])
    ]),
    new TestCommand(null, 'gamera', <Command>[
      new TestCommand(null, 'london', <Command>[]),
      new TestCommand(null, 'tokyo', <Command>[]),
      new TestCommand(null, 'topeka', <Command>[])
    ]),
    new TestCompleteCommand(
        null, 'count', <Command>[new TestCommand(null, 'chocula', <Command>[])])
  ]);

  // Show all commands.
  cmd.completeCommand('').then((result) {
    expect(result, equals(['alpha ', 'game ', 'gamera ', 'count ']));
  });

  // Substring completion.
  cmd.completeCommand('al').then((result) {
    expect(result, equals(['alpha ']));
  });

  // Full string completion.
  cmd.completeCommand('alpha').then((result) {
    expect(result, equals(['alpha ']));
  });

  // Extra space, no subcommands.
  cmd.completeCommand('alpha ').then((result) {
    expect(result, equals(['alpha ']));
  });

  // Ambiguous completion.
  cmd.completeCommand('g').then((result) {
    expect(result, equals(['game ', 'gamera ']));
  });

  // Ambiguous completion, exact match not preferred.
  cmd.completeCommand('game').then((result) {
    expect(result, equals(['game ', 'gamera ']));
  });

  // Show all subcommands.
  cmd.completeCommand('gamera ').then((result) {
    expect(
        result, equals(['gamera london ', 'gamera tokyo ', 'gamera topeka ']));
  });

  // Subcommand completion.
  cmd.completeCommand('gamera l').then((result) {
    expect(result, equals(['gamera london ']));
  });

  // Extra space, with subcommand.
  cmd.completeCommand('gamera london ').then((result) {
    expect(result, equals(['gamera london ']));
  });

  // Ambiguous subcommand completion.
  cmd.completeCommand('gamera t').then((result) {
    expect(result, equals(['gamera tokyo ', 'gamera topeka ']));
  });

  // Ambiguous subcommand completion with substring prefix.
  // Note that the prefix is left alone.
  cmd.completeCommand('gamer t').then((result) {
    expect(result, equals(['gamer tokyo ', 'gamer topeka ']));
  });

  // Ambiguous but exact prefix is preferred.
  cmd.completeCommand('game chec').then((result) {
    expect(result, equals(['game checkers ']));
  });

  // Ambiguous non-exact prefix means no matches.
  cmd.completeCommand('gam chec').then((result) {
    expect(result, equals([]));
  });

  // Locals + subcommands, show all.
  cmd.completeCommand('count ').then((result) {
    expect(result,
        equals(['count chocula ', 'count one ', 'count two ', 'count three ']));
  });

  // Locals + subcommands, single local match.
  cmd.completeCommand('count th').then((result) {
    expect(result, equals(['count three ']));
  });

  // Locals + subcommands, ambiguous local match.
  cmd.completeCommand('count t').then((result) {
    expect(result, equals(['count two ', 'count three ']));
  });

  // Locals + subcommands, single command match.
  cmd.completeCommand('co choc').then((result) {
    expect(result, equals(['co chocula ']));
  });

  // We gobble spare spaces in the prefix but not elsewhere.
  cmd.completeCommand('    game    chec').then((result) {
    expect(result, equals(['game    checkers ']));
  });
}

testCommandRunSimple() async {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd =
      new RootCommand([new TestCommand(out, 'alpha', <Command>[])]);

  // Full name dispatch works.  Argument passing works.
  await cmd.runCommand('alpha dog');
  expect(out.toString(), contains('executing alpha([dog])\n'));
  out.clear();
  // Substring dispatch works.
  await cmd.runCommand('al cat mouse');
  expect(out.toString(), contains('executing alpha([cat , mouse])\n'));
}

testCommandRunSubcommand() async {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand([
    new TestCommand(out, 'alpha', [
      new TestCommand(out, 'beta', <Command>[]),
      new TestCommand(out, 'gamma', <Command>[])
    ])
  ]);

  await cmd.runCommand('a b');
  expect(out.toString(), equals('executing beta([])\n'));
  out.clear();
  await cmd.runCommand('alpha g ');
  expect(out.toString(), equals('executing gamma([])\n'));
}

testCommandRunNotFound() async {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd =
      new RootCommand([new TestCommand(out, 'alpha', <Command>[])]);

  dynamic e;
  try {
    await cmd.runCommand('goose');
  } catch (ex) {
    e = ex;
  }
  expect(e.toString(), equals("No such command: 'goose'"));
}

testCommandRunAmbiguous() async {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand([
    new TestCommand(out, 'alpha', <Command>[]),
    new TestCommand(out, 'ankle', <Command>[])
  ]);

  dynamic e;
  try {
    await cmd.runCommand('a 55');
  } catch (ex) {
    e = ex;
  }
  expect(e.toString(), equals("Command 'a 55' is ambiguous: [alpha, ankle]"));
  out.clear();

  await cmd.runCommand('ankl 55');
  expect(out.toString(), equals('executing ankle([55])\n'));
}

testCommandRunAlias() async {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  var aliasCmd = new TestCommand(out, 'alpha', <Command>[]);
  aliasCmd.alias = 'a';
  RootCommand cmd =
      new RootCommand([aliasCmd, new TestCommand(out, 'ankle', <Command>[])]);

  await cmd.runCommand('a 55');
  expect(out.toString(), equals('executing alpha([55])\n'));
}

main() {
  test('command completion test suite', testCommandComplete);
  test('run a simple command', testCommandRunSimple);
  test('run a subcommand', testCommandRunSubcommand);
  test('run a command which is not found', testCommandRunNotFound);
  test('run a command which is ambiguous', testCommandRunAmbiguous);
  test('run a command using an alias', testCommandRunAlias);
}
