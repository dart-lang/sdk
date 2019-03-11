// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';

import 'to_json.dart' show ToJsonCommand;
import 'to_binary.dart' show ToBinaryCommand;
import 'to_proto.dart' show ToProtoCommand;
import 'usage_exception.dart';

/// This tool reports how code is divided among deferred chunks.
class ConvertCommand extends Command<void> with PrintUsageException {
  final String name = "convert";
  final String description = "Convert between info formats.";

  ConvertCommand() {
    _addSubcommand(new ToJsonCommand());
    _addSubcommand(new ToBinaryCommand());
    _addSubcommand(new ToProtoCommand());
  }

  _addSubcommand(Command<void> command) {
    addSubcommand(command);
    command.argParser
      ..addOption('out',
          abbr: 'o',
          help: 'Output file '
              '(to_json defauts to <input>.json, to_binary defaults to\n'
              '<input>.data, and to_proto defaults to <input>.pb)')
      ..addFlag('inject-text',
          negatable: false,
          help: 'Whether to inject output code snippets.\n\n'
              'By default dart2js produces code spans, but excludes the text. This\n'
              'option can be used to embed the text directly in the output.\n'
              'Note: this requires access to dart2js output files.\n');
  }
}
