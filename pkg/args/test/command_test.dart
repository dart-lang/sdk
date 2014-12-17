// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library command_test;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

void main() {
  var foo;
  setUp(() {
    foo = new FooCommand();

      // Make sure [Command.runner] is set up.
    new CommandRunner("test", "A test command runner.").addCommand(foo);
  });

  group(".invocation has a sane default", () {
    test("without subcommands", () {
      expect(foo.invocation,
          equals("test foo [arguments]"));
    });

    test("with subcommands", () {
      foo.addSubcommand(new AsyncCommand());
      expect(foo.invocation,
          equals("test foo <subcommand> [arguments]"));
    });

    test("for a subcommand", () {
      var async = new AsyncCommand();
      foo.addSubcommand(async);

      expect(async.invocation,
          equals("test foo async [arguments]"));
    });
  });

  group(".usage", () {
    test("returns the usage string", () {
      expect(foo.usage, equals("""
Set a value.

Usage: test foo [arguments]
-h, --help    Print this usage information.

Run "test help" to see global options."""));
    });

    test("contains custom options", () {
      foo.argParser.addFlag("flag", help: "Do something.");

      expect(foo.usage, equals("""
Set a value.

Usage: test foo [arguments]
-h, --help         Print this usage information.
    --[no-]flag    Do something.

Run "test help" to see global options."""));
    });

    test("doesn't print hidden subcommands", () {
      foo.addSubcommand(new AsyncCommand());
      foo.addSubcommand(new HiddenCommand());

      expect(foo.usage, equals("""
Set a value.

Usage: test foo <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  async   Set a value asynchronously.

Run "test help" to see global options."""));
    });

    test("doesn't print subcommand aliases", () {
      foo.addSubcommand(new AliasedCommand());

      expect(foo.usage, equals("""
Set a value.

Usage: test foo <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  aliased   Set a value.

Run "test help" to see global options."""));
    });
  });

  test("usageException splits up the message and usage", () {
    expect(() => foo.usageException("message"), throwsUsageError("message", """
Usage: test foo [arguments]
-h, --help    Print this usage information.

Run "test help" to see global options."""));
  });

  test("considers a command hidden if all its subcommands are hidden", () {
    foo.addSubcommand(new HiddenCommand());
    expect(foo.hidden, isTrue);
  });
}
