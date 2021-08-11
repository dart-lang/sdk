// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/binary_serialization.dart' as binary;
import 'package:dart2js_info/src/io.dart';

import 'inject_text.dart';
import 'usage_exception.dart';

/// Converts a dump-info file emitted by dart2js in JSON to binary format.
class ToBinaryCommand extends Command<void> with PrintUsageException {
  final String name = "to_binary";
  final String description = "Convert any info file to binary format.";

  void run() async {
    if (argResults.rest.length < 1) {
      usageException('Missing argument: <input-info>');
      exit(1);
    }

    String filename = argResults.rest[0];
    AllInfo info = await infoFromFile(filename);
    if (argResults['inject-text']) injectText(info);
    String outputFilename = argResults['out'] ?? '$filename.data';
    var outstream = new File(outputFilename).openWrite();
    binary.encode(info, outstream);
    await outstream.done;
  }
}
