// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import 'package:scheduled_test/scheduled_test.dart';

import 'descriptor.dart' as d;
import 'test_pub.dart';

final USAGE_STRING = """
    Pub is a package manager for Dart.

    Usage: pub command [arguments]

    Global options:
    -h, --help            Print this usage information.
        --version         Print pub version.
        --[no-]trace      Print debugging information when an error occurs.
        --verbosity       Control output verbosity.

              [all]       Show all output including internal tracing messages.
              [io]        Also show IO operations.
              [normal]    Show errors, warnings, and user messages.
              [solver]    Show steps during version resolution.

    -v, --verbose         Shortcut for "--verbosity=all"

    Available commands:
      cache      Inspect the system cache.
      help       Display help information for Pub.
      install    Install the current package's dependencies.
      publish    Publish the current package to pub.dartlang.org.
      update     Update the current package's dependencies to the latest versions.
      uploader   Manage uploaders for a package on pub.dartlang.org.
      version    Print pub version.

    Use "pub help [command]" for more information about a command.
    """;

final VERSION_STRING = '''
    Pub 0.1.2+3
    ''';

main() {
  initConfig();

  integration('running pub with no command displays usage', () {
    schedulePub(args: [], output: USAGE_STRING);
  });

  integration('running pub with just --help displays usage', () {
    schedulePub(args: ['--help'], output: USAGE_STRING);
  });

  integration('running pub with just -h displays usage', () {
    schedulePub(args: ['-h'], output: USAGE_STRING);
  });

  integration('running pub with just --version displays version', () {
    schedulePub(args: ['--version'], output: VERSION_STRING);
  });

  integration('an unknown command displays an error message', () {
    schedulePub(args: ['quylthulg'],
        error: '''
        Could not find a command named "quylthulg".
        Run "pub help" to see available commands.
        ''',
        exitCode: 64);
  });

  integration('an unknown option displays an error message', () {
    schedulePub(args: ['--blorf'],
        error: '''
        Could not find an option named "blorf".
        Run "pub help" to see available options.
        ''',
        exitCode: 64);
  });

  integration('an unknown command option displays an error message', () {
    // TODO(rnystrom): When pub has command-specific options, a more precise
    // error message would be good here.
    schedulePub(args: ['version', '--blorf'],
        error: '''
        Could not find an option named "blorf".
        Use "pub help" for more information.
        ''',
        exitCode: 64);
  });

  group('help', () {
    integration('shows help for a command', () {
      schedulePub(args: ['help', 'install'],
          output: '''
            Install the current package's dependencies.

            Usage: pub install
            ''');
    });

    integration('shows help for a command', () {
      schedulePub(args: ['help', 'publish'],
          output: '''
            Publish the current package to pub.dartlang.org.

            Usage: pub publish [options]
            -n, --dry-run    Validate but do not publish the package                      
            -f, --force      Publish without confirmation if there are no errors
                --server     The package server to which to upload this package
                             (defaults to "https://pub.dartlang.org")
            ''');
    });

    integration('an unknown help command displays an error message', () {
      schedulePub(args: ['help', 'quylthulg'],
          error: '''
            Could not find a command named "quylthulg".
            Run "pub help" to see available commands.
            ''',
            exitCode: 64);
    });

  });

  group('version', () {
    integration('displays the current version', () {
      schedulePub(args: ['version'], output: VERSION_STRING);
    });

    integration('parses a release-style version', () {
      d.dir(sdkPath, [
        d.file('version', '0.1.2.0_r17645'),
      ]).create();

      schedulePub(args: ['version'], output: "Pub 0.1.2+0.r17645\n");
    });

    integration('parses a dev-only style version', () {
      // The "version" file generated on developer builds is a little funky and
      // we need to make sure we don't choke on it.
      d.dir(sdkPath, [
        d.file('version', '0.1.2.0_r16279_bobross'),
      ]).create();

      schedulePub(args: ['version'], output: "Pub 0.1.2+0.r16279.bobross\n");
    });
  });
}
