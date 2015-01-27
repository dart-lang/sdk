// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  List<String> complete(List<String> args) {
    var possibles = ['one ', 'two ', 'three '];
    return possibles.where((possible) => possible.startsWith(args[0])).toList();
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
  expect(cmd.completeCommand(''),
         equals(['alpha ', 'game ', 'gamera ', 'count ']));

  // Substring completion.
  expect(cmd.completeCommand('al'),
         equals(['alpha ']));

  // Full string completion.
  expect(cmd.completeCommand('alpha'),
         equals(['alpha ']));
                      
  // Extra space, no subcommands.
  expect(cmd.completeCommand('alpha '),
         equals(['alpha ']));

  // Ambiguous completion.
  expect(cmd.completeCommand('g'),
         equals(['game ', 'gamera ']));

  // Ambiguous completion, exact match not preferred.
  expect(cmd.completeCommand('game'),
         equals(['game ', 'gamera ']));

  // Show all subcommands.
  expect(cmd.completeCommand('gamera '),
         equals(['gamera london ', 'gamera tokyo ', 'gamera topeka ']));

  // Subcommand completion.
  expect(cmd.completeCommand('gamera l'),
         equals(['gamera london ']));

  // Extra space, with subcommand.
  expect(cmd.completeCommand('gamera london '),
         equals(['gamera london ']));

  // Ambiguous subcommand completion.
  expect(cmd.completeCommand('gamera t'),
         equals(['gamera tokyo ', 'gamera topeka ']));

  // Ambiguous subcommand completion with substring prefix.
  // Note that the prefix is left alone.
  expect(cmd.completeCommand('gamer t'),
         equals(['gamer tokyo ', 'gamer topeka ']));

  // Ambiguous but exact prefix is preferred.
  expect(cmd.completeCommand('game chec'),
         equals(['game checkers ']));

  // Ambiguous non-exact prefix means no matches.
  expect(cmd.completeCommand('gam chec'),
         equals([]));

  // Locals + subcommands, show all.
  expect(cmd.completeCommand('count '),
         equals(['count chocula ',
                 'count one ',
                 'count two ',
                 'count three ']));

  // Locals + subcommands, single local match.
  expect(cmd.completeCommand('count th '),
         equals(['count three ']));

  // Locals + subcommands, ambiguous local match.
  expect(cmd.completeCommand('count t'),
         equals(['count two ', 'count three ']));

  // Locals + subcommands, single command match.
  expect(cmd.completeCommand('co choc'),
         equals(['co chocula ']));

  // We gobble spare spaces, even in the prefix.
  expect(cmd.completeCommand('    game    chec'), equals(['game checkers ']));
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
          expect(out.toString(), contains('executing alpha([cat, mouse])\n'));
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
      expect(e, equals('notfound'));
  }));
}

void testCommandRunAmbiguous() {
  // Run a simple command.
  StringBuffer out = new StringBuffer();
  RootCommand cmd = new RootCommand([new TestCommand(out, 'alpha', []),
                                     new TestCommand(out, 'ankle', [])]);

  cmd.runCommand('a 55').catchError(expectAsync((e) {
      expect(e, equals('ambiguous'));
      out.clear();
      cmd.runCommand('ankl 55').then(expectAsync((_) {
          expect(out.toString(), equals('executing ankle([55])\n'));
      }));
  }));
}

main() {
  test('command completion test suite', testCommandComplete);
  test('run a simple command', testCommandRunSimple);
  test('run a subcommand', testCommandRunSubcommand);
  test('run a command which is not found', testCommandRunNotFound);
  test('run a command which is ambiguous', testCommandRunAmbiguous);
}

