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
  final String description = "Convert between the binary and JSON info format.";

  ConvertCommand() {
    addSubcommand(new ToJsonCommand());
    addSubcommand(new ToBinaryCommand());
    addSubcommand(new ToProtoCommand());
  }
}
