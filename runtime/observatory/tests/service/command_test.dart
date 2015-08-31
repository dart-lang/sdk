// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override

import 'dart:async';

import 'package:observatory/cli.dart';
import 'package:unittest/unittest.dart';

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
  RootCommand cmd =
      new RootCommand([new TestCommand(null, 'alpha', []),

                       new TestCommand(null, 'game', [
                           new TestCommand(null, 'checkers', []),
                           new TestCommand(null, 'chess', [])]),

                       new TestCommand(null, 'gamera', [
                           new TestCommand(null, 'london', []),
                           new TestCommand(null, 'tokyo', []),
                           new TestCommand(null, 'topeka', [])]),

                       new TestCompleteCommand(null, 'count', [
                           new TestCommand(null, 'chocula', [])])]);

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
    expect(result, equals(['gamera london ', 'gamera tokyo ', 'gamera topeka ']));
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
      expect(result, equals(['count chocula ',
                             'count one ',
                             'count two ',
                             'count three ']));
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

void testCommandRunSimple() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand([new TestCommand(out, 'alpha', [])]);

  // Full name dispatch works.  Argument passing works.
  cmd.runCommand('alpha dog').then(expectAsync((_) {
      expect(out.toString(), contains('executing alpha([dog])\n'));
      out.clear();
      // Substring dispatch works.
      cmd.runCommand('al cat mouse').then(expectAsync((_) {
          expect(out.toString(), contains('executing alpha([cat , mouse])\n'));
      }));
  }));
}

void testCommandRunSubcommand() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd =
      new RootCommand([
          new TestCommand(out, 'alpha', [
              new TestCommand(out, 'beta', []),
              new TestCommand(out, 'gamma', [])])]);

  cmd.runCommand('a b').then(expectAsync((_) {
      expect(out.toString(), equals('executing beta([])\n'));
      out.clear();
      cmd.runCommand('alpha g ').then(expectAsync((_) {
          expect(out.toString(), equals('executing gamma([])\n'));
      }));
  }));
}

void testCommandRunNotFound() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand([new TestCommand(out, 'alpha', [])]);

  cmd.runCommand('goose').catchError(expectAsync((e) {
      expect(e, equals('No such command'));
  }));
}

void testCommandRunAmbiguous() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand([new TestCommand(out, 'alpha', []),
                                     new TestCommand(out, 'ankle', [])]);

  cmd.runCommand('a 55').catchError(expectAsync((e) {
      expect(e, equals('Ambiguous command'));
      out.clear();
      cmd.runCommand('ankl 55').then(expectAsync((_) {
          expect(out.toString(), equals('executing ankle([55])\n'));
      }));
  }));
}

void testCommandRunAlias() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  var aliasCmd = new TestCommand(out, 'alpha', []);
  aliasCmd.alias = 'a';
  RootCommand cmd = new RootCommand([aliasCmd,
                                     new TestCommand(out, 'ankle', [])]);

  cmd.runCommand('a 55').then(expectAsync((_) {
    expect(out.toString(), equals('executing alpha([55])\n'));
  }));
}

main() {
  test('command completion test suite', testCommandComplete);
  test('run a simple command', testCommandRunSimple);
  test('run a subcommand', testCommandRunSubcommand);
  test('run a command which is not found', testCommandRunNotFound);
  test('run a command which is ambiguous', testCommandRunAmbiguous);
  test('run a command using an alias', testCommandRunAlias);
}

