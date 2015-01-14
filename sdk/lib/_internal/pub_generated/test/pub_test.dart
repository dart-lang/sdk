// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../lib/src/exit_codes.dart' as exit_codes;
import 'test_pub.dart';

main() {
  initConfig();

  integration('running pub with no command displays usage', () {
    schedulePub(args: [], output: """
        Pub is a package manager for Dart.

        Usage: pub <command> [arguments]

        Global options:
        -h, --help            Print this usage information.
            --version         Print pub version.
            --[no-]trace      Print debugging information when an error occurs.
            --verbosity       Control output verbosity.

                  [all]       Show all output including internal tracing messages.
                  [io]        Also show IO operations.
                  [normal]    Show errors, warnings, and user messages.
                  [solver]    Show steps during version resolution.

        -v, --verbose         Shortcut for "--verbosity=all".

        Available commands:
          build       Apply transformers to build a package.
          cache       Work with the system cache.
          deps        Print package dependencies.
          downgrade   Downgrade the current package's dependencies to oldest versions.
          get         Get the current package's dependencies.
          global      Work with global packages.
          help        Display help information for pub.
          publish     Publish the current package to pub.dartlang.org.
          run         Run an executable from a package.
          serve       Run a local web development server.
          upgrade     Upgrade the current package's dependencies to latest versions.
          uploader    Manage uploaders for a package on pub.dartlang.org.
          version     Print pub version.

        Run "pub help <command>" for more information about a command.
        See http://dartlang.org/tools/pub for detailed documentation.
        """);
  });

  integration('running pub with just --version displays version', () {
    schedulePub(args: ['--version'], output: 'Pub 0.1.2+3');
  });
}
