// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A command that verifies that deferred libraries split the code as expected.
///
/// This tool checks that the output from dart2js meets a given specification,
/// given in a YAML file. The format of the YAML file is:
///
///     main:
///       packages:
///         - some_package
///         - other_package
///
///     foo:
///       packages:
///         - foo
///         - bar
///
///     baz:
///       packages:
///         - baz
///         - quux
///
/// The YAML file consists of a list of declarations, one for each deferred
/// part expected in the output. At least one of these parts must be named
/// "main"; this is the main part that contains the program entrypoint. Each
/// top-level part contains a list of package names that are expected to be
/// contained in that part. Any package that is not explicitly listed is
/// expected to be in the main part. For instance, in the example YAML above
/// the part named "baz" is expected to contain the packages "baz" and "quux".
///
/// The names for parts given in the specification YAML file (besides "main")
/// are arbitrary and just used for reporting when the output does not meet the
/// specification.
library dart2js_info.bin.deferred_library_check;

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dart2js_info/deferred_library_check.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:yaml/yaml.dart';

import 'usage_exception.dart';

/// A command that computes the diff between two info files.
class DeferredLibraryCheck extends Command<void> with PrintUsageException {
  final String name = "deferred_check";
  final String description =
      "Verify that deferred libraries are split as expected";

  void run() async {
    var args = argResults.rest;
    if (args.length < 2) {
      usageException('Missing arguments, expected: info.data manifest.yaml');
    }
    var info = await infoFromFile(args[0]);
    var manifest = await manifestFromFile(args[1]);

    var failures = checkDeferredLibraryManifest(info, manifest);
    failures.forEach(print);
    if (failures.isNotEmpty) exitCode = 1;
  }
}

Future manifestFromFile(String fileName) async {
  var file = await new File(fileName).readAsString();
  return loadYaml(file);
}
