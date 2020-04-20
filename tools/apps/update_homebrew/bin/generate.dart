// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';
import 'package:update_homebrew/update_homebrew.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('revision', abbr: 'r')
    ..addOption('channel', abbr: 'c', allowed: supportedChannels);

  final options = parser.parse(args);
  final revision = options['revision'] as String;
  final channel = options['channel'] as String;
  if ([revision, channel].contains(null)) {
    print(
        "Usage: generate.dart -r revision -c channel <path_to_existing_dart.rb>");
    exitCode = 1;
    return;
  }

  if (options.rest.length != 1) {
    print("Pass in the path to an existing '$dartRbFileName' file.");
    exitCode = 1;
    return;
  }
  final existingDartRb = options.rest.single;

  var file = File(existingDartRb);

  if (!file.existsSync()) {
    print("Expected '$existingDartRb' to exist.");
    exitCode = 1;
    return;
  }

  if (p.basename(existingDartRb) != dartRbFileName) {
    print("Expected provided path to end with '$dartRbFileName'.");
    exitCode = 1;
  }

  await Chain.capture(() async {
    await writeHomebrewInfo(channel, revision, file.parent.path);
  }, onError: (error, chain) {
    print(error);
    print(chain.terse);
    exitCode = 1;
  });
}
