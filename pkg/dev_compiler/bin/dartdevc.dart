#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line entry point for Dart Development Compiler (dartdevc).
///
/// Supported commands are
///   * compile: builds a collection of dart libraries into a single JS module
///
/// Additionally, these commands are being considered
///   * link:  combines several JS modules into a single JS file
///   * build: compiles & links a set of code, automatically determining
///            appropriate groupings of libraries to combine into JS modules
///   * watch: watch a directory and recompile build units automatically
///   * serve: uses `watch` to recompile and exposes a simple static file server
///            for local development
///
/// These commands are combined so we have less names to expose on the PATH,
/// and for development simplicity while the precise UI has not been determined.
///
/// A more typical structure for web tools is simply to have the compiler with
/// "watch" as an option. The challenge for us is:
///
/// * Dart used to assume whole-program compiles, so we don't have a
///   user-declared unit of building, and neither "libraries" or "packages" will
///   work,
/// * We do not assume a `node` JS installation, so we cannot easily reuse
///   existing tools for the "link" step, or assume users have a local
///   file server,
/// * We didn't have a file watcher API at first,
/// * We had no conventions about where compiled output should go (or even
///   that we would be compiling at all, vs running on an in-browser Dart VM),
/// * We wanted a good first impression with our simple examples, so we used
///   local file servers, and users have an expectation of it now, even though
///   it doesn't scale to typical apps that need their own real servers.

import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dev_compiler/src/compiler/command.dart';

main(List<String> args) async {
  var runner = new CommandRunner('dartdevc', 'Dart Development Compiler');
  runner.addCommand(new CompileCommand());
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    // Incorrect usage, input file not found, etc.
    print(e);
    exit(64);
  } on CompileErrorException catch (e) {
    // Code has error(s) and failed to compile.
    print(e);
    exit(1);
  } catch (e, s) {
    // Anything else is likely a compiler bug.
    //
    // --unsafe-force-compile is a bit of a grey area, but it's nice not to
    // crash while compiling
    // (of course, output code may crash, if it had errors).
    //
    print("");
    print("We're sorry, you've found a bug in our compiler.");
    print("You can report this bug at:");
    print("    https://github.com/dart-lang/dev_compiler/issues");
    print("");
    print("Please include the information below in your report, along with");
    print("any other information that may help us track it down. Thanks!");
    print("");
    print("    dartdevc arguments: " + args.join(' '));
    print("    dart --version: ${Platform.version}");
    print("");
    print("```");
    print(e);
    print(s);
    print("```");
  }
}
